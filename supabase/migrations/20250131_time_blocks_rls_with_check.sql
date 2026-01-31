-- Fix RLS for time_blocks INSERT: add explicit WITH CHECK so new rows are allowed when user_id = auth.uid().
-- JWT uses auth.uid() from the request; the app must send user_id = current user's id (from claims.sub).

drop policy if exists "Users can crud own time_blocks" on public.time_blocks;
create policy "Users can crud own time_blocks" on public.time_blocks
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
