-- SSAW Storage RLS policies
-- Run in Supabase SQL editor after creating buckets "avatars" and "block-images" (public).
-- Paths: avatars → avatars/{user_id}/{file.name}; block-images → {user_id}/{noteId}/{file.name}.

-- =============================================================================
-- Bucket: avatars
-- Path in app: avatars/{user_id}/{file.name} → (storage.foldername(name))[2] = user_id
-- =============================================================================

create policy "Users can upload own avatar"
on storage.objects for insert
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[2] = auth.uid()::text
);

create policy "Users can update own avatar"
on storage.objects for update
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[2] = auth.uid()::text
);

create policy "Users can delete own avatar"
on storage.objects for delete
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[2] = auth.uid()::text
);

-- Public read is handled by making the bucket public; no select policy needed for public buckets.

-- =============================================================================
-- Bucket: block-images
-- Path in app: {user_id}/{noteId}/{file.name} → (storage.foldername(name))[1] = user_id
-- =============================================================================

create policy "Users can upload own block images"
on storage.objects for insert
with check (
  bucket_id = 'block-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can read their own block images
create policy "Users can read own block images"
on storage.objects for select
using (
  bucket_id = 'block-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can read partner's block images when mutually matched
create policy "Users can read partner block images"
on storage.objects for select
using (
  bucket_id = 'block-images'
  and exists (
    select 1 from public.profiles me, public.profiles other
    where me.id = auth.uid()
      and other.id::text = (storage.foldername(name))[1]
      and me.partner_email = other.email
      and other.partner_email = me.email
  )
);
