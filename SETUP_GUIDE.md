# InsightsLM Setup Guide

This guide walks you through setting up and using the InsightsLM application to create notebooks, upload sources, and generate summaries through N8N webhooks.

## Architecture Overview

The application uses:
- **Frontend**: React with TypeScript for the user interface
- **Backend**: Supabase with PostgreSQL database
- **File Storage**: Supabase Storage for documents and audio
- **Processing**: N8N webhooks for document processing and AI summarization
- **Edge Functions**: Supabase Edge Functions for orchestration

## Complete Workflow

```
1. User creates a notebook
   ↓
2. User uploads PDF/documents or pastes text/URLs
   ↓
3. Files are uploaded to Supabase Storage
   ↓
4. Edge function processes the document and calls N8N webhook
   ↓
5. N8N extracts text, generates summary, and sends callback
   ↓
6. Callback updates the source with summary and content
   ↓
7. User sees the brief/summary in their notebook
```

## Setting Up N8N Webhooks

You need to set up the following environment variables in Supabase for the edge functions:

### Required Environment Variables

Set these in your Supabase project settings (Project Settings → Secrets):

```
DOCUMENT_PROCESSING_WEBHOOK_URL=https://your-n8n-instance.com/webhook/document-processing
ADDITIONAL_SOURCES_WEBHOOK_URL=https://your-n8n-instance.com/webhook/additional-sources
NOTEBOOK_GENERATION_AUTH=your-n8n-auth-token
```

### How to Find Your N8N Webhook URLs

1. In N8N, go to each workflow
2. Click on the Webhook trigger node
3. Copy the webhook URL from the node settings
4. Add it to your Supabase secrets

## Feature Breakdown

### 1. Create a Notebook
- User provides title and optional description
- Notebook is created in the database with user_id
- Notebook includes metadata like color and icon

### 2. Upload Sources
Sources can be:
- **PDF files**: Uploaded to storage, text extracted via N8N
- **Text/Audio files**: Uploaded to storage, processed via N8N
- **Website URLs**: Content downloaded and processed via N8N
- **Copied Text**: Directly sent to N8N for processing

### 3. Document Processing Flow

**For File Uploads (PDF, TXT, Audio):**
1. Create source record in database with status "pending"
2. Upload file to Supabase Storage (`/sources/{notebookId}/{sourceId}.ext`)
3. Call `process-document` edge function
4. Edge function calls N8N webhook with:
   - `source_id`: Source UUID
   - `file_url`: Public URL to the uploaded file
   - `file_path`: Storage path
   - `source_type`: 'pdf', 'text', or 'audio'
   - `callback_url`: Edge function endpoint for response

5. N8N processes the file:
   - Extracts text content
   - Generates summary/brief
   - Returns callback with results

6. N8N calls back the callback endpoint with:
   - `source_id`: Original source ID
   - `title`: Extracted or original title
   - `summary`: Brief summary of the content
   - `content`: Full extracted text
   - `status`: 'completed' or 'failed'

7. `process-document-callback` updates the source record

**For Text/Website Sources:**
1. Create source record in database
2. Call `process-additional-sources` edge function
3. Edge function sends to N8N webhook with:
   - `type`: 'copied-text' or 'multiple-websites'
   - `notebookId`: Notebook UUID
   - `content`: Text content (for copied text)
   - `urls`: Array of URLs (for websites)
   - `sourceIds`: Array of source IDs
   - `timestamp`: ISO timestamp

4. N8N processes and sends summaries back
5. Callback updates sources with summaries

## Source Status Lifecycle

```
pending          → Source created, waiting to upload
   ↓
uploading        → File being uploaded to storage
   ↓
processing       → Sent to N8N for processing
   ↓
completed        → Processing done, summary available
   ↓
failed           → Error during processing
```

## Edge Functions

### process-document
- **Endpoint**: `/functions/v1/process-document`
- **Method**: POST
- **Body**: `{ sourceId, filePath, sourceType }`
- **Purpose**: Initiates PDF/audio/text processing

### process-document-callback
- **Endpoint**: `/functions/v1/process-document-callback`
- **Method**: POST
- **Body**: `{ source_id, title, summary, content, status }`
- **Purpose**: Receives N8N processing results

### process-additional-sources
- **Endpoint**: `/functions/v1/process-additional-sources`
- **Method**: POST
- **Body**: `{ type, notebookId, urls/content, sourceIds }`
- **Purpose**: Handles website and copied text processing

### webhook-handler
- **Endpoint**: `/functions/v1/webhook-handler`
- **Purpose**: Generic webhook handler for various event types

## Database Schema

### notebooks
```
- id (UUID): Primary key
- user_id (UUID): Foreign key to profiles.id
- title (text): Notebook title
- description (text): Optional description
- color (text): Display color
- icon (text): Display emoji
- generation_status (text): 'completed', 'pending', etc.
- audio_overview_generation_status (text): Audio generation status
- audio_overview_url (text): Generated audio file URL
- audio_url_expires_at (timestamptz): Audio URL expiration
- example_questions (text[]): Auto-generated questions
- created_at (timestamptz): Creation timestamp
- updated_at (timestamptz): Last update timestamp
```

### sources
```
- id (UUID): Primary key
- notebook_id (UUID): Foreign key to notebooks.id
- title (text): Source title
- type (enum): 'pdf', 'text', 'website', 'youtube', 'audio'
- url (text): For website/YouTube sources
- file_path (text): Storage path for uploaded files
- file_size (bigint): File size in bytes
- display_name (text): Display name
- content (text): Extracted full text
- summary (text): Generated summary/brief
- processing_status (text): 'pending', 'processing', 'completed', 'failed'
- metadata (jsonb): Additional metadata
- created_at (timestamptz): Creation timestamp
- updated_at (timestamptz): Last update timestamp
```

### notes
```
- id (UUID): Primary key
- notebook_id (UUID): Foreign key to notebooks.id
- title (text): Note title
- content (text): Note content
- source_type (text): 'user', 'generated', etc.
- extracted_text (text): Text extracted from sources
- created_at (timestamptz): Creation timestamp
- updated_at (timestamptz): Last update timestamp
```

## Security

### Row Level Security (RLS)
All tables have RLS enabled:
- Users can only access their own notebooks and related data
- Sources and notes are filtered by notebook ownership
- Profiles can only be viewed/updated by the user

### Storage Security
- Sources bucket: Users can only access their own files (by notebook_id path)
- Audio bucket: Users can only access generated audio for their notebooks
- Service role has full access for processing

## Testing the Complete Workflow

1. **Create a notebook**
   - Go to Dashboard
   - Click "New Notebook"
   - Enter title and description

2. **Upload a PDF**
   - Click "Add Sources" in the notebook
   - Drag & drop a PDF or click to select
   - Wait for upload to complete
   - Source status should change from pending → processing → completed
   - Brief/summary should appear once N8N processes it

3. **Add website URLs**
   - Click "Add Sources"
   - Click "Link - Website"
   - Paste multiple URLs
   - Sources will be created and sent to N8N
   - Summaries will appear once processing completes

4. **Paste text**
   - Click "Add Sources"
   - Click "Paste Text"
   - Paste copied content
   - Source will be created with the text content
   - N8N will generate summary

## Troubleshooting

### "Could not find the table 'public.notebooks'"
- This is a schema cache issue
- Solution: Refresh the browser or restart the dev server
- The database tables exist but the Supabase client cache is stale

### Sources stuck in "processing"
- Check that N8N webhooks are configured correctly
- Verify webhook URLs are correct in Supabase secrets
- Check N8N webhook responses in console logs

### File upload fails
- Check storage bucket policies are correct
- Verify bucket exists: `sources`, `audio`, `public-images`
- Check file types are allowed (PDF, TXT, MP3, WAV, M4A)
- Max file size is 50MB

### Callback not updating sources
- Verify `SUPABASE_SERVICE_ROLE_KEY` is set in edge functions
- Check callback URL is correct in process-document
- Verify source_id is being sent in callback

## API Endpoints

### Notebook Operations
- **Create**: POST `/functions/v1/generate-notebook-content`
- **Update**: PATCH database directly
- **Delete**: DELETE database directly
- **List**: Query database with RLS

### Source Operations
- **Create**: INSERT into sources table
- **Upload**: POST to storage bucket
- **Update**: PATCH with callback from N8N
- **Delete**: DELETE with cascade

### Processing Operations
- **Start Processing**: POST `/functions/v1/process-document`
- **Callback**: POST `/functions/v1/process-document-callback`
- **Additional**: POST `/functions/v1/process-additional-sources`

## Next Steps

1. Configure N8N webhooks URLs in Supabase
2. Test file upload and processing
3. Customize notebook templates if needed
4. Add more source types as needed
5. Implement audio overview generation
6. Add chat functionality with sources
