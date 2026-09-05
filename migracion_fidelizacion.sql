-- =========================================================
-- Migración: funciones de fidelización
-- (estado en vivo, encuestas, sorteos, muro de mensajes)
-- Ejecutar en Supabase > SQL Editor.
-- =========================================================

-- ---------------------------------------------------------
-- 1) Estado real de transmisión
-- ---------------------------------------------------------
alter table configuracion
  add column if not exists en_vivo boolean not null default false;

-- ---------------------------------------------------------
-- 2) Encuestas
-- ---------------------------------------------------------
create table if not exists encuestas (
  id bigserial primary key,
  pregunta text not null,
  -- cada opción: { "id": "op1", "texto": "...", "votos": 0 }
  opciones jsonb not null default '[]'::jsonb,
  activa boolean not null default false,
  created_at timestamptz not null default now()
);

alter table encuestas enable row level security;

drop policy if exists "Lectura publica encuestas" on encuestas;
create policy "Lectura publica encuestas"
  on encuestas for select
  to anon, authenticated
  using (true);

-- Solo el admin puede crear/editar/borrar encuestas directamente.
-- El voto público NO pasa por acá, pasa por la función votar_encuesta().
drop policy if exists "Escritura admin encuestas" on encuestas;
create policy "Escritura admin encuestas"
  on encuestas for all
  to authenticated
  using (true)
  with check (true);

-- Función segura para votar: solo incrementa el contador de UNA
-- opción de UNA encuesta activa. No permite editar pregunta ni texto.
-- security definer = corre con permisos elevados, así que el público
-- puede ejecutarla sin necesitar permiso de UPDATE sobre la tabla.
create or replace function votar_encuesta(p_encuesta_id bigint, p_opcion_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update encuestas
  set opciones = (
    select jsonb_agg(
      case when (opcion->>'id') = p_opcion_id
        then jsonb_set(opcion, '{votos}', to_jsonb(coalesce((opcion->>'votos')::int, 0) + 1))
        else opcion
      end
    )
    from jsonb_array_elements(opciones) as opcion
  )
  where id = p_encuesta_id and activa = true;
end;
$$;

grant execute on function votar_encuesta(bigint, text) to anon, authenticated;

-- ---------------------------------------------------------
-- 3) Sorteos
-- ---------------------------------------------------------
create table if not exists sorteos (
  id bigserial primary key,
  titulo text not null,
  premio text,
  activo boolean not null default false,
  created_at timestamptz not null default now()
);

alter table sorteos enable row level security;

drop policy if exists "Lectura publica sorteos" on sorteos;
create policy "Lectura publica sorteos"
  on sorteos for select
  to anon, authenticated
  using (true);

drop policy if exists "Escritura admin sorteos" on sorteos;
create policy "Escritura admin sorteos"
  on sorteos for all
  to authenticated
  using (true)
  with check (true);

create table if not exists sorteo_participantes (
  id bigserial primary key,
  sorteo_id bigint not null references sorteos(id) on delete cascade,
  nombre text not null check (char_length(nombre) between 1 and 80),
  contacto text not null check (char_length(contacto) between 1 and 120),
  created_at timestamptz not null default now()
);

alter table sorteo_participantes enable row level security;

-- Cualquiera puede anotarse (insertar), pero NADIE puede leer la
-- lista de participantes salvo el admin autenticado: son datos de
-- contacto de otras personas, no deben quedar públicos.
drop policy if exists "Inscripcion publica sorteos" on sorteo_participantes;
create policy "Inscripcion publica sorteos"
  on sorteo_participantes for insert
  to anon, authenticated
  with check (true);

drop policy if exists "Lectura admin participantes" on sorteo_participantes;
create policy "Lectura admin participantes"
  on sorteo_participantes for select
  to authenticated
  using (true);

drop policy if exists "Borrado admin participantes" on sorteo_participantes;
create policy "Borrado admin participantes"
  on sorteo_participantes for delete
  to authenticated
  using (true);

-- ---------------------------------------------------------
-- 4) Muro de mensajes en vivo
-- ---------------------------------------------------------
create table if not exists mensajes_muro (
  id bigserial primary key,
  nombre text not null check (char_length(nombre) between 1 and 60),
  mensaje text not null check (char_length(mensaje) between 1 and 240),
  created_at timestamptz not null default now()
);

alter table mensajes_muro enable row level security;

drop policy if exists "Lectura publica muro" on mensajes_muro;
create policy "Lectura publica muro"
  on mensajes_muro for select
  to anon, authenticated
  using (true);

drop policy if exists "Publicar en muro" on mensajes_muro;
create policy "Publicar en muro"
  on mensajes_muro for insert
  to anon, authenticated
  with check (true);

-- Solo el admin puede borrar mensajes (moderación).
drop policy if exists "Moderacion muro" on mensajes_muro;
create policy "Moderacion muro"
  on mensajes_muro for delete
  to authenticated
  using (true);

-- ---------------------------------------------------------
-- 5) Habilitar Realtime en las tablas que se actualizan en vivo
-- ---------------------------------------------------------
alter publication supabase_realtime add table public.configuracion;
alter publication supabase_realtime add table public.encuestas;
alter publication supabase_realtime add table public.mensajes_muro;
alter publication supabase_realtime add table public.sorteos;
