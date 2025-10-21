# Moodly

Application web construite avec **Vue 3 + Vite + TypeScript** et **Supabase** pour suivre le bien-être des employés.  
Les rôles disponibles sont : `admin`, `manager`, `employee`.

---

## Lancer le projet en local

### 1️. Cloner le dépôt
```bash
git clone https://github.com/marwan9105/moodly_web.git
cd moodly_web
```

### 2️. Installer les dépendances
```bash
npm install
```

### 3️. Créer un projet Supabase
1. Va sur [https://supabase.com/](https://supabase.com/)  
2. Clique sur **New Project** et crée ton projet  
3. Va dans **Project Settings → API**
   - Copie **Project URL**
   - Copie **anon public key**

---

## Configurer l’environnement

Crée un fichier `.env` à la racine avec :

```bash
VITE_SUPABASE_URL=https://xxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1...
```

> Ces clés se trouvent dans **Project Settings → API**

---

## Importer la base de données

Dans Supabase :

1. Ouvre **SQL Editor → New Query**  
2. Copie le contenu des fichiers `.sql` du dossier `/supabase/migrations` un par un
   - `tables.sql`  
   - `policies.sql`  
   - `triggers.sql`  
   - `functions.sql`  
3. Exécute-les pour créer les tables :
   - `profiles`
   - `mood_entries`
   - `anonymous_comments`

---

## Démarrage du projet

```bash
npm run dev
```

L’application sera disponible sur :
-> [http://localhost:5173](http://localhost:5173)

---

## Compte Admin par défaut (exemple)

| Rôle | Email | Mot de passe |
|------|--------|--------------|
| Admin | admin@moodly.com | password |

> Si besoin, crée un utilisateur depuis **Supabase → Authentication → Users**  
> et ajoute-le dans la table `profiles` avec le rôle `admin`.

---
