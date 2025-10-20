import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL!
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
})

export interface Profile {
  id: string
  email: string | null
  full_name: string | null
  role: 'admin' | 'manager' | 'employee' | 'user' | null
  created_by?: string | null
  created_at?: string
  updated_at?: string
}

export interface MoodEntry {
  id: string
  user_id: string
  mood_level: number
  notes: string | null
  created_at: string
}

export interface AnonymousComment {
  id: string
  comment: string
  created_at: string
}
