-- MedCheck database schema (matches the deployed Supabase project)
create extension if not exists pgcrypto;

create table if not exists public.medcheck_doctors (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.medcheck_doctors enable row level security;
revoke all on public.medcheck_doctors from anon, authenticated;

create table if not exists public.medical_questionnaires (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  fio text not null check (char_length(fio) between 3 and 200),
  birthdate date not null,
  course smallint not null check (course between 1 and 8),
  faculty text not null check (char_length(faculty) between 1 and 200),
  student_group text not null check (char_length(student_group) between 1 and 100),
  height_cm numeric check (height_cm is null or height_cm between 100 and 250),
  weight_kg numeric check (weight_kg is null or weight_kg between 25 and 300),
  waist_cm numeric check (waist_cm is null or waist_cm between 40 and 250),
  metrics_unknown boolean not null default false,
  conditions text[] not null default '{}',
  condition_other text,
  pe_group text not null,
  reviewed boolean not null default false,
  reviewed_at timestamptz,
  doctor_note text
);

alter table public.medical_questionnaires enable row level security;
revoke all on public.medical_questionnaires from anon, authenticated;
grant insert on public.medical_questionnaires to anon, authenticated;
grant select, update on public.medical_questionnaires to authenticated;

drop policy if exists "public_submit_questionnaire" on public.medical_questionnaires;
create policy "public_submit_questionnaire"
on public.medical_questionnaires
for insert
to anon, authenticated
with check (reviewed = false and reviewed_at is null and doctor_note is null);

drop policy if exists "doctors_read_questionnaires" on public.medical_questionnaires;
create policy "doctors_read_questionnaires"
on public.medical_questionnaires
for select
to authenticated
using (exists (select 1 from public.medcheck_doctors d where d.user_id = (select auth.uid())));

drop policy if exists "doctors_update_questionnaires" on public.medical_questionnaires;
create policy "doctors_update_questionnaires"
on public.medical_questionnaires
for update
to authenticated
using (exists (select 1 from public.medcheck_doctors d where d.user_id = (select auth.uid())))
with check (exists (select 1 from public.medcheck_doctors d where d.user_id = (select auth.uid())));

create index if not exists med_q_created_at_idx on public.medical_questionnaires (created_at desc);
create index if not exists med_q_group_idx on public.medical_questionnaires (student_group);
create index if not exists med_q_course_idx on public.medical_questionnaires (course);
create index if not exists med_q_fio_idx on public.medical_questionnaires (fio);
