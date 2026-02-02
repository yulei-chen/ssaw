-- Add status column to block_notes (todo | done)
alter table public.block_notes
  add column if not exists status text not null default 'done'
  check (status in ('todo', 'done'));
