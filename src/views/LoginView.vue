<template>
  <div class="login-container">
    <div class="login-card">
      <div class="logo-container">
        <img src="/logo_Moodly.png" alt="Moodly" class="logo" />
      </div>

      <h1>Bienvenue sur Moodly</h1>
      <p class="subtitle">Combattre le burnout ensemble</p>

      <form @submit.prevent="handleLogin" class="login-form">
        <div v-if="error" class="error-message">
          {{ error }}
        </div>

        <div class="form-group">
          <label for="email">Email</label>
          <input
            id="email"
            v-model="email"
            type="email"
            required
            placeholder="votre@email.com"
          />
        </div>

        <div class="form-group">
          <label for="password">Mot de passe</label>
          <input
            id="password"
            v-model="password"
            type="password"
            required
            placeholder="••••••••"
          />
        </div>

        <button type="submit" class="login-button" :disabled="isLoading">
          {{ isLoading ? 'Connexion...' : 'Se connecter' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuth } from '../composables/useAuth';

const router = useRouter();
const { signIn, profile } = useAuth();

const email = ref('');
const password = ref('');
const error = ref('');
const isLoading = ref(false);

const handleLogin = async () => {
  try {
    error.value = '';
    isLoading.value = true;

    await signIn(email.value, password.value);

    if (profile.value?.role === 'admin') {
      router.push('/admin');
    } else if (profile.value?.role === 'manager') {
      router.push('/manager');
    } else {
      router.push('/employee');
    }
  } catch (err: any) {
    error.value = 'Email ou mot de passe incorrect';
  } finally {
    isLoading.value = false;
  }
};
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #00bcbc 0%, #008b8b 100%);
  padding: 20px;
}

.login-card {
  background: white;
  border-radius: 16px;
  padding: 48px;
  width: 100%;
  max-width: 440px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
}

.logo-container {
  display: flex;
  justify-content: center;
  margin-bottom: 32px;
}

.logo {
  height: 60px;
  width: auto;
}

h1 {
  text-align: center;
  color: #1a1a1a;
  font-size: 28px;
  font-weight: 700;
  margin: 0 0 8px 0;
  line-height: 1.2;
}

.subtitle {
  text-align: center;
  color: #666;
  font-size: 16px;
  margin: 0 0 32px 0;
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

label {
  font-size: 14px;
  font-weight: 600;
  color: #333;
}

input {
  padding: 12px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 16px;
  transition: all 0.2s;
}

input:focus {
  outline: none;
  border-color: #00bcbc;
  box-shadow: 0 0 0 3px rgba(0, 188, 188, 0.1);
}

.login-button {
  background: #00bcbc;
  color: white;
  border: none;
  padding: 14px;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  margin-top: 8px;
}

.login-button:hover:not(:disabled) {
  background: #009999;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 188, 188, 0.3);
}

.login-button:active:not(:disabled) {
  transform: translateY(0);
}

.login-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error-message {
  background: #fee;
  color: #c33;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
  border-left: 4px solid #c33;
}

@media (max-width: 640px) {
  .login-card {
    padding: 32px 24px;
  }

  h1 {
    font-size: 24px;
  }

  .subtitle {
    font-size: 14px;
  }
}
</style>
