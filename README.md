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

## Sobre el reproductor de TikTok

TikTok **no ofrece una forma oficial de embeber un LIVE** dentro de un
sitio externo (a diferencia de sus videos publicados, que sí tienen
oEmbed). Por eso el sitio usa **YouTube Live** para el reproductor
embebido, y muestra además un botón a TikTok para quienes prefieran
verlo ahí.

### Cómo conseguir tu ID de canal de YouTube

1. Entrá a tu canal de YouTube desde una compu.
2. **Configuración del canal > Configuración avanzada** (o
   `Personalización del canal > Básica`, según la versión de YouTube
   Studio) — ahí figura el **"ID de canal"**, algo como
   `UCxxxxxxxxxxxxxxxxxxxxxx`.
3. Pegalo en el campo "ID del canal de YouTube" del panel admin.

Ese ID no cambia nunca, así que lo cargás una sola vez: el reproductor
va a mostrar automáticamente cualquier transmisión en vivo que hagas
en ese canal, sin tener que tocar nada de nuevo cada vez que salís al
aire.

### Cómo transmitir a YouTube y TikTok al mismo tiempo (multistream)

Para no perder tu audiencia de TikTok mientras ganás el reproductor
embebido:

1. Instalá [OBS Studio](https://obsproducer.com) (gratis) en la compu
   desde la que vas a transmitir.
2. Activá el plugin de multistream (built-in en versiones recientes de
   OBS, o el plugin gratuito "Multiple RTMP Outputs" en versiones
   viejas).
3. Cargá las claves de transmisión (stream key) de YouTube Live y de
   TikTok LIVE Studio en OBS — cada plataforma te la da en su propio
   panel de "ir en vivo".
4. Al arrancar la transmisión en OBS, sale simultáneamente en los dos
   lugares.

Si no querés usar OBS, también podés transmitir nativamente desde la
app de YouTube (o YouTube Studio) por un lado y desde TikTok por otro,
pero ahí sí tenés que iniciar cada transmisión por separado.

## Funciones de fidelización

Se agregaron cuatro herramientas para mantener a la audiencia conectada
al sitio mientras escucha. Todas requieren correr
`supabase/migracion_fidelizacion.sql` en el SQL Editor de Supabase
antes de usarlas.

### Estado en vivo

El badge "AL AIRE / FUERA DE AIRE" de la página pública ahora refleja
un estado real, cargado desde el checkbox "Estamos en vivo ahora
mismo" en el panel admin. Se actualiza en tiempo real (sin recargar
la página) gracias a Supabase Realtime.

### Encuesta en vivo

Desde el admin se crea una pregunta con sus opciones y se publica:
eso desactiva automáticamente cualquier encuesta anterior y activa la
nueva. En la página pública, cada visitante vota una sola vez (se
recuerda con `localStorage` en su navegador — si borra los datos del
sitio o entra desde otro dispositivo, puede volver a votar; para el
volumen de este proyecto es una limitación aceptable). Los resultados
se actualizan en vivo para todos los que están mirando en ese momento.

El voto pasa por una función de base de datos (`votar_encuesta`) que
solo puede sumar un voto a una opción — nunca puede editar la
pregunta ni las opciones — así que es seguro que cualquiera la use
sin necesitar una cuenta.

### Sorteo

Se crea con título y premio opcional desde el admin, y activa
automáticamente el formulario de inscripción en la página pública
(nombre + usuario de TikTok o teléfono). La lista de participantes
**no es pública** — solo el admin autenticado puede verla, por
privacidad de los datos de contacto. Desde el panel admin, el botón
"Sortear ganador/a" elige uno al azar entre los anotados.

### Muro de mensajes

Cualquiera puede dejar un mensaje corto (nombre + texto, hasta 240
caracteres) que aparece en la página pública en tiempo real para
todos los visitantes. Desde el admin se puede borrar cualquier
mensaje inapropiado. Es un espacio público sin moderación previa
— los mensajes se publican al instante y se moderan después. Si en
el futuro esto recibe mucho tráfico y aparece spam, la mejora
natural es agregar moderación previa (mensajes ocultos hasta que el
admin los aprueba) o un captcha en el formulario.

## Ideas para seguir

- Agregar un campo `activo` (boolean) a cada novedad para poder
  ocultarla sin borrarla.
- Guardar un historial de cambios (tabla `configuracion_historial`)
  si más de una persona va a administrar el sitio.
