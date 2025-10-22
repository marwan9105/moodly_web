<template>
  <Layout title="Administration">
    <div class="admin-view">
      <div class="dashboard-grid">
        <div class="card stats-card">
          <h3>Statistiques</h3>
          <div class="stats-grid">
            <div class="stat-item">
              <div class="stat-value">{{ stats.totalUsers }}</div>
              <div class="stat-label">Total utilisateurs</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">{{ stats.managers }}</div>
              <div class="stat-label">Managers</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">{{ stats.employees }}</div>
              <div class="stat-label">Employés</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">{{ stats.moodEntries }}</div>
              <div class="stat-label">Entrées d'humeur</div>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-header">
            <h3>Gestion des utilisateurs</h3>
            <button @click="showCreateModal = true" class="primary-button">
              + Créer un utilisateur
            </button>
          </div>

          <!-- Tableau des utilisateurs -->
          <div class="table-container">
            <table>
              <thead>
                <tr>
                  <th>Nom</th>
                  <th>Email</th>
                  <th>Rôle</th>
                  <th>Créé le</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="user in users" :key="user.id">
                  <td>{{ user.full_name }}</td>
                  <td>{{ user.email }}</td>
                  <td>
                    <span :class="['role-badge', user.role]">
                      {{ getRoleLabel(user.role) }}
                    </span>
                  </td>
                  <td>{{ formatDate(user.created_at) }}</td>
                  <td>
                    <button @click="deleteUser(user.id)" class="delete-button">
                      Supprimer
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="card">
          <h3>Suivi des humeurs</h3>
          <div class="mood-chart">
            <div v-for="entry in moodStats" :key="entry.mood_level" class="mood-bar-container">
              <div class="mood-label">{{ getMoodEmoji(entry.mood_level) }}</div>
              <div class="mood-bar-wrapper">
                <div
                  class="mood-bar"
                  :style="{ width: `${(entry.count / maxMoodCount) * 100}%` }"
                ></div>
                <span class="mood-count">{{ entry.count }}</span>
              </div>
            </div>
          </div>
        </div>

        <div class="card">
          <h3>Commentaires anonymes récents</h3>
          <div class="comments-list">
            <div v-for="comment in comments" :key="comment.id" class="comment-item">
              <p>{{ comment.comment }}</p>
              <span class="comment-date">{{ formatDate(comment.created_at) }}</span>
            </div>
            <div v-if="comments.length === 0" class="empty-state">
              Aucun commentaire pour le moment
            </div>
          </div>
        </div>
      </div>

      <div v-if="showCreateModal" class="modal-overlay" @click="showCreateModal = false">
        <div class="modal-content" @click.stop>
          <h2>Créer un utilisateur</h2>
          <form @submit.prevent="handleCreateUser" class="create-form">
            <div v-if="createError" class="error-message">{{ createError }}</div>

            <div class="form-group">
              <label for="fullName">Nom complet</label>
              <input id="fullName" v-model="newUser.fullName" required />
            </div>

            <div class="form-group">
              <label for="email">Email</label>
              <input id="email" v-model="newUser.email" type="email" required />
            </div>

            <div class="form-group">
              <label for="password">Mot de passe</label>
              <input id="password" v-model="newUser.password" type="password" required minlength="6" />
            </div>

            <div class="form-group">
              <label for="role">Rôle</label>
              <select id="role" v-model="newUser.role" required>
                <option value="admin">Administrateur</option>
                <option value="manager">Manager</option>
                <option value="employee">Employé</option>
              </select>
            </div>

            <div class="modal-actions">
              <button type="button" @click="showCreateModal = false" class="secondary-button">
                Annuler
              </button>
              <button type="submit" class="primary-button" :disabled="isCreating">
                {{ isCreating ? 'Création...' : 'Créer' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import Layout from '../components/Layout.vue';
import { supabase, type Profile, type AnonymousComment } from '../lib/supabase';
import { useAuth } from '../composables/useAuth';

const { createUser } = useAuth();

const users = ref<Profile[]>([]);
const comments = ref<AnonymousComment[]>([]);
const moodStats = ref<{ mood_level: number; count: number }[]>([]);
const showCreateModal = ref(false);
const createError = ref('');
const isCreating = ref(false);

const newUser = ref({
  fullName: '',
  email: '',
  password: '',
  role: 'employee' as 'admin' | 'manager' | 'employee',
});

const stats = computed(() => ({
  totalUsers: users.value.length,
  managers: users.value.filter(u => u.role === 'manager').length,
  employees: users.value.filter(u => u.role === 'employee').length,
  moodEntries: moodStats.value.reduce((sum, stat) => sum + stat.count, 0),
}));

const maxMoodCount = computed(() =>
  Math.max(...moodStats.value.map(s => s.count), 1)
);

const loadUsers = async () => {
  const { data } = await supabase
    .from('profiles')
    .select('*')
    .order('created_at', { ascending: false });
  if (data) users.value = data;
};

const loadComments = async () => {
  const { data } = await supabase
    .from('anonymous_comments')
    .select('id, comment, created_at')
    .order('created_at', { ascending: false })
    .limit(10);
  if (data) comments.value = data;
};

const loadMoodStats = async () => {
  const { data } = await supabase
    .from('mood_entries')
    .select('mood_level');

  if (data) {
    const counts: Record<number, number> = {};
    data.forEach(entry => {
      counts[entry.mood_level] = (counts[entry.mood_level] || 0) + 1;
    });

    moodStats.value = [1, 2, 3, 4, 5].map(level => ({
      mood_level: level,
      count: counts[level] || 0,
    }));
  }
};

const handleCreateUser = async () => {
  try {
    createError.value = '';
    isCreating.value = true;

    await createUser(
      newUser.value.email,
      newUser.value.password,
      newUser.value.fullName,
      newUser.value.role
    );

    showCreateModal.value = false;
    newUser.value = { fullName: '', email: '', password: '', role: 'employee' };
    await loadUsers();
  } catch (err: any) {
    createError.value = err.message || 'Erreur lors de la création';
  } finally {
    isCreating.value = false;
  }
};

const deleteUser = async (userId: string) => {
  if (!confirm('Êtes-vous sûr de vouloir supprimer cet utilisateur ?')) return;

  const { error } = await supabase.auth.admin.deleteUser(userId);
  if (!error) await loadUsers();
};

const getRoleLabel = (role: string) => {
  const labels: Record<string, string> = {
    admin: 'Admin',
    manager: 'Manager',
    employee: 'Employé',
  };
  return labels[role] || role;
};

const getMoodEmoji = (level: number) => {
  const emojis = ['😢', '😕', '😐', '🙂', '😄'];
  return emojis[level - 1];
};

const formatDate = (date: string) => {
  return new Date(date).toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
};

onMounted(() => {
  loadUsers();
  loadComments();
  loadMoodStats();
});
</script>

<style scoped>
.admin-view {
  width: 100%;
}

.dashboard-grid {
  display: grid;
  gap: 24px;
}

.card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.stats-card {
  background: linear-gradient(135deg, #00bcbc 0%, #009999 100%);
  color: white;
}

.stats-card h3 {
  color: white;
  margin: 0 0 24px 0;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 20px;
}

.stat-item {
  text-align: center;
}

.stat-value {
  font-size: 36px;
  font-weight: 700;
  line-height: 1.2;
}

.stat-label {
  font-size: 14px;
  opacity: 0.9;
  margin-top: 4px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.card h3 {
  margin: 0 0 24px 0;
  font-size: 20px;
  font-weight: 700;
  color: #1a1a1a;
}

.card-header h3 {
  margin: 0;
}

.primary-button {
  background: #00bcbc;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.primary-button:hover:not(:disabled) {
  background: #009999;
  transform: translateY(-1px);
}

.primary-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.secondary-button {
  background: #f5f5f5;
  color: #666;
  border: none;
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.secondary-button:hover {
  background: #e0e0e0;
}

.table-container {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
}

th {
  text-align: left;
  padding: 12px;
  font-weight: 600;
  color: #666;
  font-size: 14px;
  border-bottom: 2px solid #e0e0e0;
}

td {
  padding: 16px 12px;
  border-bottom: 1px solid #f0f0f0;
}

.role-badge {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
}

.role-badge.admin {
  background: #fee;
  color: #c33;
}

.role-badge.manager {
  background: #ffe;
  color: #c93;
}

.role-badge.employee {
  background: #efe;
  color: #3c3;
}

.delete-button {
  background: #fee;
  color: #c33;
  border: none;
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.delete-button:hover {
  background: #fcc;
}

.mood-chart {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.mood-bar-container {
  display: flex;
  align-items: center;
  gap: 12px;
}

.mood-label {
  font-size: 24px;
  width: 32px;
}

.mood-bar-wrapper {
  flex: 1;
  position: relative;
  height: 32px;
  background: #f5f5f5;
  border-radius: 8px;
  overflow: hidden;
}

.mood-bar {
  height: 100%;
  background: #00bcbc;
  transition: width 0.3s;
  border-radius: 8px;
}

.mood-count {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  font-weight: 600;
  font-size: 14px;
  color: #333;
}

.comments-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-height: 400px;
  overflow-y: auto;
}

.comment-item {
  padding: 16px;
  background: #f8f8f8;
  border-radius: 8px;
  border-left: 4px solid #00bcbc;
}

.comment-item p {
  margin: 0 0 8px 0;
  color: #333;
  line-height: 1.5;
}

.comment-date {
  font-size: 12px;
  color: #999;
}

.empty-state {
  text-align: center;
  padding: 40px;
  color: #999;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.modal-content {
  background: white;
  border-radius: 16px;
  padding: 32px;
  width: 100%;
  max-width: 500px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-content h2 {
  margin: 0 0 24px 0;
  font-size: 24px;
  color: #1a1a1a;
}

.create-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-size: 14px;
  font-weight: 600;
  color: #333;
}

.form-group input,
.form-group select {
  padding: 12px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 16px;
  transition: all 0.2s;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #00bcbc;
  box-shadow: 0 0 0 3px rgba(0, 188, 188, 0.1);
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 8px;
}

.error-message {
  background: #fee;
  color: #c33;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
  border-left: 4px solid #c33;
}

@media (max-width: 768px) {
  .card {
    padding: 16px;
  }

  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
  }

  .stat-value {
    font-size: 28px;
  }

  .stat-label {
    font-size: 12px;
  }

  .card-header {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }

  .card h3 {
    font-size: 18px;
    margin-bottom: 16px;
  }

  .table-container {
    font-size: 14px;
  }

  th, td {
    padding: 8px 6px;
    font-size: 13px;
  }

  .primary-button,
  .secondary-button {
    padding: 10px 16px;
    font-size: 13px;
  }

  .modal-content {
    padding: 24px 20px;
  }

  .modal-content h2 {
    font-size: 20px;
  }

  .role-badge {
    font-size: 11px;
    padding: 3px 8px;
  }
}

@media (max-width: 430px) {
  html, body {
    width: 100%;
    max-width: 100%;
    overflow-x: hidden;
  }

  .dashboard-grid {
    gap: 16px;
  }

  .card {
    padding: 14px;
    overflow: hidden;
  }

  .card-header {
    flex-direction: column;
    align-items: stretch;
    gap: 10px;
    margin-bottom: 14px;
  }

  .primary-button,
  .secondary-button,
  .delete-button {
    padding: 8px 10px;
    font-size: 12px;
    border-radius: 6px;
  }

  .stats-grid {
    grid-template-columns: 1fr 1fr;
    gap: 12px;
  }

  .stat-value { font-size: 24px; }
  .stat-label { font-size: 12px; }

  .table-container {
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
  }
  table {
    width: 100%;
    table-layout: fixed;
    border-collapse: collapse;
  }
  th, td {
    padding: 10px 8px;
    font-size: 12px;
    vertical-align: top;
    word-break: break-word;
  }
  td:nth-child(2) {
    word-break: break-all;
  }
  .role-badge {
    white-space: nowrap;
  }
}

</style>
