-- Ensure the bucket exists (idempotent)
insert into storage.buckets (id, name, public)
values ('chat_attachments', 'chat_attachments', true)
on conflict (id) do nothing;

-- Policy to allow authenticated users to upload files
create policy "Authenticated users can upload chat attachments"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'chat_attachments' );

-- Policy to allow everyone to view files (since it's a public bucket)
create policy "Everyone can view chat attachments"
on storage.objects for select
to public
using ( bucket_id = 'chat_attachments' );
