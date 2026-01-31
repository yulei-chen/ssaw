-- Fix block_notes RLS to avoid issues with nested selects and RLS recursion
-- Create a security definer function to check ownership without triggering time_blocks RLS

-- Helper function to check if a time_block belongs to a user (bypasses RLS)
create or replace function public.owns_time_block(block_id uuid, check_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.time_blocks
    where id = block_id and user_id = check_user_id
  );
$$;

-- Drop and recreate block_notes policies to use the helper function
drop policy if exists "Users can crud own block_notes" on public.block_notes;
drop policy if exists "Users can read partner block_notes" on public.block_notes;

-- Policy for own block_notes (CRUD)
create policy "Users can crud own block_notes" on public.block_notes
  for all
  using (public.owns_time_block(time_block_id, auth.uid()))
  with check (public.owns_time_block(time_block_id, auth.uid()));

-- Policy for reading partner's block_notes
create policy "Users can read partner block_notes" on public.block_notes for select
  using (
    exists (
      select 1 from public.time_blocks tb
      where tb.id = block_notes.time_block_id
        and public.are_mutual_partners(auth.uid(), tb.user_id)
    )
  );
