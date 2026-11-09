-- Пульт объекта — схема БД
-- Выполни в Supabase SQL Editor

create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  full_name text,
  company_name text,
  role text check (role in ('owner', 'foreman', 'customer')) default 'owner',
  organization_id uuid,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid references auth.users not null,
  created_at timestamptz default now()
);

alter table public.profiles
  drop constraint if exists profiles_organization_id_fkey;
alter table public.profiles
  add constraint profiles_organization_id_fkey
  foreign key (organization_id) references public.organizations(id);

create table if not exists public.objects (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations not null,
  title text not null,
  address text,
  customer_name text,
  customer_phone text,
  customer_email text,
  customer_user_id uuid references auth.users,
  access_token text unique default encode(gen_random_bytes(16), 'hex'),
  status text check (status in ('active', 'paused', 'done')) default 'active',
  budget_plan numeric(12,2) default 0,
  budget_paid numeric(12,2) default 0,
  next_payment_date date,
  next_payment_amount numeric(12,2),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.stages (
  id uuid primary key default gen_random_uuid(),
  object_id uuid references public.objects on delete cascade not null,
  title text not null,
  sort_order int default 0,
  progress_percent int default 0 check (progress_percent >= 0 and progress_percent <= 100),
  is_current boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.photos (
  id uuid primary key default gen_random_uuid(),
  object_id uuid references public.objects on delete cascade not null,
  stage_id uuid references public.stages,
  path text not null,
  caption text,
  uploaded_by uuid references auth.users,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.objects enable row level security;
alter table public.stages enable row level security;
alter table public.photos enable row level security;

create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "Owners manage organizations" on public.organizations for all using (auth.uid() = owner_id);
create policy "Org members manage objects" on public.objects for all using (
  organization_id in (select id from public.organizations where owner_id = auth.uid())
);
create policy "Customers view own objects" on public.objects for select using (customer_user_id = auth.uid());

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, company_name, role)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'company_name',
    new.raw_user_meta_data->>'company_name',
    coalesce(new.raw_user_meta_data->>'role', 'owner')
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Storage: создай bucket "photos" (private) в UI Supabase
