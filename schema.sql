-- Recordly database setup. Paste all of this into Supabase > SQL Editor > Run.
create extension if not exists pgcrypto;

create table records(
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users on delete cascade,
  title text not null, target numeric, end_date date,
  show_table boolean not null default false, group_link boolean not null default false,
  created_at timestamptz not null default now());
create table people(
  id uuid primary key default gen_random_uuid(),
  record_id uuid not null references records on delete cascade,
  name text not null, phone text, user_id uuid references auth.users on delete set null,
  created_at timestamptz not null default now());
create table payments(
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references people on delete cascade,
  amount numeric not null check (amount > 0), paid_on date not null default current_date,
  note text, created_at timestamptz not null default now());
create table comments(
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references people on delete cascade,
  author_id uuid not null references auth.users on delete cascade,
  author_name text, body text not null, created_at timestamptz not null default now());

alter table records enable row level security;
alter table people enable row level security;
alter table payments enable row level security;
alter table comments enable row level security;  -- no policies: only the functions below can touch comments

create policy rec_owner on records for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy ppl_owner on people for all
  using (exists (select 1 from records r where r.id = record_id and r.owner_id = auth.uid()))
  with check (exists (select 1 from records r where r.id = record_id and r.owner_id = auth.uid()));
create policy pay_owner on payments for all
  using (exists (select 1 from people p join records r on r.id = p.record_id where p.id = person_id and r.owner_id = auth.uid()))
  with check (exists (select 1 from people p join records r on r.id = p.record_id where p.id = person_id and r.owner_id = auth.uid()));
create policy ppl_self on people for select using (user_id = auth.uid());
create policy pay_self on payments for select
  using (exists (select 1 from people p where p.id = person_id and p.user_id = auth.uid()));

-- What a link visitor may see. Payment notes and comments only for the owner or the claimed account holder.
create or replace function get_person_view(pid uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare p people; r records; me boolean; res jsonb;
begin
  select * into p from people where id = pid;
  if not found then return null; end if;
  select * into r from records where id = p.record_id;
  me := auth.uid() is not null and (p.user_id = auth.uid() or r.owner_id = auth.uid());
  res := jsonb_build_object('name', p.name, 'title', r.title, 'target', r.target,
    'show_table', r.show_table, 'claimed', p.user_id is not null, 'me', me,
    'payments', coalesce((select jsonb_agg(jsonb_build_object('amount', amount, 'paid_on', paid_on,
        'note', case when me then note end) order by paid_on desc, created_at desc)
        from payments where person_id = pid), '[]'::jsonb),
    'comments', case when me then coalesce((select jsonb_agg(jsonb_build_object('who', author_name,
        'body', body, 'at', created_at) order by created_at) from comments where person_id = pid), '[]'::jsonb)
        else '[]'::jsonb end);
  if r.show_table then
    res := res || jsonb_build_object('table', (select coalesce(jsonb_agg(to_jsonb(t) order by t.paid desc), '[]'::jsonb)
      from (select pe.id, pe.name, coalesce(sum(pa.amount), 0) as paid from people pe
            left join payments pa on pa.person_id = pe.id where pe.record_id = r.id group by pe.id, pe.name) t));
  end if;
  return res;
end $$;

create or replace function get_group_people(rid uuid) returns jsonb
language sql security definer set search_path = public as $$
  select case when r.group_link then jsonb_build_object('title', r.title,
    'people', (select coalesce(jsonb_agg(jsonb_build_object('id', p.id, 'name', p.name) order by p.name), '[]'::jsonb)
               from people p where p.record_id = r.id)) end
  from records r where r.id = rid $$;

create or replace function claim_person(pid uuid) returns boolean
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then return false; end if;
  update people set user_id = auth.uid() where id = pid and user_id is null;
  return found;
end $$;

create or replace function add_comment(pid uuid, msg text, who text) returns void
language plpgsql security definer set search_path = public as $$
declare ok boolean;
begin
  select exists (select 1 from people p join records r on r.id = p.record_id
    where p.id = pid and (p.user_id = auth.uid() or r.owner_id = auth.uid())) into ok;
  if auth.uid() is null or not ok or coalesce(trim(msg), '') = '' then raise exception 'Not allowed'; end if;
  insert into comments(person_id, author_id, author_name, body) values (pid, auth.uid(), left(who, 60), left(msg, 500));
end $$;

grant execute on function get_person_view(uuid), get_group_people(uuid) to anon, authenticated;
grant execute on function claim_person(uuid), add_comment(uuid, text, text) to authenticated;
alter publication supabase_realtime add table payments;
