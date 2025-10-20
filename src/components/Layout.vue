<template>
  <div class="layout">
    <header class="header">
      <div class="header-content">
        <div class="header-left">
          <img src="/logo_Moodly.png" alt="Moodly" class="header-logo" />
          <span class="header-title">{{ title }}</span>
        </div>
        <div class="header-right">
          <span class="user-name">{{ profile?.full_name }}</span>
          <span class="user-role">{{ roleLabel }}</span>
          <button @click="handleSignOut" class="sign-out-button">
            Déconnexion
          </button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <slot />
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAuth } from '../composables/useAuth';

defineProps<{
  title: string;
}>();

const router = useRouter();
const { signOut, profile } = useAuth();

const roleLabel = computed(() => {
  if (profile.value?.role === 'admin') return 'Administrateur';
  if (profile.value?.role === 'manager') return 'Manager';
  return 'Employé';
});

const handleSignOut = async () => {
  await signOut();
  router.push('/login');
};
</script>

<style scoped>
.layout {
  min-height: 100vh;
  background: #f5f5f5;
}

.header {
  background: white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  position: sticky;
  top: 0;
  z-index: 100;
}

.header-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 16px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.header-logo {
  height: 40px;
  width: auto;
}

.header-title {
  font-size: 20px;
  font-weight: 700;
  color: #1a1a1a;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

.user-name {
  font-weight: 600;
  color: #333;
}

.user-role {
  padding: 4px 12px;
  background: #00bcbc;
  color: white;
  border-radius: 12px;
  font-size: 13px;
  font-weight: 600;
}

.sign-out-button {
  background: #f5f5f5;
  color: #666;
  border: none;
  padding: 8px 16px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.sign-out-button:hover {
  background: #e0e0e0;
  color: #333;
}

.main-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 32px 24px;
}

@media (max-width: 768px) {
  .header-content {
    padding: 12px 16px;
  }

  .header-logo {
    height: 32px;
  }

  .header-title {
    font-size: 16px;
  }

  .header-right {
    flex-wrap: wrap;
    gap: 8px;
  }

  .user-name {
    font-size: 13px;
  }

  .user-role {
    font-size: 12px;
    padding: 3px 10px;
  }

  .sign-out-button {
    padding: 6px 12px;
    font-size: 13px;
  }

  .main-content {
    padding: 20px 16px;
  }
}

@media (max-width: 480px) {
  .header-left {
    gap: 12px;
  }

  .header-logo {
    height: 28px;
  }

  .header-title {
    font-size: 14px;
  }

  .header-right {
    width: 100%;
    justify-content: space-between;
  }

  .user-name {
    display: none;
  }

  .main-content {
    padding: 16px 12px;
  }
}
</style>
