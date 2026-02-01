-- Time travel feature: UTC storage for time blocks, timezone on profiles
-- Existing blocks: assume stored times were in UTC for migration

-- Profiles: add timezone (IANA string)
alter table public.profiles add column if not exists timezone text;

-- Time blocks: add new columns, migrate data, drop old columns
alter table public.time_blocks add column if not exists start_at timestamptz;
alter table public.time_blocks add column if not exists end_at timestamptz;

-- Migrate existing rows: interpret day + start_time/end_time as UTC
update public.time_blocks
set
  start_at = ((day::text || ' ' || start_time || ':00')::timestamp) at time zone 'UTC',
  end_at = ((day::text || ' ' || end_time || ':00')::timestamp) at time zone 'UTC'
where start_at is null and start_time is not null and end_time is not null;

-- Handle end_time that might be next day (e.g. 23:30 to 00:30)
update public.time_blocks
set end_at = start_at + (
  (24 * 60
    - (split_part(start_time, ':', 1)::int * 60 + coalesce(nullif(split_part(start_time, ':', 2), '')::int, 0))
    + (split_part(end_time, ':', 1)::int * 60 + coalesce(nullif(split_part(end_time, ':', 2), '')::int, 0))
  ) || ' minutes'
)::interval
where end_at < start_at and start_time is not null;

-- Drop old columns and add constraints
alter table public.time_blocks drop column if exists start_time;
alter table public.time_blocks drop column if exists end_time;
alter table public.time_blocks drop column if exists day;

alter table public.time_blocks alter column start_at set not null;
alter table public.time_blocks alter column end_at set not null;
