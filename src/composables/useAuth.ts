import { ref, computed } from 'vue'
import { supabase, type Profile } from '../lib/supabase'
import type { Session, User } from '@supabase/supabase-js'

/** State partagé (singleton) */
const session = ref<Session | null>(null)
const user = ref<User | null>(null)
const profile = ref<Profile | null>(null)
const loading = ref(true)

/** Garde-fous pour ne pas initialiser plusieurs fois */
let initialized = false
let unsub: { unsubscribe: () => void } | null = null
let readyPromise: Promise<void> | null = null

async function fetchProfile(u: User | null) {
  if (!u) { profile.value = null; return }
  const { data, error } = await supabase
    .from('profiles')
    .select('id,email,full_name,role,created_by,created_at,updated_at')
    .eq('id', u.id)
    .maybeSingle()
  if (error) {
    console.warn('profiles select error:', error)
    profile.value = null
    return
  }
  profile.value = data
}

async function initSessionOnce() {
  loading.value = true
  const { data, error } = await supabase.auth.getSession()
  if (error) console.warn('getSession error:', error)
  session.value = data.session ?? null
  user.value = data.session?.user ?? null
  await fetchProfile(user.value)
  loading.value = false
}

/** Appelle ceci pour démarrer l’auth (une seule fois) */
async function ready() {
  if (initialized) return readyPromise!
  initialized = true
  readyPromise = (async () => {
    await initSessionOnce()
    // souscription unique
    const { data } = supabase.auth.onAuthStateChange((_e, newSession) => {
      session.value = newSession
      user.value = newSession?.user ?? null
      void fetchProfile(user.value)
    })
    unsub = data.subscription
  })()
  return readyPromise
}

async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) throw error
  session.value = data.session ?? null
  user.value = data.user ?? null
  await fetchProfile(user.value)
  return data
}

async function signOut() {
  await supabase.auth.signOut()
  session.value = null
  user.value = null
  profile.value = null
}

async function createUser(
  email: string,
  password: string,
  fullName: string,
  role: 'admin' | 'manager' | 'employee'
) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { full_name: fullName, role, created_by: user.value?.id ?? null },
      emailRedirectTo: window.location.origin,
    },
  })
  if (error) throw error
  return data
}

export function useAuth() {
  const isAuthenticated = computed(() => !!user.value)
  const isAdmin = computed(() => profile.value?.role === 'admin')
  const isManager = computed(() => profile.value?.role === 'manager')
  const isEmployee = computed(() => profile.value?.role === 'employee')

  return {
    // state
    session, user, profile, loading,
    // flags
    isAuthenticated, isAdmin, isManager, isEmployee,
    // actions
    signIn, signOut, createUser,
    // init / util
    ready,
  }
}
