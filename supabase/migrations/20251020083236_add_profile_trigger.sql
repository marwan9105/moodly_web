/*
  # Ajout d'un trigger pour créer automatiquement les profils

  ## Problème
  Lorsqu'un utilisateur est créé via auth.signUp(), le profil n'est pas créé automatiquement
  dans la table profiles, ce qui empêche la connexion.

  ## Solution
  Créer un trigger qui s'exécute automatiquement après l'insertion d'un utilisateur
  dans auth.users et crée le profil correspondant dans la table profiles.

  ## Détails
  - La fonction handle_new_user() récupère les métadonnées utilisateur (full_name, role, created_by)
  - Le trigger on_auth_user_created s'exécute après chaque INSERT dans auth.users
  - Le profil est créé automatiquement avec les bonnes informations
*/

-- Fonction pour créer automatiquement un profil lors de l'inscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, created_by)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'employee'),
    COALESCE((NEW.raw_user_meta_data->>'created_by')::uuid, NULL)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer le trigger s'il existe déjà
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Créer le trigger qui s'exécute après l'insertion d'un utilisateur
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
