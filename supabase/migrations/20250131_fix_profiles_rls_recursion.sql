-- Fix infinite recursion in "Users can read partner profile" policy.
-- The policy was selecting from profiles inside a profiles policy, causing 42P17.
-- Run this in Supabase SQL editor if you already applied the old schema.

create or replace function public.are_mutual_partners(my_id uuid, other_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles me, public.profiles other
    where me.id = my_id and other.id = other_id
      and me.partner_email = other.email and other.partner_email = me.email
  );
$$;

drop policy if exists "Users can read partner profile" on public.profiles;
create policy "Users can read partner profile" on public.profiles for select
  using (public.are_mutual_partners(auth.uid(), id));
