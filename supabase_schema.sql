-- شغّل هذا الملف مرة واحدة في Supabase > SQL Editor

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  title text not null check (char_length(title) between 3 and 80),
  description text not null default '' check (char_length(description) <= 1000),
  price numeric check (price is null or price >= 0),
  category text not null default 'أخرى',
  city text not null default '',
  image_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  content text not null check (char_length(content) between 1 and 1000),
  created_at timestamptz not null default now()
);

alter table public.listings enable row level security;
alter table public.messages enable row level security;

create policy "listings_read" on public.listings
  for select to authenticated using (true);
create policy "listings_insert" on public.listings
  for insert to authenticated with check (auth.uid() = user_id);
create policy "listings_update" on public.listings
  for update to authenticated using (auth.uid() = user_id);
create policy "listings_delete" on public.listings
  for delete to authenticated using (auth.uid() = user_id);

create policy "messages_read" on public.messages
  for select to authenticated using (true);
create policy "messages_insert" on public.messages
  for insert to authenticated with check (auth.uid() = sender_id);

-- Storage
insert into storage.buckets (id, name, public)
values ('listings', 'listings', true)
on conflict (id) do nothing;

create policy "listing_images_read" on storage.objects
  for select using (bucket_id = 'listings');
create policy "listing_images_insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'listings' and (storage.foldername(name))[1] = auth.uid()::text);

-- Realtime للرسائل
alter publication supabase_realtime add table public.messages;
