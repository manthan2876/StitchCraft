import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const isTest = process.env.NODE_ENV === 'test' ||
  process.env.npm_lifecycle_event === 'test' ||
  process.argv.some(arg => arg.includes('test'));

const supabaseUrl = process.env.SUPABASE_URL || (isTest ? 'https://placeholder.supabase.co' : null);
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || (isTest ? 'placeholder-key-for-test-suite' : null);

if (!supabaseUrl || !supabaseKey) {
  throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required');
}

export const supabase = createClient(
  supabaseUrl,
  supabaseKey,
  { auth: { autoRefreshToken: false, persistSession: false } },
);
