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
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRobGp0a2p0Z2NiZXhxeXJsdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg1MzMwNjUsImV4cCI6MjEwNDEwOTA2NX0.CR2iR96Iz4-FrRyl67u8TeXqmySJWDEz0hsEymNMHsg";

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
