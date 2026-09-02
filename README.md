# Radio Web

Sitio de radio en vivo con panel de administración (CRUD), construido con
HTML/CSS/JS plano + Supabase (base de datos y autenticación) y desplegado
en Vercel.

## Estructura

```
radio-web/
├── index.html          # Página pública
├── login.html           # Login del panel admin
├── admin.html           # Panel de administración (protegido)
├── vercel.json           # Config de despliegue
├── assets/
│   ├── style.css         # Estilos del sitio
│   └── config.js         # Credenciales de Supabase (URL + anon key)
└── supabase/
    └── schema.sql         # Tabla + políticas de seguridad (RLS)
```

## 1. Crear el proyecto en Supabase

1. Andá a [supabase.com](https://supabase.com) y creá un proyecto nuevo.
2. Entrá a **SQL Editor > New query**, pegá el contenido completo de
   `supabase/schema.sql` y ejecutalo. Esto crea:
   - la tabla `configuracion` (con una única fila, `id = 1`),
   - un trigger que actualiza `updated_at` en cada cambio,
   - las políticas de RLS: **lectura pública** (la página lo necesita
     para mostrar los datos sin login) y **escritura solo para usuarios
     autenticados** (nadie puede editar sin haber iniciado sesión, ni
     siquiera con la anon key).

## 2. Crear tu usuario administrador

El panel de admin usa **Supabase Auth**, no una contraseña fija en el
código. Para crear el usuario que vas a usar para entrar:

1. En el dashboard de Supabase: **Authentication > Users > Add user**.
2. Cargá tu email y una contraseña. Marcá "Auto confirm user" para no
   depender del email de verificación.
3. Ese email/contraseña son los que vas a usar en `login.html`.

> Podés crear más de un usuario si varias personas van a administrar
> el sitio. Para dar de baja un acceso, simplemente borrá el usuario
> desde el mismo panel.

## 3. Completar las credenciales

Abrí `assets/config.js` y reemplazá:

```js
const SUPABASE_URL = "TU_SUPABASE_URL";
const SUPABASE_ANON_KEY = "TU_SUPABASE_ANON_KEY";
```

con los valores de **Project Settings > API** de tu proyecto de
Supabase (`Project URL` y `anon public` key). Es un solo archivo:
las tres páginas (`index.html`, `login.html`, `admin.html`) lo
comparten.

## 4. Probar en local

Como todo es estático, alcanza con abrir `index.html` en el navegador,
o servirlo con cualquier servidor simple, por ejemplo:

```bash
npx serve .
```

Para probar el panel: entrá a `login.html`, iniciá sesión con el
usuario que creaste en el paso 2, y vas a caer en `admin.html`.

## 5. Desplegar en Vercel

1. Subí la carpeta completa a un repositorio de GitHub.
2. En [vercel.com](https://vercel.com), **Add New… > Project** e
   importá el repositorio.
3. Dejá la configuración por defecto (sitio estático, sin build
   command) y hacé **Deploy**.
4. Listo: Vercel te da una URL pública. La página principal queda en
   `/`, el login del admin en `/login` y el panel en `/admin`.

## Notas de seguridad

- La **anon key** de Supabase es pública por diseño (va en el
  navegador de cualquier visitante); la protección real está en las
  políticas RLS de `schema.sql`, no en ocultar esa key.
- El panel admin **no es accesible sin iniciar sesión**: `admin.html`
  verifica la sesión de Supabase Auth al cargar y redirige a
  `login.html` si no existe.
- El texto que se guarda en la base (novedades, etc.) se muestra en
  `index.html` escapado como texto plano, para que nadie pueda
  inyectar HTML/JS a través del panel.
- Si en algún momento agregás más campos o tablas, recordá habilitar
  RLS y escribir sus políticas — por defecto Supabase bloquea todo
  acceso a una tabla sin política explícita.

## Ideas para seguir

- Reemplazar el bloque `console__inner` de `index.html` por el embed
  real del vivo de TikTok o el reproductor de streaming que uses.
- Agregar un campo `activo` (boolean) a cada novedad para poder
  ocultarla sin borrarla.
- Guardar un historial de cambios (tabla `configuracion_historial`)
  si más de una persona va a administrar el sitio.
