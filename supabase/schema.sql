-- SSAW Supabase schema
-- Run in Supabase SQL editor after enabling Google Auth and creating Storage buckets.

-- Profiles (extend auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text unique not null,
  display_name text,
  avatar_url text,
  partner_email text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Trigger: create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'email', new.email),
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Time blocks (start_time/end_time as text "HH:mm" for simplicity)
create table if not exists public.time_blocks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  day date not null,
  start_time text not null,
  end_time text not null,
  created_at timestamptz default now()
);

-- Block notes (1:1 with time_block for simplicity)
create table if not exists public.block_notes (
  id uuid primary key default gen_random_uuid(),
  time_block_id uuid not null references public.time_blocks (id) on delete cascade unique,
  content text,
  created_at timestamptz default now()
);

-- Block note attachments (images)
create table if not exists public.block_note_attachments (
  id uuid primary key default gen_random_uuid(),
  block_note_id uuid not null references public.block_notes (id) on delete cascade,
  file_path text not null,
  created_at timestamptz default now()
);

-- Comments on partner's notes
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  block_note_id uuid not null references public.block_notes (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz default now()
);

-- Helper: check mutual partnership without triggering RLS on profiles (avoids infinite recursion)
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

-- Helper: check if a time_block belongs to a user (bypasses RLS for nested selects)
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

-- RLS
alter table public.profiles enable row level security;
alter table public.time_blocks enable row level security;
alter table public.block_notes enable row level security;
alter table public.block_note_attachments enable row level security;
alter table public.comments enable row level security;

-- Profiles: own row
create policy "Users can read own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can read partner profile" on public.profiles for select
  using (public.are_mutual_partners(auth.uid(), id));

-- Time blocks: own + partner's (when matched)
create policy "Users can crud own time_blocks" on public.time_blocks
  for all using (auth.uid() = user_id);
create policy "Users can read partner time_blocks" on public.time_blocks for select
  using (
    exists (
      select 1 from public.profiles me, public.profiles other
      where me.id = auth.uid() and other.id = time_blocks.user_id
        and me.partner_email = other.email and other.partner_email = me.email
    )
  );

-- Block notes: via time_blocks ownership (using security definer function to avoid RLS recursion)
create policy "Users can crud own block_notes" on public.block_notes for all
  using (public.owns_time_block(time_block_id, auth.uid()))
  with check (public.owns_time_block(time_block_id, auth.uid()));
create policy "Users can read partner block_notes" on public.block_notes for select
  using (
    exists (
      select 1 from public.time_blocks tb
      where tb.id = block_notes.time_block_id
        and public.are_mutual_partners(auth.uid(), tb.user_id)
    )
  );

-- Block note attachments
create policy "Users can crud own attachments" on public.block_note_attachments for all
  using (
    exists (
      select 1 from public.block_notes bn
      join public.time_blocks tb on tb.id = bn.time_block_id
      where bn.id = block_note_attachments.block_note_id and tb.user_id = auth.uid()
    )
  );
create policy "Users can read partner attachments" on public.block_note_attachments for select
  using (
    exists (
      select 1 from public.block_notes bn
      join public.time_blocks tb on tb.id = bn.time_block_id
      join public.profiles me on me.id = auth.uid()
      join public.profiles other on other.id = tb.user_id
      where bn.id = block_note_attachments.block_note_id and me.partner_email = other.email and other.partner_email = me.email
    )
  );

-- Comments: insert own, read on partner notes
create policy "Users can insert comments" on public.comments for insert with check (auth.uid() = user_id);
create policy "Users can read comments on own or partner notes" on public.comments for select
  using (
    auth.uid() = user_id
    or exists (
      select 1 from public.block_notes bn
      join public.time_blocks tb on tb.id = bn.time_block_id
      where bn.id = comments.block_note_id and tb.user_id = auth.uid()
    )
    or exists (
      select 1 from public.block_notes bn
      join public.time_blocks tb on tb.id = bn.time_block_id
      join public.profiles me on me.id = auth.uid()
      join public.profiles other on other.id = tb.user_id
      where bn.id = comments.block_note_id and me.partner_email = other.email and other.partner_email = me.email
    )
  );
