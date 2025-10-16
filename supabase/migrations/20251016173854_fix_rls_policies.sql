/*
  # Correction des politiques RLS - Élimination de la récursion infinie

  ## Problème
  Les politiques RLS créaient une récursion infinie en essayant de vérifier le rôle 
  de l'utilisateur dans la table profiles elle-même.

  ## Solution
  Supprimer toutes les anciennes politiques et créer de nouvelles politiques simplifiées
  qui évitent la récursion.
*/

-- Supprimer toutes les anciennes politiques
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Managers can view employees and managers" ON profiles;
DROP POLICY IF EXISTS "Employees can view own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can create any profile" ON profiles;
DROP POLICY IF EXISTS "Managers can create employee profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can delete any profile" ON profiles;

DROP POLICY IF EXISTS "Admins can view all mood entries" ON mood_entries;
DROP POLICY IF EXISTS "Managers can view all mood entries" ON mood_entries;
DROP POLICY IF EXISTS "Employees can view own mood entries" ON mood_entries;
DROP POLICY IF EXISTS "Employees can create mood entries" ON mood_entries;
DROP POLICY IF EXISTS "Employees can update own mood entries" ON mood_entries;
DROP POLICY IF EXISTS "Employees can delete own mood entries" ON mood_entries;

DROP POLICY IF EXISTS "Admins can view anonymous comments" ON anonymous_comments;
DROP POLICY IF EXISTS "Managers can view anonymous comments" ON anonymous_comments;
DROP POLICY IF EXISTS "Employees can create anonymous comments" ON anonymous_comments;

-- Créer une fonction pour obtenir le rôle de l'utilisateur actuel
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$;

-- Nouvelles politiques pour profiles (sans récursion)
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Admins and managers can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    get_user_role() IN ('admin', 'manager')
  );

CREATE POLICY "Admins can insert profiles"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (get_user_role() = 'admin');

CREATE POLICY "Managers can insert employee profiles"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() = 'manager' AND role = 'employee'
  );

CREATE POLICY "Admins can update profiles"
  ON profiles FOR UPDATE
  TO authenticated
  USING (get_user_role() = 'admin')
  WITH CHECK (get_user_role() = 'admin');

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can delete profiles"
  ON profiles FOR DELETE
  TO authenticated
  USING (get_user_role() = 'admin');

-- Politiques pour mood_entries
CREATE POLICY "Admins and managers can view all mood entries"
  ON mood_entries FOR SELECT
  TO authenticated
  USING (
    get_user_role() IN ('admin', 'manager') OR auth.uid() = user_id
  );

CREATE POLICY "Users can create own mood entries"
  ON mood_entries FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own mood entries"
  ON mood_entries FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own mood entries"
  ON mood_entries FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Politiques pour anonymous_comments
CREATE POLICY "Admins and managers can view comments"
  ON anonymous_comments FOR SELECT
  TO authenticated
  USING (get_user_role() IN ('admin', 'manager'));

CREATE POLICY "Users can create anonymous comments"
  ON anonymous_comments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);
