create table if not exists public.app_admins (
  email text primary key check (email = lower(email))
);

create table if not exists public.course_records (
  id text primary key,
  name text not null,
  course_data jsonb not null check (jsonb_typeof(course_data) = 'object'),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null
);

create table if not exists public.course_access (
  email text not null check (email = lower(email)),
  course_id text not null references public.course_records (id) on delete cascade,
  access_level text not null check (access_level in ('view', 'edit')),
  created_at timestamptz not null default now(),
  primary key (email, course_id)
);

create table if not exists public.app_settings (
  id text primary key,
  settings jsonb not null default '{}'::jsonb check (jsonb_typeof(settings) = 'object'),
  updated_at timestamptz not null default now()
);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists course_records_touch_updated_at on public.course_records;
create trigger course_records_touch_updated_at
  before update on public.course_records
  for each row execute function public.touch_updated_at();

drop trigger if exists app_settings_touch_updated_at on public.app_settings;
create trigger app_settings_touch_updated_at
  before update on public.app_settings
  for each row execute function public.touch_updated_at();

revoke all on public.app_admins, public.course_records, public.course_access, public.app_settings from anon;
grant usage on schema public to authenticated;
grant select on public.app_admins to authenticated;
grant select, insert, update, delete on public.course_records to authenticated;
grant select, insert, update, delete on public.course_access to authenticated;
grant select, insert, update, delete on public.app_settings to authenticated;

alter table public.app_admins enable row level security;
alter table public.course_records enable row level security;
alter table public.course_access enable row level security;
alter table public.app_settings enable row level security;

create or replace function public.is_app_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.app_admins
    where email = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

create or replace function public.can_access_course(target_course_id text, needs_edit boolean default false)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_app_admin() or exists (
    select 1
    from public.course_access
    where course_id = target_course_id
      and email = lower(coalesce(auth.jwt() ->> 'email', ''))
      and (not needs_edit or access_level = 'edit')
  );
$$;

revoke all on function public.is_app_admin() from public, anon;
revoke all on function public.can_access_course(text, boolean) from public, anon;
grant execute on function public.is_app_admin() to authenticated;
grant execute on function public.can_access_course(text, boolean) to authenticated;

drop policy if exists "Admins can read administrator list" on public.app_admins;
create policy "Admins can read administrator list"
  on public.app_admins for select to authenticated
  using (public.is_app_admin());

drop policy if exists "Users can read authorized courses" on public.course_records;
create policy "Users can read authorized courses"
  on public.course_records for select to authenticated
  using (public.can_access_course(id));

drop policy if exists "Editors can update authorized courses" on public.course_records;
create policy "Editors can update authorized courses"
  on public.course_records for update to authenticated
  using (public.can_access_course(id, true))
  with check (public.can_access_course(id, true));

drop policy if exists "Admins can insert courses" on public.course_records;
create policy "Admins can insert courses"
  on public.course_records for insert to authenticated
  with check (public.is_app_admin());

drop policy if exists "Admins can delete courses" on public.course_records;
create policy "Admins can delete courses"
  on public.course_records for delete to authenticated
  using (public.is_app_admin());

drop policy if exists "Users can read their course access" on public.course_access;
create policy "Users can read their course access"
  on public.course_access for select to authenticated
  using (email = lower(coalesce(auth.jwt() ->> 'email', '')) or public.is_app_admin());

drop policy if exists "Admins can assign course access" on public.course_access;
create policy "Admins can assign course access"
  on public.course_access for insert to authenticated
  with check (public.is_app_admin());

drop policy if exists "Admins can change course access" on public.course_access;
create policy "Admins can change course access"
  on public.course_access for update to authenticated
  using (public.is_app_admin())
  with check (public.is_app_admin());

drop policy if exists "Admins can revoke course access" on public.course_access;
create policy "Admins can revoke course access"
  on public.course_access for delete to authenticated
  using (public.is_app_admin());

drop policy if exists "Signed-in users can read app settings" on public.app_settings;
create policy "Signed-in users can read app settings"
  on public.app_settings for select to authenticated
  using (auth.uid() is not null);

drop policy if exists "Admins can insert app settings" on public.app_settings;
create policy "Admins can insert app settings"
  on public.app_settings for insert to authenticated
  with check (public.is_app_admin());

drop policy if exists "Admins can update app settings" on public.app_settings;
create policy "Admins can update app settings"
  on public.app_settings for update to authenticated
  using (public.is_app_admin())
  with check (public.is_app_admin());
