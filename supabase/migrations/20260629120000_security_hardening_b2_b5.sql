-- Security & correctness hardening (code_review.md B2–B5)
-- B2: anon must not EXECUTE SECURITY DEFINER RPCs
-- B3: pin search_path on flagged functions
-- B4: PostGIS degrees→meters bug in get_nearby_moment_groups
-- B5: profiles SELECT exposes phone PII to everyone
-- B1 (missing increment_story_view_count) intentionally NOT included — feature undecided.

begin;

-- ─────────────────────────────────────────────────────────────────────────────
-- B2 — Revoke EXECUTE from anon/public on every SECURITY DEFINER function in
-- public; grant only to authenticated (skip trigger functions — clients can't
-- call them and revoking EXECUTE does not affect trigger firing).
-- ─────────────────────────────────────────────────────────────────────────────
do $$
declare
  fn record;
begin
  for fn in
    select p.oid::regprocedure as sig, (p.prorettype = 'pg_catalog.trigger'::regtype) as is_trigger
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef                                   -- SECURITY DEFINER only
      and not exists (                                  -- skip extension-owned (postgis etc.)
        select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e'
      )
  loop
    execute format('revoke execute on function %s from anon, public;', fn.sig);
    if not fn.is_trigger then
      execute format('grant execute on function %s to authenticated;', fn.sig);
    end if;
  end loop;
end $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- B3 — Pin search_path on the functions the advisor flagged as mutable.
-- `public` is safe here: PostGIS lives in public, and bodies reference
-- public tables. (A stricter `''` + fully-qualified bodies is the long-term goal.)
-- ─────────────────────────────────────────────────────────────────────────────
alter function public.find_nearby_users(double precision, double precision, double precision) set search_path = public;
alter function public.get_recent_conversations() set search_path = public;
alter function public.get_or_create_conversation(uuid) set search_path = public;
alter function public.get_conversation_with_friend(uuid) set search_path = public;
alter function public.mark_messages_delivered(uuid) set search_path = public;
alter function public.search_profiles(text) set search_path = public;
alter function public.search_curated_tracks(text, text, text, integer, integer) set search_path = public;
alter function public.get_story_viewers(uuid) set search_path = public;
alter function public.get_friends_stories(uuid) set search_path = public;
alter function public.handle_new_moment_contributor() set search_path = public;
-- The 6-arg create_moment_batch overload (the INVOKER one with p_group_private):
alter function public.create_moment_batch(jsonb[], uuid, text, double precision, double precision, boolean) set search_path = public;

-- ─────────────────────────────────────────────────────────────────────────────
-- B4 — get_nearby_moment_groups measured distance in DEGREES (geometry column),
-- so radius_meters was treated as ~degrees (100 ≈ whole planet). Cast to
-- geography so ST_DWithin / ST_Distance use meters, matching find_nearby_users.
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.get_nearby_moment_groups(
  lat double precision, lng double precision, radius_meters double precision
)
returns setof moment_groups
language sql
stable
set search_path = public
as $function$
  select *
  from moment_groups
  where ST_DWithin(
    geom::geography,
    ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
    radius_meters
  )
  order by ST_Distance(
    geom::geography,
    ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
  ) asc;
$function$;

-- ─────────────────────────────────────────────────────────────────────────────
-- B5 — profiles SELECT was `USING (true)` → anon could read every row including
-- phone_number / phone_hash. Restrict reads to authenticated, and block direct
-- column reads of the phone fields for clients entirely (the DEFINER
-- find_profiles_by_phone RPC still works as it runs as owner).
-- ─────────────────────────────────────────────────────────────────────────────
drop policy if exists "Anyone can view profiles" on public.profiles;

create policy "Authenticated can view profiles"
  on public.profiles
  for select
  to authenticated
  using (true);

-- Column-level: clients cannot SELECT the phone fields directly.
revoke select (phone_number, phone_hash) on public.profiles from anon, authenticated;
-- NOTE: find_profiles_by_phone returns SETOF profiles, so it still echoes phone
-- columns back to callers. Narrow it to return only safe columns (id, username,
-- display_name, avatar_url) in a follow-up — column grants don't cover function
-- return values.

-- NOTE: if any pre-auth flow needs to read a profile (e.g. invite-code or
-- username lookup during signup), move that to a SECURITY DEFINER RPC that
-- returns only non-sensitive columns — do NOT re-open anon table reads.

commit;
