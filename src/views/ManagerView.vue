<template>
  <Layout title="Tableau de bord Manager">
    <div class="manager-view">
      <div class="dashboard-grid">
        <div class="card stats-card">
          <h3>Vue d'ensemble</h3>
          <div class="stats-grid">
            <div class="stat-item">
              <div class="stat-value">{{ employees.length }}</div>
              <div class="stat-label">Employés</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">{{ todayMoods }}</div>
              <div class="stat-label">Humeurs aujourd'hui</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">{{ averageMood.toFixed(1) }}</div>
              <div class="stat-label">Humeur moyenne</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">{{ comments.length }}</div>
              <div class="stat-label">Commentaires</div>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-header">
            <h3>Mes employés</h3>
            <button @click="showCreateModal = true" class="primary-button">
              + Ajouter un employé
            </button>
          </div>

          <div v-if="deleteError" class="error-message" style="margin-bottom:12px">
            {{ deleteError }}
          </div>

          <div class="table-container">
            <table>
              <thead>
                <tr>
                  <th>Nom</th>
                  <th>Email</th>
                  <th>Date de création</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="employee in employees" :key="employee.id">
                  <td>{{ employee.full_name }}</td>
                  <td>{{ employee.email }}</td>
                  <td>{{ formatDate(employee.created_at) }}</td>
                  <td>
                    <button
                      class="delete-button"
                      @click="handleDeleteEmployee(employee)"
                      :disabled="isDeletingId === employee.id"
                    >
                      {{ isDeletingId === employee.id ? 'Suppression…' : 'Supprimer' }}
                    </button>
                  </td>
                </tr>
                <tr v-if="employees.length === 0">
                  <td colspan="4" class="no-data">Aucun employé trouvé</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="card">
          <h3>Distribution des humeurs</h3>
          <div class="mood-chart">
            <div
              v-for="entry in moodStats"
              :key="entry.mood_level"
              class="mood-bar-container"
            >
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
          <h2>Ajouter un employé</h2>
          <form @submit.prevent="handleCreateEmployee" class="create-form">
            <div v-if="createError" class="error-message">{{ createError }}</div>

            <div class="form-group">
              <label for="fullName">Nom complet</label>
              <input id="fullName" v-model="newEmployee.fullName" required />
            </div>

            <div class="form-group">
              <label for="email">Email</label>
              <input id="email" v-model="newEmployee.email" type="email" required />
            </div>

            <div class="form-group">
              <label for="password">Mot de passe</label>
              <input
                id="password"
                v-model="newEmployee.password"
                type="password"
                required
                minlength="6"
              />
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
import { supabase, type Profile, type MoodEntry, type AnonymousComment } from '../lib/supabase';
import { useAuth } from '../composables/useAuth';

const { createUser, user, ready } = useAuth();

const employees = ref<Profile[]>([]);
const moodEntries = ref<MoodEntry[]>([]);
const comments = ref<AnonymousComment[]>([]);
const showCreateModal = ref(false);
const createError = ref('');
const isCreating = ref(false);

// suppression
const deleteError = ref('');
const isDeletingId = ref<string | null>(null);

const newEmployee = ref({
  fullName: '',
  email: '',
  password: '',
});

const moodStats = computed(() => {
  const counts: Record<number, number> = {};
  moodEntries.value.forEach(entry => {
    counts[entry.mood_level] = (counts[entry.mood_level] || 0) + 1;
  });

  return [1, 2, 3, 4, 5].map(level => ({
    mood_level: level,
    count: counts[level] || 0,
  }));
});

const maxMoodCount = computed(() =>
  Math.max(...moodStats.value.map(s => s.count), 1)
);

const todayMoods = computed(() => {
  const today = new Date().toDateString();
  return moodEntries.value.filter(
    entry => new Date(entry.created_at).toDateString() === today
  ).length;
});

const averageMood = computed(() => {
  if (moodEntries.value.length === 0) return 0;
  const sum = moodEntries.value.reduce((acc, entry) => acc + entry.mood_level, 0);
  return sum / moodEntries.value.length;
});

const loadEmployees = async () => {
  deleteError.value = '';
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('role', 'employee')
    .eq('created_by', user.value?.id ?? '')
    .order('created_at', { ascending: false });

  if (error) {
    deleteError.value = error.message;
    return;
  }
  if (data) employees.value = data;
};

const loadMoodEntries = async () => {
  const { data } = await supabase
    .from('mood_entries')
    .select('*')
    .order('created_at', { ascending: false });
  if (data) moodEntries.value = data;
};

const loadComments = async () => {
  const { data } = await supabase
    .from('anonymous_comments')
    .select('id, comment, created_at')
    .order('created_at', { ascending: false })
    .limit(10);
  if (data) comments.value = data;
};


const handleCreateEmployee = async () => {
  try {
    createError.value = '';
    isCreating.value = true;

    await createUser(
      newEmployee.value.email,
      newEmployee.value.password,
      newEmployee.value.fullName,
      'employee'
    );

    showCreateModal.value = false;
    newEmployee.value = { fullName: '', email: '', password: '' };
    await loadEmployees();
  } catch (err: any) {
    createError.value = err.message || 'Erreur lors de la création';
  } finally {
    isCreating.value = false;
  }
};

const handleDeleteEmployee = async (employee: Profile) => {
  deleteError.value = '';
  if (!confirm(`Supprimer ${employee.full_name || employee.email} ?`)) return;

  try {
    isDeletingId.value = employee.id;

    const { error } = await supabase
      .from('profiles')
      .delete()
      .eq('id', employee.id);

    if (error) throw error;

    employees.value = employees.value.filter(e => e.id !== employee.id);
  } catch (e: any) {
    deleteError.value = e.message || 'Erreur lors de la suppression';
  } finally {
    isDeletingId.value = null;
  }
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

onMounted(async () => {
  await ready();
  await loadEmployees();
  await loadMoodEntries();
  await loadComments();
});
</script>

<style scoped>
.manager-view {
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

.no-data {
  color: #999;
  font-style: italic;
  text-align: center;
}

.mood-indicator {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  background: #f5f5f5;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
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

.form-group input {
  padding: 12px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 16px;
  transition: all 0.2s;
}

.form-group input:focus {
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
.delete-button:hover:not(:disabled) { background: #fcc; }
.delete-button:disabled { opacity: .6; cursor: not-allowed; }

.error-message {
  background: #fee;
  color: #c33;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
  border-left: 4px solid #c33;
}

@media (max-width: 768px) {
  .card { padding: 16px; }

  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
  }

  .stat-value { font-size: 28px; }
  .stat-label { font-size: 12px; }

  .card-header {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }

  .card h3 {
    font-size: 18px;
    margin-bottom: 16px;
  }

  .table-container { font-size: 14px; }

  th, td {
    padding: 8px 6px;
    font-size: 13px;
  }

  .primary-button,
  .secondary-button {
    padding: 10px 16px;
    font-size: 13px;
  }

  .modal-content { padding: 24px 20px; }
  .modal-content h2 { font-size: 20px; }
}

@media (max-width: 480px) {
  .stats-grid { grid-template-columns: 1fr 1fr; }

  table { font-size: 12px; }
  th, td { padding: 6px 4px; }

  .mood-label { font-size: 20px; width: 24px; }
  .mood-bar-wrapper { height: 28px; }
}
</style>
