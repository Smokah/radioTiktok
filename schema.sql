-- =========================================================
-- Radio Web · esquema de base de datos para Supabase
-- =========================================================
-- Ejecutar este script completo en:
-- Supabase Dashboard > SQL Editor > New query

-- 1) Tabla de configuración (registro único, id = 1)
create table if not exists configuracion (
  id int8 primary key default 1,
  nombre_radio text not null default 'Mi Radio',
  usuario_tiktok text not null default '',
  novedades jsonb not null default '[]'::jsonb,
  publicidad_url text,
  updated_at timestamptz not null default now(),
  constraint solo_una_fila check (id = 1)
);

-- Fila inicial (solo se inserta si la tabla está vacía)
insert into configuracion (id, nombre_radio, usuario_tiktok, novedades)
values (1, 'Mi Radio', 'miradio', '[]'::jsonb)
on conflict (id) do nothing;

-- 2) Trigger para mantener updated_at al día en cada UPDATE
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_configuracion_updated_at on configuracion;
create trigger trg_configuracion_updated_at
  before update on configuracion
  for each row
  execute function set_updated_at();

-- 3) Row Level Security (RLS)
-- Sin esto, por defecto Supabase BLOQUEA todo acceso vía la anon key,
-- así que hay que habilitar RLS y crear políticas explícitas.
alter table configuracion enable row level security;

-- Lectura pública: cualquiera (incluso sin login) puede LEER la config.
-- Esto es necesario para que index.html funcione sin autenticación.
drop policy if exists "Lectura publica" on configuracion;
create policy "Lectura publica"
  on configuracion
  for select
  to anon, authenticated
  using (true);

-- Escritura SOLO para usuarios autenticados (el panel admin).
-- La anon key nunca podrá hacer UPDATE gracias a esta política:
-- solo un usuario logueado con Supabase Auth puede modificar datos.
drop policy if exists "Escritura solo autenticados" on configuracion;
create policy "Escritura solo autenticados"
  on configuracion
  for update
  to authenticated
  using (true)
  with check (id = 1);

-- Nota: no se crea política de INSERT ni DELETE a propósito.
-- La fila con id=1 ya existe; nadie (ni el admin) debería poder
-- crear filas nuevas o borrar la única fila de configuración
-- desde el cliente. Si alguna vez necesitás insertar/borrar,
-- hacelo manualmente desde el SQL Editor.
