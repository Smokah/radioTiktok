// =========================================================
// Configuración de Supabase
// =========================================================
// Completá estos dos valores con los de tu proyecto:
// Supabase Dashboard > Project Settings > API
//
// SUPABASE_URL     -> "Project URL"
// SUPABASE_ANON_KEY -> "anon public" key
//
// La "anon key" está pensada para exponerse en el frontend:
// no es secreta. La seguridad real la dan las políticas RLS
// definidas en supabase/schema.sql (lectura pública, escritura
// solo para usuarios autenticados).
// =========================================================

const SUPABASE_URL = "TU_SUPABASE_URL";
const SUPABASE_ANON_KEY = "TU_SUPABASE_ANON_KEY";

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
