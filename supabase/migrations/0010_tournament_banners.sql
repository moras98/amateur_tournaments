-- Optional organizer-uploaded tournament banner (image).
-- Path into the public `tournament-banners` bucket; NULL = no banner and
-- the app falls back to its sport-icon look.

alter table public.tournaments
  add column if not exists banner_path text;

-- Public read: banners advertise public events and are served through the
-- bucket's public URL. Writes are restricted by the policies below, which
-- check the uploader owns the tournament whose id is the object's folder.
insert into storage.buckets (id, name, public)
values ('tournament-banners', 'tournament-banners', true)
on conflict (id) do nothing;

create policy "Tournament banners are publicly readable"
  on storage.objects for select
  using (bucket_id = 'tournament-banners');

create policy "Owners upload tournament banners"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'tournament-banners'
    and exists (
      select 1
      from public.tournaments t
      where t.id::text = (storage.foldername(name))[1]
        and t.owner_id = (select auth.uid())
    )
  );

-- Deleting an object (a replaced banner, or the banner of a tournament
-- about to be removed) is allowed while the owning row still exists — the
-- app removes the object before deleting the row.
create policy "Owners delete tournament banners"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'tournament-banners'
    and exists (
      select 1
      from public.tournaments t
      where t.id::text = (storage.foldername(name))[1]
        and t.owner_id = (select auth.uid())
    )
  );
