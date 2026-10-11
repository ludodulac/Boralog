-- BORALOG-106 schema contract.
do $$
declare
  v_nullable text;
  v_type text;
begin
  select is_nullable, data_type into v_nullable, v_type
  from information_schema.columns
  where table_schema='public' and table_name='events' and column_name='event_date';

  if v_type is distinct from 'date' or v_nullable is distinct from 'NO' then
    raise exception 'events.event_date must be date NOT NULL';
  end if;

  if (select data_type from information_schema.columns where table_schema='public' and table_name='events' and column_name='starts_at') is distinct from 'timestamp with time zone' then
    raise exception 'events.starts_at must remain timestamptz';
  end if;

  if (select is_nullable from information_schema.columns where table_schema='public' and table_name='events' and column_name='starts_at') is distinct from 'YES' then
    raise exception 'events.starts_at must remain nullable';
  end if;

  if (select data_type from information_schema.columns where table_schema='public' and table_name='events' and column_name='ends_at') is distinct from 'timestamp with time zone' then
    raise exception 'events.ends_at must remain timestamptz';
  end if;

  if (select is_nullable from information_schema.columns where table_schema='public' and table_name='events' and column_name='ends_at') is distinct from 'YES' then
    raise exception 'events.ends_at must remain nullable';
  end if;
end $$;
