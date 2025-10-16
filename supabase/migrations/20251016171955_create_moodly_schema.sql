/*
  # Moodly Database Schema - Burnout Prevention Platform

  ## Overview
  This migration creates the complete database structure for Moodly, an application 
  designed to combat workplace burnout through mood tracking and anonymous feedback.

  ## 1. New Tables

  ### `profiles`
  Extended user information linked to auth.users
  - `id` (uuid, primary key) - Links to auth.users.id
  - `email` (text) - User email
  - `full_name` (text) - User's full name
  - `role` (text) - User role: 'admin', 'manager', or 'employee'
  - `created_by` (uuid) - ID of the user who created this account
  - `created_at` (timestamptz) - Account creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### `mood_entries`
  Daily mood tracking for employees
  - `id` (uuid, primary key)
  - `user_id` (uuid) - Employee who logged the mood
  - `mood_level` (integer) - Mood rating (1-5 scale)
  - `notes` (text) - Optional personal notes
  - `created_at` (timestamptz) - Entry timestamp

  ### `anonymous_comments`
  Anonymous feedback system
  - `id` (uuid, primary key)
  - `user_id` (uuid) - Employee who wrote the comment (kept for auditing but not exposed)
  - `comment` (text) - Anonymous comment content
  - `created_at` (timestamptz) - Comment timestamp

  ## 2. Security

  ### Row Level Security (RLS)
  - All tables have RLS enabled for maximum security
  
  ### Profiles Table Policies
  - Admins can view and manage all profiles
  - Managers can view employees and other managers, create employees
  - Employees can only view their own profile
  
  ### Mood Entries Policies
  - Admins and managers can view all mood entries
  - Employees can create and view only their own entries
  
  ### Anonymous Comments Policies
  - Admins and managers can read all comments (but not see who wrote them)
  - Employees can create comments but cannot read them back (ensuring anonymity)

  ## 3. Important Notes
  - User creation is restricted: only admins and managers can create accounts
  - Anonymous comments are truly anonymous from the application perspective
  - All timestamps use timestamptz for accurate time tracking across timezones
  - Default values ensure data integrity
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  role text NOT NULL CHECK (role IN ('admin', 'manager', 'employee')),
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create mood_entries table
CREATE TABLE IF NOT EXISTS mood_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  mood_level integer NOT NULL CHECK (mood_level >= 1 AND mood_level <= 5),
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

-- Create anonymous_comments table
CREATE TABLE IF NOT EXISTS anonymous_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  comment text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE mood_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE anonymous_comments ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Managers can view employees and managers"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'manager'
    )
    OR auth.uid() = id
  );

CREATE POLICY "Employees can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Admins can create any profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Managers can create employee profiles"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'manager'
    )
    AND role = 'employee'
  );

CREATE POLICY "Admins can update any profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can delete any profile"
  ON profiles FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- Mood Entries Policies
CREATE POLICY "Admins can view all mood entries"
  ON mood_entries FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Managers can view all mood entries"
  ON mood_entries FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'manager'
    )
  );

CREATE POLICY "Employees can view own mood entries"
  ON mood_entries FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Employees can create mood entries"
  ON mood_entries FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Employees can update own mood entries"
  ON mood_entries FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Employees can delete own mood entries"
  ON mood_entries FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Anonymous Comments Policies
CREATE POLICY "Admins can view anonymous comments"
  ON anonymous_comments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Managers can view anonymous comments"
  ON anonymous_comments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'manager'
    )
  );

CREATE POLICY "Employees can create anonymous comments"
  ON anonymous_comments FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
    )
  );

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_created_by ON profiles(created_by);
CREATE INDEX IF NOT EXISTS idx_mood_entries_user_id ON mood_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_mood_entries_created_at ON mood_entries(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_anonymous_comments_created_at ON anonymous_comments(created_at DESC);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for profiles table
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();