<template>
  <Layout title="Mon espace">
    <div class="employee-view">
      <div class="dashboard-grid">
        <div class="card welcome-card">
          <h2>Bonjour {{ profile?.full_name }} 👋</h2>
          <p>Comment vous sentez-vous aujourd'hui ?</p>
        </div>

        <div class="card mood-card">
          <h3>Enregistrer mon humeur</h3>
          <p class="card-description">Sélectionnez l'émoticône qui correspond le mieux à votre état actuel</p>

          <div class="mood-selector">
            <button
              v-for="level in [1, 2, 3, 4, 5]"
              :key="level"
              @click="selectedMood = level"
              :class="['mood-button', { active: selectedMood === level }]"
            >
              <span class="mood-emoji">{{ getMoodEmoji(level) }}</span>
              <span class="mood-text">{{ getMoodLabel(level) }}</span>
            </button>
          </div>

          <div class="form-group">
            <label for="notes">Notes personnelles (optionnel)</label>
            <textarea
              id="notes"
              v-model="moodNotes"
              placeholder="Partagez vos pensées, ce qui vous préoccupe..."
              rows="3"
            ></textarea>
          </div>

          <button @click="saveMood" class="primary-button" :disabled="!selectedMood || isSaving">
            {{ isSaving ? 'Enregistrement...' : 'Enregistrer' }}
          </button>

          <div v-if="saveSuccess" class="success-message">
            Humeur enregistrée avec succès !
          </div>
        </div>

        <div class="card">
          <h3>Mon historique d'humeur</h3>
          <div class="mood-history">
            <div v-for="entry in myMoodEntries" :key="entry.id" class="mood-entry">
              <div class="mood-entry-header">
                <span class="mood-emoji-large">{{ getMoodEmoji(entry.mood_level) }}</span>
                <div class="mood-entry-info">
                  <span class="mood-entry-label">{{ getMoodLabel(entry.mood_level) }}</span>
                  <span class="mood-entry-date">{{ formatDate(entry.created_at) }}</span>
                </div>
              </div>
              <p v-if="entry.notes" class="mood-entry-notes">{{ entry.notes }}</p>
            </div>
            <div v-if="myMoodEntries.length === 0" class="empty-state">
              Vous n'avez pas encore enregistré d'humeur
            </div>
          </div>
        </div>

        <div class="card">
          <h3>Commentaire anonyme</h3>
          <p class="card-description">
            Partagez vos préoccupations de manière anonyme. Votre identité ne sera jamais révélée.
          </p>

          <div class="form-group">
            <label for="comment">Votre commentaire</label>
            <textarea
              id="comment"
              v-model="anonymousComment"
              placeholder="Exprimez-vous librement et anonymement..."
              rows="4"
            ></textarea>
          </div>

          <button
            @click="saveComment"
            class="secondary-button"
            :disabled="!anonymousComment.trim() || isSubmittingComment"
          >
            {{ isSubmittingComment ? 'Envoi...' : 'Envoyer anonymement' }}
          </button>

          <div v-if="commentSuccess" class="success-message">
            Commentaire envoyé avec succès !
          </div>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import Layout from '../components/Layout.vue';
import { supabase, type MoodEntry } from '../lib/supabase';
import { useAuth } from '../composables/useAuth';

const { profile, user } = useAuth();

const selectedMood = ref<number | null>(null);
const moodNotes = ref('');
const myMoodEntries = ref<MoodEntry[]>([]);
const anonymousComment = ref('');
const isSaving = ref(false);
const isSubmittingComment = ref(false);
const saveSuccess = ref(false);
const commentSuccess = ref(false);

const loadMyMoodEntries = async () => {
  if (!user.value) return;

  const { data } = await supabase
    .from('mood_entries')
    .select('*')
    .eq('user_id', user.value.id)
    .order('created_at', { ascending: false })
    .limit(10);

  if (data) myMoodEntries.value = data;
};

const saveMood = async () => {
  if (!selectedMood.value || !user.value) return;

  try {
    isSaving.value = true;
    saveSuccess.value = false;

    const { error } = await supabase.from('mood_entries').insert({
      user_id: user.value.id,
      mood_level: selectedMood.value,
      notes: moodNotes.value,
    });

    if (error) throw error;

    saveSuccess.value = true;
    selectedMood.value = null;
    moodNotes.value = '';
    await loadMyMoodEntries();

    setTimeout(() => {
      saveSuccess.value = false;
    }, 3000);
  } finally {
    isSaving.value = false;
  }
};

const saveComment = async () => {
  if (!anonymousComment.value.trim() || !user.value) return;

  try {
    isSubmittingComment.value = true;
    commentSuccess.value = false;

    const { error } = await supabase.from('anonymous_comments').insert({
      user_id: user.value.id,
      comment: anonymousComment.value,
    });

    if (error) throw error;

    commentSuccess.value = true;
    anonymousComment.value = '';

    setTimeout(() => {
      commentSuccess.value = false;
    }, 3000);
  } finally {
    isSubmittingComment.value = false;
  }
};

const getMoodEmoji = (level: number) => {
  const emojis = ['😢', '😕', '😐', '🙂', '😄'];
  return emojis[level - 1];
};

const getMoodLabel = (level: number) => {
  const labels = ['Très mauvais', 'Mauvais', 'Neutre', 'Bien', 'Excellent'];
  return labels[level - 1];
};

const formatDate = (date: string) => {
  const d = new Date(date);
  return d.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

onMounted(() => {
  loadMyMoodEntries();
});
</script>

<style scoped>
.employee-view {
  width: 100%;
}

.dashboard-grid {
  display: grid;
  gap: 24px;
  max-width: 900px;
  margin: 0 auto;
}

.card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.welcome-card {
  background: linear-gradient(135deg, #00bcbc 0%, #009999 100%);
  color: white;
  text-align: center;
  padding: 40px 24px;
}

.welcome-card h2 {
  margin: 0 0 8px 0;
  font-size: 28px;
  font-weight: 700;
  line-height: 1.2;
}

.welcome-card p {
  margin: 0;
  font-size: 18px;
  opacity: 0.9;
}

.mood-card {
  border: 2px solid #00bcbc;
}

.card h3 {
  margin: 0 0 8px 0;
  font-size: 20px;
  font-weight: 700;
  color: #1a1a1a;
}

.card-description {
  color: #666;
  margin: 0 0 24px 0;
  line-height: 1.5;
}

.mood-selector {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 12px;
  margin-bottom: 24px;
}

.mood-button {
  background: #f5f5f5;
  border: 3px solid transparent;
  border-radius: 12px;
  padding: 16px 8px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.mood-button:hover {
  background: #e8e8e8;
  transform: translateY(-2px);
}

.mood-button.active {
  background: #e0f7f7;
  border-color: #00bcbc;
  transform: scale(1.05);
}

.mood-emoji {
  font-size: 36px;
}

.mood-text {
  font-size: 12px;
  font-weight: 600;
  color: #666;
  text-align: center;
}

.mood-button.active .mood-text {
  color: #00bcbc;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 16px;
}

.form-group label {
  font-size: 14px;
  font-weight: 600;
  color: #333;
}

.form-group textarea {
  padding: 12px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 16px;
  font-family: inherit;
  resize: vertical;
  transition: all 0.2s;
}

.form-group textarea:focus {
  outline: none;
  border-color: #00bcbc;
  box-shadow: 0 0 0 3px rgba(0, 188, 188, 0.1);
}

.primary-button {
  background: #00bcbc;
  color: white;
  border: none;
  padding: 14px 24px;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  width: 100%;
}

.primary-button:hover:not(:disabled) {
  background: #009999;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 188, 188, 0.3);
}

.primary-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.secondary-button {
  background: #f5f5f5;
  color: #666;
  border: 2px solid #e0e0e0;
  padding: 14px 24px;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  width: 100%;
}

.secondary-button:hover:not(:disabled) {
  background: #e8e8e8;
  border-color: #ccc;
}

.secondary-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.success-message {
  background: #e8f5e9;
  color: #2e7d32;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
  border-left: 4px solid #4caf50;
  margin-top: 16px;
  animation: slideDown 0.3s ease-out;
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.mood-history {
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-height: 500px;
  overflow-y: auto;
}

.mood-entry {
  padding: 16px;
  background: #f8f8f8;
  border-radius: 12px;
  border-left: 4px solid #00bcbc;
}

.mood-entry-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 8px;
}

.mood-emoji-large {
  font-size: 32px;
}

.mood-entry-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.mood-entry-label {
  font-weight: 600;
  color: #333;
}

.mood-entry-date {
  font-size: 13px;
  color: #999;
}

.mood-entry-notes {
  margin: 8px 0 0 0;
  color: #666;
  line-height: 1.5;
  padding-left: 48px;
}

.empty-state {
  text-align: center;
  padding: 40px;
  color: #999;
}

@media (max-width: 768px) {
  .mood-selector {
    grid-template-columns: repeat(3, 1fr);
  }

  .mood-emoji {
    font-size: 28px;
  }

  .mood-text {
    font-size: 11px;
  }

  .welcome-card {
    padding: 32px 20px;
  }

  .welcome-card h2 {
    font-size: 24px;
  }

  .welcome-card p {
    font-size: 16px;
  }
}

@media (max-width: 480px) {
  .mood-selector {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
