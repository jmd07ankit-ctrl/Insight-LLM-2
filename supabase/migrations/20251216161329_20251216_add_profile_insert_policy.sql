/*
  # Add INSERT policy for profiles table

  1. Security Changes
    - Add INSERT policy for profiles table to allow authenticated users to create their own profile
*/

DROP POLICY IF EXISTS "Users can create their own profile" ON public.profiles;
CREATE POLICY "Users can create their own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);
