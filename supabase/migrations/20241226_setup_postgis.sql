-- Enable PostGIS extension if not already enabled
create extension if not exists postgis;

-- Add geometry column to moment_groups
alter table moment_groups add column if not exists geom geometry(Point, 4326);

-- Create index for spatial queries
create index if not exists moment_groups_geom_idx on moment_groups using gist (geom);

-- Create a trigger to automatically update the geom column when lat/long changes
create or replace function update_moment_group_geom()
returns trigger as $$
begin
  new.geom := ST_SetSRID(ST_MakePoint(new.longitude, new.latitude), 4326);
  return new;
end;
$$ language plpgsql;

create trigger update_moment_group_geom_trigger
before insert or update of latitude, longitude on moment_groups
for each row
execute function update_moment_group_geom();

-- Update existing records
update moment_groups set geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) where geom is null;

-- Create the RPC function for fetching nearby groups
create or replace function get_nearby_moment_groups(lat double precision, lng double precision, radius_meters double precision)
returns setof moment_groups
language sql
stable
as $$
  select *
  from moment_groups
  where ST_DWithin(
    geom,
    ST_SetSRID(ST_MakePoint(lng, lat), 4326),
    radius_meters
  )
  order by ST_Distance(geom, ST_SetSRID(ST_MakePoint(lng, lat), 4326)) asc;
$$;
