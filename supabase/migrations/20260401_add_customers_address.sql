-- Add optional address column for patient profile editing.
-- Safe to run multiple times.

alter table public.customers
add column if not exists address text;

comment on column public.customers.address is 'Patient street/area address (optional)';

-- Keep parity with existing gender check style: non-empty when present.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'customers_address_check'
  ) then
    alter table public.customers
      add constraint customers_address_check
      check (
        address is null
        or length(trim(both from address)) > 0
      );
  end if;
end $$;

-- Optional backfill: if address was stored in auth metadata fallback, hydrate customers.address.
update public.customers c
set address = nullif(trim(both from u.raw_user_meta_data ->> 'address'), '')
from auth.users u
where c.id = u.id
  and (c.address is null or trim(both from c.address) = '')
  and u.raw_user_meta_data ? 'address'
  and nullif(trim(both from u.raw_user_meta_data ->> 'address'), '') is not null;

