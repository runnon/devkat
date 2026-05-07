import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = "https://sbuskyzrwhlqlxxkoozq.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_lv4uG0KNeJVXiqg9jekuVg_7fkXUwgK";

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
});
