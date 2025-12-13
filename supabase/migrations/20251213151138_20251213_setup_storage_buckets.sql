/*
  # Setup Storage Buckets and RLS Policies

  1. Storage Buckets
    - `sources` - Private bucket for user-uploaded documents
    - `audio` - Private bucket for generated audio files
    - `public-images` - Public bucket for application images

  2. Security
    - RLS policies for each bucket
    - Users can only access their own notebook files
    - Service role can manage all files
*/

-- Delete existing buckets if they exist
DELETE FROM storage.buckets WHERE id IN ('sources', 'audio', 'public-images');

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('sources', 'sources', false, 52428800, ARRAY[
    'application/pdf',
    'text/plain',
    'text/csv',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'audio/mpeg',
    'audio/wav',
    'audio/mp4',
    'audio/m4a'
  ]),
  
  ('audio', 'audio', false, 104857600, ARRAY[
    'audio/mpeg',
    'audio/wav',
    'audio/mp4',
    'audio/m4a'
  ]),
  
  ('public-images', 'public-images', true, 10485760, ARRAY[
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/svg+xml'
  ])
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types,
  public = EXCLUDED.public;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own source files" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload source files to their notebooks" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own source files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own source files" ON storage.objects;

DROP POLICY IF EXISTS "Users can view their own audio files" ON storage.objects;
DROP POLICY IF EXISTS "Service role can manage audio files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own audio files" ON storage.objects;

DROP POLICY IF EXISTS "Anyone can view public images" ON storage.objects;
DROP POLICY IF EXISTS "Service role can manage public images" ON storage.objects;

-- Sources bucket policies (private - users can only access their own files)
CREATE POLICY "Users can view their own source files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'sources' AND
  (storage.foldername(name))[1]::uuid IN (
    SELECT id FROM public.notebooks WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can upload source files to their notebooks"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'sources' AND
  (storage.foldername(name))[1]::uuid IN (
    SELECT id FROM public.notebooks WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can update their own source files"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'sources' AND
  (storage.foldername(name))[1]::uuid IN (
    SELECT id FROM public.notebooks WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can delete their own source files"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'sources' AND
  (storage.foldername(name))[1]::uuid IN (
    SELECT id FROM public.notebooks WHERE user_id = auth.uid()
  )
);

-- Audio bucket policies (private - users can only access their own audio files)
CREATE POLICY "Users can view their own audio files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'audio' AND
  (storage.foldername(name))[1]::uuid IN (
    SELECT id FROM public.notebooks WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Service role can manage audio files"
ON storage.objects FOR ALL
USING (
  bucket_id = 'audio' AND
  auth.role() = 'service_role'
);

CREATE POLICY "Users can delete their own audio files"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'audio' AND
  (storage.foldername(name))[1]::uuid IN (
    SELECT id FROM public.notebooks WHERE user_id = auth.uid()
  )
);

-- Public images bucket policies (public - anyone can read)
CREATE POLICY "Anyone can view public images"
ON storage.objects FOR SELECT
USING (bucket_id = 'public-images');

CREATE POLICY "Service role can manage public images"
ON storage.objects FOR ALL
USING (
  bucket_id = 'public-images' AND
  auth.role() = 'service_role'
);
