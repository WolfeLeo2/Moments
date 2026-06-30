# Moments — Code Review & Architecture Audit

_Generated 2026-06-29. Scope: full `lib/` (177 Dart files, ~51k LOC), `supabase/`, PowerSync config, and `pubspec.yaml` dependencies._

This is a deep audit of antipatterns, logic flaws, security issues, architectural problems, and dependency bloat. Findings are ordered by **criticality**. Each has a stable ID (`C#`, `H#`, `M#`, `L#`) for tracking, a `file:line` anchor, the problem, and the fix.

## Maintainer decisions (2026-06-29)

These are settled; the findings below are annotated accordingly.

- **D1 — PowerSync is the single source of truth for all synced data.** Drift is removed for synced entities. Sync rules in `powersync/sync-config.yaml` drive what replicates. Resolves the C1–C5 direction. See the follow-up section _"PowerSync migration — service & repository fate"_.
- **D8 — Default-everything-local; only moment media is opt-in.** All row/relational data that's cheap to store — friendships, chat (incl. text/notifications), profiles, moments metadata — is synced to the device **automatically**. The *only* thing kept server-side by default is **moment media (the shared images/videos)**, downloaded on demand unless the user toggles it on per the policy service. So the "pick what's offline" control is **media-scoped, not row-scoped** — and signed-URL fetching + media GC remain first-class (rows are always there; the heavy bytes are the variable).
- **D2 — Chat moves fully to PowerSync** (offline send + retry on reconnect). Custom chat UI to be re-evaluated against the `chat_bubbles` package. See _"chat_bubbles vs custom chat UI"_.
- **D3 — Secrets move to `dart-defines.json` consumed via `--dart-define-from-file=dart-defines.json`** (also feeds CI/CD). Resolves C6's delivery mechanism. `.env` is no longer bundled as an asset.
- **D4 — Chat encryption (C7) will be redesigned from scratch.** Current scheme is treated as not-secure until then.
- **D5 — OTP bypass (C8) is intentional for testing.** Downgraded to a release-gate checklist item, not a standing defect.
- **D6 — Notifications subsystem flagged for rework.** Findings distributed across the tiers (tagged `N#`).
- **D7 — Notifications are PowerSync-backed.** Rationale: **history on demand** — offline scrollback of notification history without server round-trips. Settles M13. The list becomes a reactive local SQL query (real pagination + realtime + unread count from one table); C10/H17/H18/H21 dissolve. Requires adding a `notifications` table to the PS schema + a sync stream + connector upload cases for `markAsRead`/`deleteNotification`. The `actor:actor_id` join + unread-count RPC stay server-side (or denormalize the actor onto the synced row).

## Severity legend & hierarchy

| Tier | Meaning | Action |
|------|---------|--------|
| 🔴 **CRITICAL** | Data loss, security breach, or core architecture is self-contradictory | Fix before next release |
| 🟠 **HIGH** | Correctness/perf bug users will hit, or major redundancy | Fix this cycle |
| 🟡 **MEDIUM** | Maintainability / latent bug / inconsistency | Schedule |
| ⚪ **LOW** | Polish, dead code, micro-perf | Opportunistic |

## TL;DR — the three things that matter most

1. **You have four overlapping local-data/sync systems** (Drift + PowerSync + Supabase realtime + a hand-rolled `pending_action` queue). They disagree on the source of truth, write paths race each other, and the offline queue is **never drained** — queued offline mutations are silently lost. See **C1–C5**.
2. **Secrets ship inside the app binary.** `.env` (containing a Supabase `service_role` key that bypasses all RLS) is bundled as a Flutter asset, and chat "encryption" uses a key shipped in that same file. The Mapbox token is hardcoded in source. See **C6–C8**.
3. **~7 dependencies are completely unused and several more are redundant** (5 animation libs, 5 hand-rolled image caches reinventing `flutter_cache_manager`). See the **Dependency Audit**.

---

# 🔴 CRITICAL

## ~~C1 — Two physical SQLite databases store the same domain entities~~ ✅ **FIXED** (2026-06-30)
> Drift removed entirely. Deleted `database.dart`/`database.g.dart`, `moment_storage_service`, dead `friends_service`; dropped `drift`, `drift_dev`, `sqlite3_flutter_libs` direct deps (Drift now only transitive via powersync_core). MediaCache → deterministic file cache (`MomentMediaCache`); conversation-id cache → `shared_preferences`; profile caches → Supabase/PowerSync. PowerSync is now the single SQLite stack. (Also resolved the powersync-2.x dependency conflict — bumped `riverpod_generator` to 4.x.)
`lib/core/database/database.dart:182-193` (Drift) vs `lib/core/services/powersync/chat_powersync_schema.dart:56-187` (PowerSync)

The app opens two independent on-device SQLite files (`moments_drift.db` and `moments_chat_powersync.db`) with overlapping schemas for messages, moments, profiles, friendships, and reactions. The UI reads chat and moments **exclusively from PowerSync** (`moments_providers.dart:28-56`, `chat_providers.dart:31-38`), so the entire Drift copy of those entities is a stale parallel store that can silently diverge.

**Fix:** Make PowerSync the single store for synced domain data. Delete the Drift `Messages`/`Moments`/`Profiles`/`Friendships`/`Conversations` tables; keep Drift only for genuinely local concerns (media-path cache) if anything. Route remaining writers through PowerSync.

## ~~C2 — The custom `pending_action` offline queue is never drained → queued mutations are permanently lost~~ ✅ **FIXED** (2026-06-30)
> Deleted the entire subsystem: `pending_action_service.dart`, `pending_action.dart`, the Drift `PendingActions` table + methods + mappers, and the `pendingActionsCount` provider. PowerSync's CRUD upload queue is the offline mutation queue.
`lib/core/services/pending_action_service.dart` (whole file), `lib/core/database/database.dart:587-671`

`PendingActionService` is never constructed or exposed by any provider. Nothing ever calls `getPendingActions()` to **execute** queued work — the only consumer is `sync_provider.dart:96-100`, which merely **counts** rows for a UI badge. Any action written via `queueAction` (delete moment, toggle privacy, mark-as-read…) sits in the table forever and is never replayed to the server. Worse, `markActionFailed` (`database.dart:634-651`) **deletes** actions after 5 retries with no dead-letter.

**Fix:** Delete the entire `PendingAction*` subsystem — PowerSync's CRUD upload queue already does offline mutation replay. (If you keep it, wire a processor that drains it on reconnect and dead-letters instead of deleting.)

## ~~C3 — Two conflicting write paths for chat mutations; offline durability depends on which button you press~~ ✅ **FIXED** (2026-06-30)
> The UI already routed all sends/edits/deletes/reactions through `ChatMutationService` (PowerSync); the direct-Supabase methods in `ChatRepository` were dead. Removed them — `ChatRepository` slimmed 743→~140 lines, keeping only `getOrCreateConversation` (RPC), typing (ephemeral realtime), and `streamUnreadCount`. Single write path now. _Residual exception:_ the FCM background isolate (`firebase_messaging_service`) still inserts a quick-reply message directly to Supabase — acceptable (PowerSync can't run in that isolate; the row syncs down on next foreground).
`lib/core/services/chat_mutation_service.dart:55-243` (PowerSync-first) vs `lib/data/repositories/chat_repository.dart:212-387` (direct Supabase)

`ChatRepository.sendMessage/editMessage/deleteMessageForEveryone/addReaction` write **directly to Supabase** and are still invoked from the UI (`chat_page.dart:88,189,196`), bypassing PowerSync's local store and offline queue. The same operations also exist in `ChatMutationService` via PowerSync. Depending on the path, a mutation may or may not survive offline, and the two can race on the same row (`messages.updated_at` is touched by `ChatRepository.addReaction:364-367` while PowerSync also syncs reactions).

**Fix:** Route **all** chat mutations through `ChatMutationService` (PowerSync). Reduce `ChatRepository` to typing-indicator / RPC helpers only.

## ~~C4 — `markAsRead` is dual-written to PowerSync and Supabase, racing on the same rows~~ ✅ **FIXED** (2026-06-30)
> The UI path (`MarkAsReadAction`) already went through PowerSync only; the racing `ChatRepository.markAsRead` direct-Supabase method was dead and was removed with the C3 slim-down. (The FCM background `_markAsRead` remains for the notification-reply path — same accepted background-isolate exception as C3.)
`lib/features/chat/providers/chat_providers.dart:159-176` (PowerSync) + `lib/data/repositories/chat_repository.dart:462-480` + `lib/core/services/firebase_messaging_service.dart:338` (direct Supabase)

Read-state (`is_read`/`last_read_at`) is mutated through two uncoordinated paths; the PowerSync connector also pushes `is_read` patches (`chat_powersync_connector.dart:235-281`). A direct Supabase update and a PowerSync upload clobber each other → flapping unread counts.

**Fix:** Mark-as-read goes through PowerSync only; remove the direct Supabase writes.

## ~~C5 — Dead `MomentStorageService.syncMoments` can destroy locally-cached data~~ ✅ **FIXED** (2026-06-30)
> File deleted — confirmed zero callers after Drift removal. The Drift `Moments` table and the `momentStorageService` provider were also removed as part of the C1/Drift-removal pass.
`lib/core/services/moment_storage_service.dart:77-140` (esp. `syncMoments` at 117-128)

## C6 — `service_role` secret bundled into the shipped app binary
`.env:5` (`ADMIN_ACCESS_TOKEN=sb_secret_…`, a `service_role` JWT) bundled via `pubspec.yaml:154` (`assets: - .env`)

`.env` is a Flutter asset, so the whole file is packaged inside the APK/IPA and trivially extractable. It contains a Supabase `service_role` key that **bypasses all RLS** — extracting it grants read/write/delete on every table. It also exposes `CHAT_ENCRYPTION_KEY`, `GIPHY_API_KEY`, and the PowerSync URL. (`.env` is correctly gitignored, but that's irrelevant — it ships in the binary.)

**Fix (per D3):** Remove `ADMIN_ACCESS_TOKEN` from the app entirely (server-only). **Rotate the service_role key now.** Stop bundling `.env` as an asset (drop it from `pubspec.yaml:154`); move public config to `dart-defines.json` consumed via `--dart-define-from-file=dart-defines.json` (also wires CI/CD). Read values with `String.fromEnvironment(...)`. Note: even `dart-define` values are still extractable from the binary — so this is correct only for the **anon/public** key, never the service_role key. Gitignore `dart-defines.json` and provide a `dart-defines.example.json`.

## C7 — Chat "encryption" key ships with the app; encryption is defeated
`lib/core/services/chat_encryption_service.dart:28-34, 48-51` + `.env:6`

The per-conversation key is `sha256(masterSecret + ':' + conversationId)` where `masterSecret` is the static `CHAT_ENCRYPTION_KEY` bundled in `.env` (and it falls back to the literal `'moments-default-key-change-me'` if unset, `chat_encryption_service.dart:29-30`). Since the master key ships in the binary and conversationIds aren't secret, anyone can derive every key and decrypt all messages. AES-CBC is used with **no HMAC** (no integrity), and on any error the service **silently returns plaintext** (`return plaintext; // Graceful fallback`, lines 48-51, 73-76) — so a thrown exception downgrades to cleartext invisibly.

**Fix (per D4 — full redesign):** This is obfuscation, not encryption. Either implement real E2E (per-user keys derived from secrets never sent to the server, e.g. libsignal) or drop the "encrypted" claim. Minimum bar for the rewrite: fail **closed** on encryption errors (never transmit plaintext), use AES-GCM (authenticated), and keep any master key server-side. Note this interacts with D1/D2 — once messages flow through PowerSync, decide whether ciphertext or plaintext is what syncs (E2E means PowerSync only ever sees ciphertext).

## C8 — Phone OTP verification is bypassed _(intentional for testing — see D5; RELEASE GATE)_
`lib/features/auth/presentation/phone_verification_page.dart:65-73` (and `_skip()` at line 88)

The active phone flow writes `phone_number`/`phone_hash` straight to `profiles` with the comment _"Skipping the actual SMS OTP verification step for now,"_ and lets users skip phone entry entirely. **This is a deliberate testing shortcut (D5), not a defect** — but it MUST be reverted before any production release, otherwise any user can claim any phone number (poisons phone-hash matching, enables impersonation).

**Release gate:** Require `supabase.auth.verifyOTP` to succeed (as `phone_verification_otp_page.dart:102` already does) before persisting the number; enforce ownership server-side, not via a trusted client UPDATE. Add a build-time guard so the skip path can't ship in release mode.

## ~~C9 — FCM token never cleared on logout → cross-account notification leakage~~ ✅ **FIXED** (2026-06-30)
> `auth_service.dart:signOut()` now calls `FirebaseMessaging.instance.getToken()`, deletes the `user_devices` row by `fcm_token`, then calls `FirebaseMessaging.instance.deleteToken()` before the Google/Supabase sign-out. Best-effort (`try/catch` with a warning log) so a network failure doesn't block sign-out.
`lib/core/services/auth_service.dart:107-120`, `lib/core/services/firebase_messaging_service.dart:661-675`

## ~~C10 — Notification pagination state held in mutable instance fields invisible to Riverpod~~ ✅ **FIXED** (2026-06-30)
> Dissolved by moving to PowerSync (D7). `NotificationsList` now extends `AsyncNotifier` whose `build()` subscribes to a `repo.watchNotifications()` PS stream via a single `StreamSubscription` — `state` is set directly as `AsyncData(rows)` on each stream emission. No offset/hasMore/isLoadingMore fields remain; the pagination UI in `notifications_page.dart` is deleted. Also resolves **H17** (non-realtime list), **H18** (offset-pagination race), and **H21** (100ms markAllAsRead timer).
`lib/core/providers/providers.dart:108-165`

---

# 🟠 HIGH

## H1 — Hardcoded Mapbox token in source (two places)
`lib/features/mapv2/presentation/map_page_v2.dart:44-45`, `lib/features/social/presentation/friend_profile_page.dart:791-792`

The Mapbox access token (`pk.eyJ1…`) is a committed string literal in two files — extractable and abusable for billing.

**Fix:** Move to `--dart-define`/dotenv, reference from one config constant, and **rotate the token**.

## H2 — Hardcoded Supabase URL + anon JWT in source
`lib/core/services/firebase_messaging_service.dart:23-25`

The URL and full anon JWT are inlined as top-level consts ("for background isolates"), inconsistent with every other service. The handler already loads `.env` at line 39, so it's redundant too.

**Fix:** Load from `dotenv`/`SupabaseConfig` in the background handler; rotate the key.

## H3 — `profiles` SELECT policy is fully public, leaking phone PII
`supabase/migrations/20251121221500_create_friendships_and_profiles.sql:42-44` (`USING (true)`)

Every `profiles` row is readable by any caller. A later migration adds `phone_number`/`phone_hash`, so raw numbers and hashes of all users are world-readable — a mass PII scrape vector when combined with the exposed anon key.

**Fix:** Restrict SELECT to non-sensitive columns (use a view or column grants); never expose `phone_number`/`phone_hash`; gate sensitive lookups behind the `find_profiles_by_phone` RPC only. Add `WITH CHECK (auth.uid() = id)` to the UPDATE policy (currently missing, same file lines 52-54).

## H4 — `send-sms` edge function has no JWT verification or rate limiting
`supabase/functions/send-sms/index.ts:17-48`

Sends a Plivo SMS to any `phone` in the request body with no auth check and no rate limit — an open SMS-bomb / toll-fraud relay if directly invokable.

**Fix:** Restrict to the Supabase Auth SMS hook (validate hook secret/JWT), or set `verify_jwt = true` plus per-recipient rate limiting.

## H5 — `chat_attachments` storage bucket is world-readable
`supabase/migrations/20251125145500_fix_storage_policies.sql:1-16`

The bucket is `public` and SELECT is granted `to public`, so all private DM attachments are readable by anyone with the path; INSERT isn't path-scoped to the uploader.

**Fix:** Make the bucket private; SELECT restricted to conversation participants; scope INSERT paths to the uploader's user id.

## H6 — UI widgets bypass repositories and hit Supabase directly
`lib/features/moments/presentation/moment_details_page.dart:258,716,1169,1495-1523`; `chat_page.dart:231,265,1105`; `story_viewer_page.dart:195`

Widgets call `Supabase.instance.client.from('…').update(...)` inside `setState` handlers, bypassing the repository layer and duplicating business logic (e.g. the privacy cascade at `moment_details_page.dart:1495-1523`). This makes the data layer untestable and the logic unmaintainable.

**Fix:** Move every `.from(...)` query into the relevant repository method, expose via a provider; widgets only `watch`/`read`.

## H7 — Realtime streams pull the **entire** `friendships` table and filter in Dart
`lib/data/repositories/social_repository.dart:422-466`

The Supabase stream has no server-side `.eq` filter (`primaryKey: ['id']` only), so every client receives **all** friendship rows and filters `friendId == userId` in Dart (a comment even notes `.eq()` "is not supported on stream builder"). Data exposure + cost that scales with total app rows.

**Fix:** Use a filtered stream / RLS-scoped view so only the user's rows are pushed.

## H8 — N+1 queries inside realtime stream mappers
`lib/data/repositories/moment_repository.dart:1057-1078` (`watchContributors`), `1097-1146` (`watchPendingInvitations`)

Inside `.asyncMap`, the code loops per row and issues a separate `profiles`/`moment_groups` query per contributor **on every stream emission** — N (or 3N) sequential round-trips each tick.

**Fix:** Batch with a single `inFilter('id', ids)` (as `watchCommentsForMoment` already does correctly) or a Postgres join/RPC.

## H9 — Per-frame `setState()` rebuilds entire pages (multiple rebuild storms)
- `moment_details_page.dart:429-450` — each card's `SingleMotionController` listener calls `setState()` every frame, rebuilding the whole 2,586-line page for all cards at once during entry animation.
- `map_page_v2.dart:1029-1077` — `setState` per resolved marker image; `_invalidateMarkerCaches` does `setState(() => _bitmapCache.clear())` then re-renders **every** marker as avatars stream in (O(N) canvas work on the main thread while panning).
- `friend_profile_page.dart:42-51` — `_tabController.animation` listener `setState(() {})` ~60×/s, rebuilding the whole `NestedScrollView`.
- `story_viewer_page.dart:54-60` — `_progressController.addListener(() => setState(() {}))` rebuilds the full viewer every frame; listener never removed.

**Fix:** Drive animations with `AnimatedBuilder`/`ListenableBuilder` scoped to the animating subtree (or `Transform`/`Opacity` directly). For the map (imperatively updated), invalidate only the affected marker's cache entry and debounce; don't `setState`.

## H10 — Leaked stream/player subscriptions firing `setState` after dispose
- `add_moment_page.dart:70-78` — three `_audioService` stream `.listen(...)` calls in `initState`, never stored or cancelled.
- `music_picker_sheet.dart:142,156-160` — `_togglePreview` adds a new `playerStateStream` listener on every tap; none stored/cancelled.
- `video_player_widget.dart:27-87` — no `didUpdateWidget`; stale controller kept/leaked when `videoUrl` changes.

**Fix:** Store subscriptions as fields, cancel in `dispose()`; create players once in `initState`; add `didUpdateWidget` to dispose+recreate controllers on prop change.

## H11 — Five overlapping hand-rolled image caches reinventing `flutter_cache_manager`
`cache_manager_service.dart`, `avatar_cache_service.dart`, `map_cache_service.dart:94-149`, `features/chat/services/media_cache_service.dart`, plus inline image caching

Each independently implements: hash a URL → `http.get` → write to a per-feature dir → return path → custom size/cleanup. `flutter_cache_manager` (already a transitive dep) and `cached_network_image` already do this. Worse, `CacheManagerService` and `GarbageCollectionService` both **hardcode the same cache directory strings** (`garbage_collection_service.dart:65-193`) and reimplement `_directorySize`, so they drift out of sync silently.

**Fix:** Collapse onto a single `flutter_cache_manager`-backed helper with per-feature `CacheManager` instances (configurable maxAge/maxSize). Each cache service exposes its own dir/size/evict API; GC and the aggregator delegate instead of hardcoding paths.

## H12 — GC deletes media files with no awareness of pending uploads → data loss on offline send
`lib/core/services/garbage_collection_service.dart:126-201`, interacting with `chat_powersync_connector.dart:78-104,432-491`

GC evicts files purely by mtime/total-size and never checks whether a file backs a `local_only`/`pending` message. An offline media message whose file is evicted before upload becomes permanently failed — and because media upload happens **inside** the CRUD upload transaction, a missing file triggers `_PermanentCrudFailure` + `transaction.complete()`, discarding the queue entry with no retry.

**Fix:** Exclude files referenced by rows where `local_only = 1` or `send_status IN ('pending','sending','failed')` from eviction. On transient upload failure, throw (leave the transaction pending) rather than completing it.

## H13 — Optimistic message UUID never reconciled with server row
`chat_mutation_service.dart:66-83`, `chat_powersync_connector.dart:210-233`

`sendTextOptimistic` generates a client UUID; the connector `upsert`s it with `onConflict: 'id'` and marks it synced. This only works if the server accepts client PKs and never rewrites the id. `replaceLocalMessageWithServer` (`chat_powersync_service.dart:704-756`) exists to swap ids but **has no caller** — if the server ever assigns its own id, the optimistic row and the synced row diverge into a duplicate PowerSync streams back down.

**Fix:** Confirm the DB accepts client UUIDs as canonical PK (no server-side id generation), or wire up the id reconciliation that `replaceLocalMessageWithServer` was built for.

## H14 — `friendsList` keepAlive provider never closes its realtime subscription
`lib/core/providers/providers.dart:293-351`

`@Riverpod(keepAlive: true)` ending in an unbounded `await for (… in socialRepo.streamFriendshipChanges())` with no `ref.onDispose`. The realtime stream + a full re-fetch (`getFriendIds` → `getFriends` → `inFilter`) live for the whole session and re-run on every friendship change.

**Fix:** Drop `keepAlive` (or add `ref.onDispose` to cancel), and feed the realtime payload directly instead of full re-fetching each event.

## H15 — Duplicate friend-request providers → double subscriptions for identical data
`providers.dart:354-358` (`pendingRequests`, one-shot) vs `realtime_providers.dart:9-13` (`pendingRequestsRealtime`, stream)

Both fetch the same data; some screens watch the polling one and manually `ref.invalidate` it in many places while a live stream for the same data also runs.

**Fix:** Standardize on the realtime provider; delete `pendingRequests` and its scattered invalidations.

## H16 — DB/network calls in `itemBuilder`/`build` (per-cell, per-rebuild)
`friend_profile_page.dart:657-677` (`FutureBuilder` → `db.getLocalMediaPath` per grid cell), `timeline_gallery_page.dart:973` (`_loadImagesForMoments` in the build data handler), `memory_lane_page.dart:652-657` (`SignedUrlCache.getSignedUrl` from widget state)

Data fetching runs from the widget on every rebuild/scroll instead of a cached provider.

**Fix:** Resolve local paths / signed URLs in a Riverpod provider returning a `{momentId: path}` map, fetched once and watched.

## ~~H17 — Notification list is not realtime; only the badge count is~~ ✅ **FIXED** (2026-06-30) _(N4)_
> Both list and count are now PS `watchQuery` streams from the local SQLite copy of `notifications`. The Supabase realtime channel (`notification-changes-$userId`) + the `getNotifications` one-shot call are gone. A single `notifications` PS sync stream powers everything.

## ~~H18 — Offset pagination over a live-mutating table double-counts / skips rows~~ ✅ **FIXED** (2026-06-30) _(N3)_
> Dissolved by PS migration — offset pagination is gone. PS `watchQuery` returns all local rows ordered by `created_at DESC`; no page/range needed.

## ~~H19 — Cold-start deep-link retry loops uncapped; no auth gate~~ ✅ **FIXED** (2026-06-30) _(N5)_
> Replaced the infinite `Future.delayed(500ms, retry)` with a `static Map _pending` store. `drainIfPending(context)` is called from the router's `redirect` once `isSignedIn && !isOnSplash` — guaranteed mounted and authed. Tab navigations (`/chats`, `/`) now use `context.go()`; `new_moment_group` uses `context.go('/')` instead of `popUntil`.
`notification_navigator.dart:48-56,79-96`

## H20 — N+1 profile fetch per friend-request card, in `build()` _(N6)_
`notifications_page.dart:540-566`

Each friend-request item does `ref.watch(friendProfileProvider(request.userId))` — one round trip per visible card, in build. **Fix:** batch-fetch actors once (single `in` query) or include the actor in the `pendingRequests` query.

## ~~H21 — `markAllAsRead` fires on a 100ms timer racing the list load~~ ✅ **FIXED** (2026-06-30) _(N7)_
> Timer + `ref.invalidate` removed. PS local SQL UPDATE (`is_read=1 WHERE is_read=0`) runs synchronously in `initState` post-frame; the live stream re-emits with all rows marked read immediately. Single write path.
`notifications_page.dart:149-156`

## H22 — FCM permission requested cold at launch; no Android 13+/iOS denial handling _(N8)_
`firebase_messaging_service.dart:128-138`, `notification_settings_page.dart`

No priming, no re-prompt/settings deep link on denial, and the settings master switch only toggles a DB column — never reflects OS permission. **Fix:** request contextually post-onboarding; show rationale + settings link on denial; reflect real OS permission.

## ~~H23 — `main_scaffold` doesn't compile after the `flutter_floating_bottom_bar` 2.0 bump~~ ✅ **FIXED** (2026-06-30)
> Migrated the scaffold to the 2.0.x API: old top-level `BottomBar` params moved into `BottomBarLayout` (width/offset/borderRadius), `BottomBarThemeData.barDecoration` (bar color), `BottomBarScrollBehavior` (hideOnScroll/scrollOpposite), and `BottomBarMotion.curved` (200ms). `body` is now a plain `TabBarView` — 2.0.x auto-hides the bar via `ScrollNotification` bubbling, so pages no longer need a `ScrollController` passed (`scrollController: null`). `lib/` analyzes clean.

---

# 🟡 MEDIUM

## M1 — Redundant `Profile` vs `UserProfile` models for the same table
`lib/data/models/profile.dart` vs `lib/data/models/user_profile.dart`

Two models describe the same `profiles` table with near-identical fields; both are actively used (repos return `Profile`, several pages + `user_profile_service.dart` use `UserProfile`), so the app maintains two parallel mappings and converts implicitly.

**Fix:** Consolidate into one `Profile` (port `displayNameOrUsername` onto it); delete `UserProfile` and the duplicated `user_profile_service.dart`. _(Note: `reaction.dart` vs `moment_reaction.dart` are genuinely distinct — message vs moment reactions — not duplicates.)_

## M2 — Three divergent PowerSync sync-rule specs
`sync_rules.yaml`, `sync_streams.yaml` (both marked DEPRECATED) vs `powersync/sync-config.yaml`

`sync_streams.yaml` is chat-only; `sync-config.yaml` adds the whole `moments_home` stream; `sync_rules.yaml` uses the old bucket format referencing tables not in the canonical streams. Deploying the wrong one silently changes what data exists on-device.

**Fix:** Delete `sync_rules.yaml` and `sync_streams.yaml`; keep only `powersync/sync-config.yaml`.

## M3 — Soft-delete visibility differs between the two read paths
`chat_repository.dart:64-70` vs `chat_powersync_service.dart:121,131-134`

The Supabase path filters `isDeleted && deletedFor != 'everyone'` + `deletedFor == currentUserId`; the PowerSync path filters `COALESCE(is_deleted,0)=0` in SQL plus `deletedFor != currentUserId` in Dart. Not equivalent — a message can be visible via one path and hidden via the other.

**Fix:** Centralize the visibility predicate once a single read path is chosen (see C3/C4).

## M4 — Avatar cache keyed by `String.hashCode` (collisions, non-stable)
`lib/core/services/avatar_cache_service.dart:286,333`

Filenames use `url.hashCode.toRadixString(16)`. Dart's `String.hashCode` isn't collision-resistant or stable across runs/platforms → wrong avatar served or cache misses. Every other service uses sha256 (`map_cache_service.dart:332`).

**Fix:** Hash with sha256.

## M5 — Encryption / init failures silently swallowed across services
`firebase_messaging_service.dart:46,67,78,561`; `audio_note_service.dart:127,175,184`; `moment_storage_service.dart:279,303`; `ai_service.dart:259,404,489`; `avatar_cache_service.dart:75-82`

Numerous `catch (_) {}` with no log (e.g. Supabase/Firebase init failure in the background handler → notifications silently do nothing). `AvatarCacheService.initialize` swallows errors but still sets `_initialized = true`, so partial caches are treated as authoritative.

**Fix:** Log via `AppLogger` in every catch; for init failures that gate functionality, surface/retry. Track an init-failed state distinct from init-complete.

## M6 — `momentDetails` provider silently mixes PowerSync + direct-Supabase sources
`lib/core/providers/moments_providers.dart:59-79`

Reads from PowerSync, and on miss silently falls back to `repo.getMomentById` (direct Supabase). Watches `momentRepositoryProvider` unconditionally; the two sources can return divergent shapes/freshness with no signal.

**Fix:** Make the fallback explicit (log + flag) and resolve the repo lazily only in the fallback branch.

## M7 — `SignedUrlCache` is process-global static state, not cleared on logout
`lib/core/services/signed_url_cache.dart:8-13`

Entirely `static` (`_cache`, `_failedPaths`) — untestable, and not cleared on user logout unless someone remembers `clearCache()`. Inconsistent with the DI'd avatar/storage services.

**Fix:** Convert to an instance behind a Riverpod provider tied to the auth session so it auto-clears on logout. Also: `MapCacheService.preloadMomentImages` (`map_cache_service.dart:178-181`) regenerates signed URLs directly and caches under the (expiring) signed URL — route through `SignedUrlCache` and hash only the stable `media_path`.

## M8 — Async work fired-and-forgotten in notifier `build()`
`theme_provider.dart:16-20`, `map_state_provider.dart:43-47`, `providers.dart:52-57` (`aiService.initialize()`), `currentUserProfile` at `providers.dart:71-75`

`build()` returns a sync default then kicks off async loads that mutate `state` later with errors swallowed (visible flash + lost loading/error state). `aiService` returns un-awaited after firing `initialize()`. `currentUserProfile` doesn't depend on auth state, so it won't refresh on sign-in/out.

**Fix:** Use async notifiers (`Future<T>` `build`) / `FutureProvider`; `watch(currentUserProvider)` inside `currentUserProfile`.

## M9 — `clearAllCaches` nukes the entire temp directory
`lib/core/services/cache_manager_service.dart:284-304`

`_clearTempFiles` deletes everything under `getTemporaryDirectory()` — including `mapbox_cache`, `libCachedImageData`, and files possibly in active use by other isolates.

**Fix:** Delete only known app-owned temp subpaths.

## M10 — `MapboxMap`/annotation manager not disposed
`friend_profile_page.dart:800-856`

`_mapboxMap`/`_annotationManager` created in `_onStyleLoaded`, never disposed or listeners removed in `dispose()`.

**Fix:** Dispose the annotation manager and remove listeners in `dispose()`.

## M11 — `MediaCacheService` keys cache by `messageId` only, shared across media types
`features/chat/services/media_cache_service.dart:12,22-32,130-135`

Cache key ignores the URL, so a changed media URL returns the stale file forever; and `getAudioFile`/`getImageFile`/`getVideoFile` share one `_filePathCache[messageId]`, so the same id requested as two types returns the wrong file. `_waveformCache` is dead state.

**Fix:** Include a URL hash and media-type namespace in the key; delete the dead waveform code.

## M12 — Synchronous large-image decode + clustering on the main thread
`moment_share_card.dart:525-543`, `add_moment_page.dart:718` (`Image.file` with no `cacheWidth/Height`); `memory_lane_page.dart:292-340` (`_clusterByLocation` O(n) in `SliverChildBuilderDelegate`)

Full-res local images decode on the UI thread; clustering runs per-render during scroll → jank.

**Fix:** Pass `cacheWidth`/`cacheHeight` sized to the display box; pre-compute clustering once in a provider keyed by chapter.

## ~~M13 (strategic) — Notifications → PowerSync~~ ✅ **FIXED** (2026-06-30) _(DECIDED, D7)_ _(N9)_
> Implemented. `notifications` table added to PS schema + `sync-config.yaml` (`WHERE user_id = auth.user_id()`). Supabase migration adds `actor_name`/`actor_avatar_url` columns with a BEFORE INSERT trigger that denormalizes from `profiles` — no join needed offline. Connector handles PATCH (`is_read`) and DELETE. `NotificationRepository` rewritten to use `watchQuery`/`execute` via `ChatPowerSyncService`. `notificationCount` and `NotificationsList` now drive from local PS streams. RLS tightened (was `USING(true)`, now auth-scoped).
spans `notification_repository.dart`, `providers.dart`, `notifications_page.dart`

## M14 — Notification count channel/controller leaks across logout _(N10)_
`notification_repository.dart:13-14`

Keep-alive provider keeps streaming the previous user's count after logout. **Fix:** tear down on `onAuthStateChange`.

## M15 — Swipe = permanent hard DELETE, no undo; `_dismissedIds` grows unbounded _(N11)_
`notifications_page.dart:507-515`, `providers.dart:185-213` — double-filters on top of optimistic removal. **Fix:** offer undo before committing; drop the parallel `_dismissedIds` set.

## M16 — `_combineNotifications` re-merges+sorts every build; triple-nested `.when` pyramid _(N12)_
`notifications_page.dart:237-273` — one source in `loading` hides all others. **Fix:** memoized derived provider; render partial data.

## M17 — 1116-line notifications god widget doing fetch + shaping + nav _(N13)_
`notifications_page.dart` — duplicates the local-first moment fetch from `notification_navigator.dart:200-215`. **Fix:** extract a controller/service; share the local-first fetch.

## M18 — Notification type→behavior mapping duplicated & divergent across 3-4 layers _(N14)_
`notifications_page.dart:351-365`, `notification_navigator.dart:58-96`, `firebase_messaging_service.dart:476-506`, push `index.ts` — they disagree. **Fix:** one shared type enum + route/label/channel map.

## M19 — Background reply re-inits Firebase/Supabase per action; failed reply still dismisses the notification _(N15)_
`firebase_messaging_service.dart:56-81,240-260,329-334` — `catch (_) {}` hides init failures; a failed reply dismisses anyway so the user thinks it sent. **Fix:** centralize background init with surfaced errors; keep the notification on failure.

## M20 — Opening the notifications page calls `cancelAllNotifications()` _(N16)_
`notifications_page.dart:147` — wipes unrelated active chat threads from the tray. **Fix:** cancel only the items being marked read.

---

# ⚪ LOW

| ID | Issue | Location | Fix |
|----|-------|----------|-----|
| L1 | `main()` awaits independent inits serially (slow cold start) | `main.dart:25-46` | `Future.wait` the independent inits; defer messaging past first frame |
| L2 | `MaterialApp` ignores `darkTheme`/`themeMode` — `darkThemeProvider` + persisted theme are dead | `main.dart:116-123` | Wire `darkTheme`/`themeMode`, or delete the unused providers |
| L3 | `NotificationsList` pagination state in mutable instance fields (invisible to Riverpod) | `providers.dart:108-165` | Fold `hasMore`/`isLoadingMore` into the notifier's state type |
| L4 | `appRouter` provider just wraps a static singleton (no reactive redirect) | `router_provider.dart:8-11` | Make it auth-reactive or drop the provider |
| L5 | Drift migrations re-add the same columns with `catch (_) {}` (hides corruption) | `database.dart:210-315` | Idempotent column-existence checks, not catch-all |
| L6 | God widgets / 900+ line build methods, untestable | `chat_page.dart:499-1414`, `add_moment_page.dart:129-623`, `moment_details_page.dart` (2,586 LOC) | Extract `const` section widgets |
| L7 | `ref.listen` registered inside `build()` (re-registers each rebuild; add_moment mutates controller mid-build) | `moment_details_page.dart:2295-2301`, `add_moment_page.dart:133-151` | Use `ref.listenManual` in `initState` (map_page_v2:121 does it right) |
| L8 | `setState` UI state coexists with Riverpod (two sources of truth) | `chat_page.dart` (11+ calls), `timeline_gallery_page.dart`, `add_moment_page.dart` | Move into providers, watch narrowly |
| L9 | Duplicated UI: 3 near-identical speed-dial FABs, dup tile builders | `map_page_v2`, `moment_details`, `timeline_gallery_page.dart` | Extract shared `SpeedDialFab` / `MomentTile` |
| L10 | Pervasive hardcoded colors/strings/dimensions instead of theme | `moment_details_page.dart`, `chat_page.dart`, `memory_lane_page.dart`, … | Move to `AppTheme` + a strings/i18n layer |
| L11 | Widespread missing `const` constructors (compounds rebuild storms) | all large UI files | Enforce `prefer_const_constructors` lint |
| L12 | Phone hash is unsalted SHA-256 of a 9-digit number (≤10⁹ keyspace, brute-forceable + publicly readable per H3) | `phone_hash_service.dart:23-27` | Server-side keyed HMAC; never expose the hash column |
| L13 | Committed debug/placeholder SQL (`webhooks.sql:22,63` placeholder anon key, `debug_friend_requests.sql`) | repo root | Remove; rely on vault-backed `resolve_edge_anon_token()` |
| L14 | `firebase_options.dart` git-tracked despite being in `.gitignore` (ineffective — already committed) | `lib/firebase_options.dart` | Decide tracked-or-not deliberately; ensure Firebase backend rules don't rely on key secrecy |
| L15 _(N17)_ | `notification_settings_page` ignores its own provider; parallel `_preferences` field + `setState` + post-write `invalidate` | `notification_settings_page.dart:99-167` | Watch the provider with a `Notifier` doing optimistic updates; drop the duplicate field |
| L16 _(N18)_ | Notification errors shown as raw strings / `SizedBox.shrink()` / `catch (_)`; no retry affordance | `notifications_page.dart:262-263,564,1002` | Provide retry UI; stop leaking exception strings |
| L17 | Chat context-menu "+" emoji button is a dead `// TODO: Show emoji picker` | `message_context_menu.dart:246` | Wire `emoji_picker_flutter` (see research) |

---

# 📦 Dependency Audit

Usage counts are imports across `lib/`. **None** of the "dead" packages are referenced anywhere in the repo.

## Remove immediately — 0 imports (dead weight)

| Package | Notes |
|---------|-------|
| `animations` | 0 uses. You already have 4 other animation libs. |
| `button_m3e` | 0 uses. |
| `icon_button_m3e` | 0 uses. |
| `avatar_stack` | 0 uses. |
| `supercluster` | 0 uses — yet you do map clustering, so clustering is hand-rolled/native elsewhere. Remove the unused dep. |
| `geocoding` | 0 uses — `geocoding_service.dart` uses `http` directly, not this package. |
| `connectivity_plus` | 0 uses — no `Connectivity` reference anywhere. PowerSync handles connectivity internally. |

## Pin / fix

| Package | Issue | Fix |
|---------|-------|-----|
| `giphy_get : any` | Unpinned `any` version — non-reproducible builds, can break on any upstream release. | Pin to a concrete `^x.y.z`. |

## Redundant / consolidate

| Area | Packages present | Recommendation |
|------|------------------|----------------|
| **Local DB + sync** | `drift` + `sqlite3_flutter_libs` **and** `powersync` (its own embedded SQLite + sync engine) | Pick one. PowerSync is the live read path (see C1). Removing Drift for synced entities drops `drift`, `drift_dev`, `build_runner` (Drift portion), and a whole DB file. |
| **Animation** (5 libs) | `flutter_animate` (1 use), `motor` (1), `animations` (0), `lottie` (5), `dotlottie_loader` (1) | Drop `animations` (dead). Consider collapsing `flutter_animate` + `motor` (1 use each) into one. Keep `lottie`; `dotlottie_loader` only if you actually ship `.lottie` files. |
| **Media pickers** | `image_picker` (5), `wechat_assets_picker` (3) | Two pickers covering overlapping flows. Standardize on one. |
| **Compression** | `flutter_image_compress` (1), `video_compress` (3) | Both funnel through `MediaCompressionService` (OK), but `video_compress`'s temp cache is then managed in 3 separate places (see H11). Keep both only if you genuinely need image+video; centralize the cache. |
| **Material3 niche** | `button_m3e` (0), `icon_button_m3e` (0), `progress_indicator_m3e` (1), `flutter_m3shapes_extended` (1) | First two are dead. Last two are single-use third-party M3E packages — evaluate whether the stock Material 3 widgets suffice. |
| **Image cache** | `cached_network_image` (20) + transitive `flutter_cache_manager` | Already present and capable — use it instead of the 5 hand-rolled caches in H11. |

**Confirmed NOT redundant** (keep): `just_audio` (playback, 6) vs `record` (recording, 1) are different jobs. `logger` (1) backs the `AppLogger` wrapper used in 58 files — not duplicated. `video_player` (4) + `chewie` (1) is the standard player+controls pairing.

---

# Follow-up investigations (2026-06-29)

Three deeper dives prompted by the maintainer decisions above.

## PowerSync migration — service & repository fate (D1/D2)

**Correction to C1:** the PowerSync schema (`chat_powersync_schema.dart`) already declares **10 tables** (profiles, conversations, conversation_participants, messages, message_reactions, moment_groups, moments, moment_contributors, moment_reactions, moment_comments) — not just chat+moment. The real gaps are **`friendships`** and **`notifications`**, which aren't in the schema at all. `sync-config.yaml` joins on `friendships` for visibility but never *replicates* friendship rows to the device, so **the friend graph is currently invisible locally**.

`ChatMutationService` is already the correct PowerSync-first template — every other domain should follow its shape.

### Services

| File | Verdict | Why |
|------|---------|-----|
| `pending_action_service.dart` | **DELETE** | PowerSync's CRUD upload queue replaces the hand-rolled queue entirely (confirms C2). |
| `moment_storage_service.dart` | **DELETE (mostly)** | Row mirror replaced by PS tables. Keep only media download + `local_media_path` bookkeeping → fold into a small media-cache helper that writes back to the PS `moments` row (schema already has `local_media_path`/`local_thumbnail_path`). |
| `data/services/user_profile_service.dart` | **DELETE** | All 4 methods are `profiles` selects/upsert — now local PS reads. Redundant with PS + `AvatarCacheService` (resolves M1's service half). |
| `chat_mutation_service.dart` | **KEEP** | Already fully PowerSync-first. The template. |
| `avatar_cache_service.dart` | **REWIRE** | Drop `_database`, `_persistAvatarUrl`, and the `.from('profiles')` fetch (read `avatar_url` from PS `profiles`). Keep only file-download + `ImageProvider` layer. Also fixes M4 (sha256) while in there. |
| `signed_url_cache`, `cache_manager_service`, `map_cache_service`, `garbage_collection_service`, `audio_note_service`, `video_controller_manager`, `geocoding_service`, `share_service` | **KEEP** | Binary media caches, storage uploads/signed URLs, geo HTTP, runtime controllers — PS syncs rows, not files/auth. (H11/M9 cleanups still apply.) |
| `offline_media_policy_service.dart` | **KEEP & EXPAND** | The control plane for the **moment-media** opt-in (D8) — governs which moment images/videos get pulled local. Rows always sync; this gates only the heavy bytes. |
| `powersync/chat_powersync_service.dart` | **KEEP — promote & extend** | Drop the "chat" framing; it's the single sync/read service. Add watch/get/upsert for comments, moment_reactions, contributor writes, profiles, friendships. |
| `powersync/chat_powersync_connector.dart` | **KEEP — extend** | `_applyCrudEntry` currently routes only messages/message_reactions/participants. Add cases for moments, moment_groups, moment_contributors, moment_reactions, moment_comments, profiles, friendships. Relocate moment image/video Storage uploads here (mirror the existing chat-attachment `_resolveMediaUrl` path). |
| `powersync/chat_powersync_schema.dart` | **KEEP — extend** | Add `friendships` and `notifications` (both now required — D7). |

### Repositories — what moves vs what stays

The pattern for every repo: **raw `.from().insert/update/delete` → PowerSync local writes**; **RPCs, Storage uploads, ephemeral realtime, auth → stay**.

- **`chat_repository.dart` — REWIRE, mostly redundant.** Move: send/edit/delete message, add/remove reaction, markAsRead, all reads (`streamMessages`→`watchMessages` already exists). **Keep:** `getOrCreateConversation`, `getRecentConversations`, `markMessagesDelivered`, `streamUnreadCount` (RPCs); file uploads (Storage — the row insert moves, the upload goes in the connector); `sendTyping`/`subscribeToTyping`, `streamConversationsChanged` (ephemeral realtime). _(This is the concrete plan for C3/C4.)_
- **`moment_repository.dart` — REWIRE, split.** Move: `updateMoment`, delete row parts, reaction/contributor/comment CRUD, all reads/streams (`stream*`→`watch*`). **Keep:** `createMoment`/`createMomentsBatch` (RPC `create_moment_batch` + image/video uploads), `getMomentsByLocation`/`getNearbyGroups` (PostGIS RPCs), Storage removes. Fixes H8's N+1 for free (local SQL joins).
- **`social_repository.dart` — REWIRE after `friendships` is added to PS.** Move: profile updates, friend request/accept/reject/remove, friend/profile reads (resolves H7's full-table stream and H14's keepAlive leak — they become local PS queries). **Keep:** `getMutualFriendsCount`, `getUserMomentsCount`, `searchProfiles`, `findProfilesByPhone`, `findNearbyUsers` (all RPCs).
- **`notification_repository.dart` — REWIRE to PowerSync (D7).** Add a `notifications` PS table + sync stream; the list and unread count become local SQL queries. Move `markAsRead`/`markAllAsRead`/`deleteNotification` to PS local writes + connector upload. **Denormalize the actor (name/avatar) onto the row** so no `actor:actor_id` join is needed offline. **Keep server-side:** the FCM push path that *inserts* notifications (unchanged — PS syncs them down). The unread-count RPC can be retired in favor of the local count.

### What PowerSync can NOT do (must keep)

RPCs/edge functions · Storage uploads/downloads + signed URLs · binary media caching & GC · ephemeral realtime (typing, count channels, conversation pings) · auth/session · device-local prefs (`offline_media_policy_service`) · server-side geo/full-text/aggregation (PostGIS, phone-hash, search).

## chat_bubbles vs custom chat UI (D2) — verdict: ADOPT MORE (you're ~80% there)

_Re-audited by reading the actual installed `chat_bubbles-1.10.1` source — the first pass missed two exported widgets and mis-scored the verdict._

The bubbles themselves are **already well-adopted** (`message_bubble.dart` uses `BubbleNormal`/`BubbleReply`/`BubbleReaction`; `audio_message_bubble.dart` uses `BubbleNormalAudio`; `typing_indicator_bubble.dart` uses `TypingIndicatorWave`; image/gif use `BubbleNormalImage`). The remaining wins are concentrated in **one widget** (the context menu) plus two data-quality fixes — not a wholesale rewrite. Two things the first pass got wrong:

- **The package exports `ReactionPicker` and `ReactionOverlay`** (`reactions/bubble_reaction.dart:239,318`) — a horizontal emoji tray and a long-press overlay that shows it. The first review never mentioned these.
- **`BubbleNormalAudio` renders the waveform itself** (internal `_WaveformPainter`, `bubble_normal_audio.dart:12`) and supports tap/drag-to-seek + 1x/1.5x/2x speed. You only feed `waveformData`.

### Adoption table (corrected, verified against source)

| Widget | State today | Action |
|--------|-------------|--------|
| `message_bubble.dart` | Already `BubbleNormal`/`BubbleReply`/`BubbleReaction` | **Keep.** Wrapper adds deleted-state, reply-text builder, reaction dedup, send-status→ticks, retry hint — none of which the package does. _Timestamp note (your concern):_ `timestamp:` renders **inside** the bubble's bottom-right status row (`bubble_normal.dart:228`), so it does **not** affect message ordering. For the "minimal feel," drop the per-bubble timestamp and surface time via `DateChip` on group boundaries / on tap. |
| `audio_message_bubble.dart` | Already `BubbleNormalAudio` + `showPlaybackSpeed` | **Keep widget, fix data.** It passes `AudioNoteService.generateFakeWaveform(...)` (`audio_message_bubble.dart:203`) — the waveform is **fake**, not real amplitude. Either compute a real waveform at record time and store it on the message, or keep decorative bars but stop implying they're real. |
| `typing_indicator_bubble.dart` | Already `TypingIndicatorWave` (pure `CustomPaint`, no Lottie) | **Done — no action.** Your "Lottie wrapper" memory is stale; it's already the package's lightweight version. (The `Lottie.asset` calls at `chat_page.dart:597,665` are *other* art — empty/loading states — not the typing indicator.) |
| `image_message_bubble.dart` | `BubbleNormalImage` + `CachedNetworkImage` | **Keep wrapper** for local-vs-network resolution, sizing, error fallback (package takes a finished `image` widget only). |
| `gif_sticker_message_bubble.dart` | `BubbleNormalImage` + `CachedNetworkImage` | **Keep, but modernize sizing.** Sizes are hardcoded (`140×140` sticker, `220×220` gif — `gif_sticker_message_bubble.dart:73,90`). Revisit against current GIF/sticker conventions (see emoji/GIF research below). |
| `video_message_bubble.dart` | Custom | **Keep — no choice.** `chat_bubbles` has **no video bubble** (confirmed: no `bubble_*_video` file). Reusing `BubbleNormalImage` as a frame + play overlay is the right call. |
| `message_context_menu.dart` (361 lines) | Fully custom overlay | **THE consolidation.** See below. |
| reply composer banner (`reply_preview.dart`) + input bar (in `chat_page.dart`) | Custom | **Keep.** Do **not** adopt `cb.MessageBar`: it can't do edit-mode or media actions, and it creates its `TextEditingController` as a field on a `StatelessWidget` (`message_bar.dart:50`) → recreated every rebuild, loses text. Its reply UI is a bare `"Re : X"` row, inferior to yours. |
| grouping | Already `MessageGroupHelper.compute` (`chat_page.dart:693`) | **Done.** |

### The one real refactor — `message_context_menu.dart`

It's a 361-line hand-rolled `OverlayEntry` with **fragile manual position math** (`top = anchorRect.top - 220; if (top < 60) top = 60` — `message_context_menu.dart:78`) and a **dead button**: the "+" emoji has `// TODO: Show emoji picker` (line 246) and does nothing. Split it:

1. **Reaction row → `cb.ReactionPicker`** (or wrap the bubble in `cb.ReactionOverlay`), and wire the "+" to a real emoji picker (package rec in the research below).
2. **Action list (reply/copy/edit/delete) → native `showModalBottomSheet`** with `ListTile`s. This deletes all the manual overlay positioning and is accessible/scrim-correct for free.
3. **Do NOT use `flutter_floating_bottom_bar` for this.** It's resolved at **1.4.0** (your pubspec `^1.3.0`), and it is a *scroll-reactive floating **nav** bar* — it hides/shows on scroll and holds a TabBar (`bottom_bar.dart:65,281`). Even the 2.0.x rewrite is still a nav bar, not an action/context menu. Wrong tool. Keep it for its single legitimate use (the main-scaffold nav, 1 file). _Bumping to 2.0.2 buys you a richer nav bar, not a menu — only do it if you want that for the scaffold._

**Net corrected verdict:** keep `chat_bubbles` (off the dependency cut list), keep the wrappers, and bank three wins — (1) collapse the context menu into `ReactionPicker` + a native bottom sheet (deletes ~200 lines of overlay math + the dead TODO), (2) real-vs-fake audio waveform decision, (3) modernize GIF/sticker sizing + wire a real emoji picker. The C3/C4 sync work is independent — it's the *mutation path behind* these widgets.

_The notifications subsystem findings are now distributed across the severity tiers above (C9, **C10**, **H17–H22**, **M13–M20**, **L15–L16**), each tagged with its `N#` for traceability._

## Emoji / GIF / reaction modernization (research, 2025-2026)

Backs the three chat consolidations above. Sourced from primary docs; pixel sizes are de-facto, not vendor-published.

- **Reaction tray — hand-roll it.** The closest off-the-shelf package, `flutter_chat_reactions`, is **GPL-3.0 (copyleft)** — unusable in a closed-source app. Your `message_context_menu.dart` is already the right shape (`OverlayEntry` + scale animation); finish it with `cb.ReactionPicker` (or `emoji_picker_flutter` for the "+") rather than adopting a package.
- **Emoji picker:** `emoji_picker_flutter` (v4.x, de-facto standard, no real competitor) for the dead "+" button. Set `emojiTextStyle` if you want consistent color emoji.
- **GIFs — you're on the right provider.** **Tenor's API shuts down today (2026-06-30)**; you use **Giphy** (`giphy_get`) and no Tenor reference exists in `lib/` — no action, just don't add Tenor. Giphy `fixed_width` = 200px inline, `_small` = 100px thumbnails: your hardcoded **220px GIF / 140px sticker** (`gif_sticker_message_bubble.dart:73,90`) are close to convention (sticker is slightly large; 96–128dp is typical).
- **Animated emoji / stickers:** the proprietary sets (Genmoji, Memoji, Emoji Kitchen) are OS-locked *images*, not font glyphs — you can't reproduce them with text. If you want animated emoji, render **Lottie** (the `lottie` package decodes Telegram `.tgs` via `decodeGZip`); you already depend on `lottie`.
- **Jumbo emoji:** emoji-only messages of ≤3 should render ~3× inline size (universal convention) — not currently implemented in `message_bubble.dart`. Cheap, high-polish add.
- **⚠️ iOS gotcha:** open Flutter/Impeller bug renders color emoji as tofu boxes **on the iOS Simulator** (fine on real devices). Don't bundle `NotoColorEmoji.ttf` to "fix" it — it's >30MB and 7–15s to render. **Test emoji/reactions on real iOS hardware.**

---

# Live Supabase audit (inspected 2026-06-29)

Pulled from the running project (schema, RLS, functions, PostGIS, advisors), not the migration files. IDs `B#`. **Context: every table currently reports 0 rows** — so the ~50 "unused index" advisories are *no-traffic noise, not a signal to drop indexes*. Ignore them until there's real data.

## 🔴 / 🟠 correctness & security

**B1 (HIGH, broken feature) — App calls an RPC that doesn't exist.**
`increment_story_view_count` is invoked in `lib/` (story viewer) but **no such function exists** in the database (only `get_story_viewers` does). Every call returns a PostgREST 404 that the app swallows → **story view counts never increment.** Fix: create the function (`update stories set view_count = view_count + 1 where id = p_story_id`) or remove the call. _(Also flags that RPC errors are being silently eaten — cf. the error-swallowing findings.)_

**B2 (HIGH, security) — anon can EXECUTE every SECURITY DEFINER RPC.**
57 advisor warnings: `anon` (24) and `authenticated` (33) hold EXECUTE on all DEFINER functions. An unauthenticated caller with the anon key can run `find_profiles_by_phone`, `search_profiles`, `find_nearby_users`, `get_recent_conversations`, etc. — these run with owner privileges and bypass RLS. Fix: `REVOKE EXECUTE ON FUNCTION ... FROM anon, public;` then `GRANT EXECUTE ... TO authenticated;` for each. This is the single biggest backend security cluster.

**B3 (HIGH, security) — 11 functions have a mutable `search_path`.**
Including SECURITY DEFINER ones: `find_nearby_users`, `get_recent_conversations`, `get_or_create_conversation`, `get_conversation_with_friend`, `mark_messages_delivered`, `create_moment_batch` (the 6-arg overload), `search_profiles`, `search_curated_tracks`, plus invoker `get_story_viewers`/`get_friends_stories`/`handle_new_moment_contributor`. A DEFINER function without a pinned path is a privilege-escalation vector (search-path injection). Fix: add `SET search_path = ''` (schema-qualify refs) or `= public` to each.

**B4 (HIGH, PostGIS correctness bug) — `get_nearby_moment_groups` measures distance in DEGREES, not meters.**
It runs `ST_DWithin(geom, ST_MakePoint(lng,lat), radius_meters)` on `moment_groups.geom`, which is **`geometry(Point,4326)`** — for geometry, `ST_DWithin`'s distance is in **degrees**, so `radius_meters = 100` means *100 degrees* (≈ the whole planet). The query returns essentially every group. (`find_nearby_users` does it right — it casts `::geography`, so meters.) Fix: cast to geography — `ST_DWithin(geom::geography, ST_MakePoint(lng,lat)::geography, radius_meters)` — or convert the radius to degrees.

**B5 (CRITICAL, = H3 confirmed live) — `profiles` SELECT policy is `USING (true)`.**
Verified on the live DB: policy "Anyone can view profiles" exposes every row — including `phone_number` and `phone_hash` — to anon. See H3 for the fix (column-scoped view / drop sensitive columns from the public read).

## 🟡 schema & PostGIS hygiene

**B6 (MEDIUM) — Mixed spatial types.** `moments.geom` = `geography(Point,4326)` but `moment_groups.geom` = `geometry(Point,4326)`. Standardize on **geography** (meters, simplest for "within X m"). Making `moment_groups.geom` geography + a geography GiST index also lets `find_nearby_users` use an index instead of casting `geometry→geography` per row (today it can't use `moment_groups_geom_idx`). Fixes B4 as a side effect.

**B7 (MEDIUM) — Redundant `friendships` indexes.** Eight indexes, several overlapping: partial `idx_friendships_user`/`idx_friendships_friend` (`WHERE status='accepted'`) **and** full `idx_friendships_user_id`/`idx_friendships_friend_id`, **plus two unique constraints** — `(user_id,friend_id)` *and* `friendships_unique_pair (LEAST,GREATEST)`. The `(user_id,friend_id)` unique permits reciprocal duplicate rows (A→B *and* B→A); `unique_pair` forbids them — so `unique_pair` is the real guard and the plain `(user_id,friend_id)` unique is redundant (unless an `onConflict` upsert depends on it — check before dropping). Keep: `unique_pair`, the status partials (hot "accepted friends" path), and one full index for pending-request lookups; drop the rest. _(Defer until there's data — empty DB.)_

**B8 (LOW) — Legacy geo extensions.** `earthdistance` + `cube` are installed alongside PostGIS, which supersedes them. If nothing uses `ll_to_earth`/`earth_box`, drop them. PostGIS/earthdistance/cube also live in the `public` schema (advisor "Extension in Public") — low-priority, move to an `extensions` schema if convenient.

**B9 (LOW, perf) — `auth_rls_initplan` on 4 tables.** `message_reactions`, `stories`, `story_views`, `moment_comments` policies still call bare `auth.uid()` (re-evaluated per row). Wrap as `(select auth.uid())` — most other tables already do. Unindexed FK `message_reactions.user_id` — add an index when traffic warrants.

**B10 (LOW) — Misc advisor.** Leaked-password protection is **disabled** (enable the HaveIBeenPwned check in Auth settings). `spatial_ref_sys` has RLS off (benign PostGIS reference table). Storage buckets are public + listable (3) — ties into H5.

## ✅ What's already good
- RLS avoids recursion cleanly via SECURITY DEFINER helpers `get_friends_of_user()` and `get_user_conversation_ids()` — the right pattern.
- Server-side housekeeping already exists: `storage-cleanup` edge fn, `cleanup_orphaned_storage`, `find_orphaned_moment_media`, `cleanup_empty_groups`, `cleanup_orphaned_notifications`. Coordinate these with the client media policy (D8/H12) so server GC and client GC don't fight.
- Notification triggers (`enqueue_push_notification`, `forward_notification_to_edge`) + `push-notification` edge fn (verify_jwt=true) are wired; the FCM token-on-logout leak (C9) is the gap, not the pipeline.

## Implications for the PowerSync migration (D1/D7)
PowerSync sync rules **cannot call** `get_friends_of_user()` / `get_user_conversation_ids()` (they're plpgsql). The rules must **reimplement those predicates inline as SQL**:
- **moments/groups:** `mine OR (NOT is_private AND author ∈ friends)` where `friends` = the `get_friends_of_user` UNION (`SELECT friend_id ... WHERE user_id=me AND status='accepted' UNION SELECT user_id ... WHERE friend_id=me AND status='accepted'`).
- **messages/participants:** scoped by "conversations I participate in."
- **friendships / notifications:** `WHERE user_id = me OR friend_id = me` / `WHERE user_id = me`.

Keep these in sync with the RLS policies above — if the two drift, the device sees a different dataset than the server authorizes. The geo RPCs (B4/B6) and search/phone RPCs stay server-side (PostGIS/full-text can't be sync rules), so the geometry→geography fix matters regardless of the migration.

---

# Routing review & go_router 17 migration (2026-06-30)

Reviewed `app_router.dart` on go_router **17.3.0** (was 14.x). Findings + what was done:

- **✅ Tabs are now real routes.** Previously the 4 tabs were internal `TabController` state inside `MainScaffold`, so they were **not deep-linkable** and used a hand-rolled `_KeepAlivePage` to preserve state. Migrated to **`StatefulShellRoute.indexedStack`** with 4 branches (`/`, `/spotlight`, `/explore`, `/chats`) — each tab is now a URL, state preservation is native (deleted `_KeepAlivePage` + the `TabController`), and the map branch has its own navigator key for an independent push stack.
- **✅ Extracted `AppNavbar`** (`widgets/app_navbar.dart`) — sliding pill-indicator `TabBar` with labels + unread badge on Chats; `MainScaffold` is now a lean `ConsumerWidget` shell builder hosting it in the floating `BottomBar`.
- **✅ Deleted phantom route.** `momentDetailRoute = '/moment/:id'` + `goToMomentDetail` were declared and would route to a non-existent `GoRoute` (→ error page) — and couldn't work anyway, since `MomentDetailsPage` needs a `moments` list + `locationName`, not an id. Both were unused; removed. (Real moment-detail nav is imperative `Navigator` pushes with the list, in 12 places — unchanged.)
- **Next (not yet done) — adopt `onEnter` for deep-link gating.** go_router **16.3.0** added a top-level `onEnter` callback with current+next route state. This is the clean fix for the notification deep-link handling (**H19/N5**): replace the fragile `navigatorKey.currentContext` 500ms retry loop in `notification_navigator` with router-level gating, and route notification taps to the new tab URLs (`context.go('/chats')` etc.). Also benefits: the **16.2.4** Android cold-start deep-link fix and **16.2.3** iOS back-gesture ShellRoute fix come for free on 17.x.
- **Note — 15.0.0 made URLs case-sensitive** (`caseSensitive` defaults true). All current routes are lowercase, so no impact — just don't introduce mixed-case paths.

---

# Recommended remediation order

1. **Stop the bleeding (security, this week):** C6 (`.env`→`dart-defines.json` per D3 + rotate service_role), **C9/N1 (FCM token on logout)**, H1/H2 (rotate Mapbox + Supabase keys), H3/B5/H4/H5 (RLS + edge function + bucket). **Backend (SQL, fast):** B2 (revoke anon EXECUTE on DEFINER RPCs), B3 (pin `search_path` on all DEFINER functions). Add the C8 OTP release-gate guard (D5). C7 encryption deferred to its redesign (D4).
1b. **Quick correctness fixes:** B1 (create the missing `increment_story_view_count` RPC — broken feature), B4 (PostGIS degrees→meters bug in `get_nearby_moment_groups`).
2. **PowerSync migration (D1/D2):** add `friendships` to the schema first (the friend graph isn't local today), then follow the per-repo move/keep table — C3/C4 single write path, C2/C5 (delete dead queue + storage service), H7/H8/H14 dissolve into local queries, H12/H13 (offline media + id reconciliation), M2/M3. Largest source of latent data-loss bugs. **Chat UI stays as-is — do not touch the `chat_bubbles` hybrid.**
3. **Kill dead code & deps:** the 7 zero-use packages, pin `giphy_get`, M1 + `user_profile_service` (`UserProfile`). Keep `chat_bubbles` (it's load-bearing). Drift drops out as a byproduct of step 2.
4. **Perf & leaks:** H9 (rebuild storms), H10 (subscription leaks), H16 (build-time queries), H11 (cache consolidation), N6/N12 (notification N+1 + per-build merge).
5. **Notifications rework (D6):** decide M13 (PowerSync-backed list vs. fix-in-place), then C10/H17/H18/H21 (pagination + single source of truth), H19 (deep-link safety), H22 (permission UX), M14–M20 + L15–L16.
6. **Consistency / polish:** the remaining MEDIUM and LOW tiers.
