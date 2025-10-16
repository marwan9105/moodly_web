import { ref, computed } from 'vue';
import { supabase, type Profile } from '../lib/supabase';
import type { User } from '@supabase/supabase-js';

const user = ref<User | null>(null);
const profile = ref<Profile | null>(null);
const loading = ref(true);

export function useAuth() {
  const isAuthenticated = computed(() => !!user.value);
  const isAdmin = computed(() => profile.value?.role === 'admin');
  const isManager = computed(() => profile.value?.role === 'manager');
  const isEmployee = computed(() => profile.value?.role === 'employee');

  const loadUser = async () => {
    try {
      loading.value = true;
      const { data: { user: currentUser } } = await supabase.auth.getUser();
      user.value = currentUser;

      if (currentUser) {
        const { data } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', currentUser.id)
          .maybeSingle();

        profile.value = data;
      } else {
        profile.value = null;
      }
    } finally {
      loading.value = false;
    }
  };

  const signIn = async (email: string, password: string) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;

    user.value = data.user;
    await loadUser();
    return data;
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    user.value = null;
    profile.value = null;
  };

  const createUser = async (email: string, password: string, fullName: string, role: 'admin' | 'manager' | 'employee') => {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    });

    if (error) throw error;

    if (data.user) {
      const { error: profileError } = await supabase
        .from('profiles')
        .insert({
          id: data.user.id,
          email,
          full_name: fullName,
          role,
          created_by: user.value?.id,
        });

      if (profileError) throw profileError;
    }

    return data;
  };

  supabase.auth.onAuthStateChange(async (event, session) => {
    user.value = session?.user ?? null;
    if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
      await loadUser();
    } else if (event === 'SIGNED_OUT') {
      profile.value = null;
    }
  });

  return {
    user,
    profile,
    loading,
    isAuthenticated,
    isAdmin,
    isManager,
    isEmployee,
    loadUser,
    signIn,
    signOut,
    createUser,
  };
}
