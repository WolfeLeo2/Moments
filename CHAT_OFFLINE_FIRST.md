# Chat Offline-First Implementation Plan

## Overview
Transform the current hybrid chat implementation into a true offline-first system with WhatsApp-level persistence.

---

## Priority 1: Critical (Message Reliability) ✅ COMPLETE

### 1.1 Add MessageSendStatus Enum ✅
- [x] Create `MessageSendStatus` enum: `pending`, `sending`, `sent`, `delivered`, `read`, `failed`
- [x] Add `sendStatus` field to `Message` model
- [x] Add `localOnly` boolean for messages created offline

### 1.2 Update Drift Schema ✅
- [x] Add `send_status` column to Messages table
- [x] Add `local_only` column to Messages table
- [x] Add helper methods: `deleteMessage`, `getMessageById`, `updateMessageStatus`, `getPendingMessages`

### 1.3 Implement Optimistic Message Sending ✅
- [x] Save message to Drift immediately with `pending` status
- [x] Show message in UI instantly
- [x] Send to Supabase in background
- [x] Update status to `sent` on success
- [x] Update status to `failed` on error

### 1.4 Create PendingMessageQueue Service ✅
- [x] Queue failed messages for retry (`MessageQueueService`)
- [x] Exponential backoff retry logic (5s, 10s, 20s, 40s, 80s)
- [x] Sync when connectivity restored
- [x] `retryMessage()` for manual retry
- [x] Auto-started in `main.dart`

### 1.5 Add Status Indicators to UI ✅
- [x] Add ✓ (sent) ✓✓ (delivered) indicators to message bubbles
- [x] Show spinning indicator for pending/sending messages
- [x] Show "Tap to retry" for failed messages
- [x] Blue ticks for read messages

---

## Priority 2: Important (Sync Reliability)

### 2.1 Connectivity Detection ⏭️ SKIPPED
User feedback: "A user already knows when they are offline. The pending icon already shows this."
The retry queue handles offline operations - no UI banner needed.

### 2.2 Improve Chat List Sync ✅
- [x] Handle `streamConversationsChanged()` offline errors gracefully
- [x] Error logging with `syncStateProvider` for debugging
- [x] Drift reactive stream continues working even when Supabase fails

### 2.3 Unread Count Sync ✅
- [x] `markConversationAsReadLocally()` - instant local update
- [x] `updateChatListUnreadCount()` - update chat list cache
- [x] `MarkAsReadAction` provider - fire-and-forget server sync
- [x] Queue failed read receipts via `PendingActions` table

### 2.4 Message Deduplication ✅
- [x] `saveMessagesWithMerge()` - smart merge from server
- [x] Preserves local `sendStatus` for pending/sending/failed messages
- [x] Updates to `sent` + `localOnly=false` when server confirms
- [x] Uses `insertAllOnConflictUpdate` for atomic upserts

---

## Priority 3: Enhanced Experience ✅ COMPLETE

### 3.1 Media Queue ✅
- [x] `sendImageOptimistic()` - local preview, background upload
- [x] `sendAudioOptimistic()` - local playback, background upload
- [x] `sendVideoOptimistic()` - local preview, background upload
- [x] `getPendingMediaMessages()` - query for retry queue
- [x] Added `localMediaPath` column to Messages table

### 3.2 Edit/Delete Message Queue ✅
- [x] `editMessageOptimistic()` - instant local update, queue sync
- [x] `deleteForSelfOptimistic()` - instant local hide, queue sync
- [x] `deleteForEveryoneOptimistic()` - instant local delete, queue sync
- [x] Uses `PendingActions` table for retry on failure

### 3.3 Reaction Queue ✅
- [x] `addReactionOptimistic()` - instant local update, queue sync
- [x] `removeReactionOptimistic()` - instant local remove, queue sync
- [x] `updateMessageReactions()` database method

### 3.4 Delivery Receipts ✅ COMPLETE
- [x] Added `delivered_at` column to messages table (Supabase)
- [x] Created `mark_messages_delivered()` RPC function (Supabase)
- [x] Added `deliveredAt` field to Message model
- [x] Added `deliveredAt` column to local Drift database
- [x] Added `markMessagesDelivered()` to ChatRepository
- [x] UI supports `MessageSendStatus.delivered` with double tick

---

## Unified ChatOfflineService ✅

Replaced duplicate `MessageQueueService` with comprehensive `ChatOfflineService`:

**Location:** `lib/core/services/chat_offline_service.dart`

**Methods:**
- `sendTextOptimistic()` - Text messages with retry
- `sendImageOptimistic()` - Image messages with local preview
- `sendAudioOptimistic()` - Audio messages with local playback
- `sendVideoOptimistic()` - Video messages with local preview
- `editMessageOptimistic()` - Edit with instant local update
- `deleteForSelfOptimistic()` - Delete for self with instant hide
- `deleteForEveryoneOptimistic()` - Delete for all with instant removal
- `addReactionOptimistic()` - Reactions with instant UI
- `removeReactionOptimistic()` - Remove reactions with instant UI
- `retryMessage()` - Manual retry for failed messages
- `syncNow()` - Force immediate queue processing
- `getPendingCount()` - Get count of all pending operations

**Queue Processing:**
- Exponential backoff: 5s, 10s, 20s, 40s, 80s
- Handles text messages, media uploads, edits, deletes, reactions
- Uses `PendingActions` table for non-message operations

---

## Implementation Status

| Item | Status | Date |
|------|--------|------|
| 1.1 MessageSendStatus Enum | ✅ Complete | Feb 5, 2026 |
| 1.2 Drift Schema Update | ✅ Complete | Feb 5, 2026 |
| 1.3 Optimistic Sending | ✅ Complete | Feb 5, 2026 |
| 1.4 PendingMessageQueue | ✅ Complete | Feb 5, 2026 |
| 1.5 Status Indicators UI | ✅ Complete | Feb 5, 2026 |
| 2.1 Connectivity Banner | ⏭️ Skipped | Feb 5, 2026 |
| 2.2 Chat List Sync | ✅ Complete | Feb 5, 2026 |
| 2.3 Unread Count Sync | ✅ Complete | Feb 5, 2026 |
| 2.4 Message Deduplication | ✅ Complete | Feb 5, 2026 |
| 3.1 Media Queue | ✅ Complete | Feb 5, 2026 |
| 3.2 Edit/Delete Queue | ✅ Complete | Feb 5, 2026 |
| 3.3 Reaction Queue | ✅ Complete | Feb 5, 2026 |
| 3.4 Delivery Receipts | ✅ Complete | Feb 5, 2026 |

---

## Architecture Notes

### Message Flow (After Implementation)

```
User taps Send
    │
    ▼
┌─────────────────────────────┐
│ 1. ChatOfflineService       │
│    - Generate local UUID    │
│    - status = pending       │
│    - localOnly = true       │
└─────────────────────────────┘
    │
    ▼
┌─────────────────────────────┐
│ 2. Save to Drift (instant)  │
│    - Message appears in UI  │
│    - Shows "Sending..." icon│
└─────────────────────────────┘
    │
    ▼
┌─────────────────────────────┐
│ 3. Send to Supabase (async) │
│    - status = sending       │
└─────────────────────────────┘
    │
    ├── Success ──────────────────┐
    │                             ▼
    │                   ┌─────────────────────┐
    │                   │ 4a. Update Drift    │
    │                   │     - status = sent │
    │                   │     - localOnly = false │
    │                   │     - Shows ✓       │
    │                   └─────────────────────┘
    │
    └── Failure ──────────────────┐
                                  ▼
                        ┌─────────────────────┐
                        │ 4b. Update Drift    │
                        │     - status = failed │
                        │     - Auto-retry queue│
                        │     - Shows ⚠️ Retry │
                        └─────────────────────┘
```

### Files Modified

**Core Services:**
- ✅ `lib/core/services/chat_offline_service.dart` - Unified offline service (NEW)
- ❌ `lib/core/services/message_queue_service.dart` - DELETED (replaced)

**Database:**
- ✅ `lib/core/database/database.dart` - Added columns and methods

**Providers:**
- ✅ `lib/features/chat/providers/chat_providers.dart` - Smart merge, offline markAsRead

**UI:**
- ✅ `lib/features/chat/presentation/chat_page.dart` - All ops use ChatOfflineService
- ✅ `lib/features/chat/widgets/message_bubble.dart` - Status icons + retry

**Startup:**
- ✅ `lib/main.dart` - Starts ChatOfflineService
