# Database Health Check & Fixes Report

## Status: ✅ Resolved

We have successfully audited the database and applied fixes for critical security and performance issues.

### 🛡️ Security Improvements

- **Fixed Mutable Search Paths**: 18 functions were identified as having mutable search paths, which could allow malicious users to execute arbitrary code. All custom functions have been updated to `SET search_path = public`.
- **Remaining Low-Priority Warnings**:
  - `extension_in_public`: Extensions (`postgis`, `cube`, `earthdistance`) are in the `public` schema. This is common but can be improved in future refactors.
  - `rls_disabled_in_public`: `spatial_ref_sys` (PostGIS system table) does not have RLS. This is expected.

### 🚀 Performance Optimizations

- **Optimized RLS Policies**:
  - **Issue**: Policies were calling `auth.uid()` for every row, preventing Postgres from caching the user ID.
  - **Fix**: Wrapped `auth.uid()` in a subquery `(select auth.uid())` across all policies. This allows the query planner to execute it once per query (InitPlan) instead of once per row.
- **Added Missing Indexes**:
  - Added indexes to foreign keys that were missing them:
    - `conversations(created_by)`
    - `notifications(actor_id)`
    - `notifications(user_id)`
    - `user_devices(user_id)`
- **Removed Duplicate Index**:
  - Dropped redundant constraint/index on `moment_contributors` to save storage and write overhead.

### 🔍 Post-Fix Analysis

- **Unused Indexes**: The newly created indexes are currently marked as "unused". This is normal as they haven't been hit by live traffic yet.
- **Policy Overlap**: There is a warning about multiple permissive policies on the `messages` table for `UPDATE`.
  - Policy 1: Users can update their own messages.
  - Policy 2: Users can update messages in conversations they are part of.
  - _Resolution_: We confirmed that Policy 2 is required for the "Mark as Read" feature (updating `is_read`). However, to prevent abuse (editing content), we implemented a **Trigger** (`trg_check_message_update_permission`) that strictly forbids non-senders from modifying any field other than `is_read`.

## Applied Migration

The files `supabase/migrations/20241227_fix_security_performance.sql` and `supabase/migrations/20241227_secure_message_updates.sql` contain all the applied changes.
