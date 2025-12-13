# Quick Start Guide

Get your InsightsLM application running in 5 minutes!

## Prerequisites

- Node.js 18+ installed
- Supabase account with project set up
- N8N instance with webhooks configured (or use the provided N8N workflows)

## Step 1: Environment Setup

Your `.env` file is already configured with:
```
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-anon-key
```

No additional setup needed!

## Step 2: Database & Storage

The database is already initialized with:
- ✅ All required tables (notebooks, sources, notes, documents, profiles)
- ✅ Row Level Security (RLS) enabled on all tables
- ✅ Storage buckets created (sources, audio, public-images)
- ✅ Proper access policies configured

## Step 3: N8N Configuration

To enable document processing and summaries:

### Get Your N8N Webhook URLs

1. **Document Processing Webhook**: Import `InsightsLM___Extract_Text.json`
2. **Additional Sources Webhook**: Import `InsightsLM___Process_Additional_Sources.json`
3. Get the webhook URL from each workflow's trigger node

### Set Environment Variables in Supabase

Go to: **Project Settings → Secrets → Environment Secrets**

Add these secrets:
```
DOCUMENT_PROCESSING_WEBHOOK_URL
your-n8n-domain.com/webhook/document-processing

ADDITIONAL_SOURCES_WEBHOOK_URL
your-n8n-domain.com/webhook/additional-sources

NOTEBOOK_GENERATION_AUTH
your-n8n-bearer-token-or-auth-header
```

## Step 4: Run the Application

```bash
npm run dev
```

The app will open at `http://localhost:5173`

## Step 5: Test the Full Workflow

### 1. Sign Up / Log In
- Click "Sign Up" or "Log In"
- Create an account with email/password
- Profile is auto-created in the database

### 2. Create a Notebook
- Click "New Notebook" on the dashboard
- Enter title (e.g., "My First Notebook")
- Click "Create"

### 3. Upload a Source
- Click "Add Sources" in the notebook
- Choose an option:

**Option A: Upload PDF**
- Drag & drop a PDF or click "Choose file"
- Wait for upload (shows "uploading" status)
- N8N processes and extracts text
- Brief summary appears (once N8N responds)

**Option B: Add Website URLs**
- Click "Link - Website"
- Paste multiple URLs
- Click "Add"
- N8N downloads and processes content

**Option C: Paste Text**
- Click "Paste Text - Copied Text"
- Paste your content
- Click "Add"
- N8N processes the text

### 4: Monitor Progress
- Each source shows status: pending → processing → completed
- Once completed, you'll see:
  - **Title**: Source name
  - **Summary**: AI-generated brief
  - **Content**: Full extracted text

## How It Works

```
┌─────────────────────────────────────────────┐
│          You (Browser/Frontend)             │
│ ✓ Create notebook                           │
│ ✓ Upload files / Add sources                │
│ ✓ View summaries & content                  │
└────────────┬────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────┐
│      Supabase Edge Functions (Free Tier)    │
│ • process-document                          │
│ • process-additional-sources                │
│ • process-document-callback                 │
└────────────┬────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────┐
│    N8N Webhooks (Your N8N Instance)        │
│ • Extract text from PDFs/Audio              │
│ • Download & parse websites                 │
│ • Generate summaries with AI                │
│ • Send results back via callback            │
└────────────┬────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────┐
│         Supabase Database                   │
│ ✓ Notebooks - your collections              │
│ ✓ Sources - uploaded/added documents        │
│ ✓ Summaries - AI-generated briefs           │
└─────────────────────────────────────────────┘
```

## Key Features

### ✅ Working Now
- **Notebooks**: Create, organize, delete
- **Source Upload**: PDF, TXT, Audio, Websites, Text
- **Database**: All data persists in Supabase
- **Authentication**: Secure sign up / login
- **RLS**: Your data is private to you
- **Storage**: Files stored in Supabase Storage

### ⚙️ Requires N8N Setup
- **Text Extraction**: PDF → text conversion
- **Summary Generation**: AI-powered briefs
- **Content Processing**: Automatic summarization
- **Metadata Extraction**: Title, author detection

## Troubleshooting

### "Error loading notebooks"
- Refresh the browser
- Check browser console for errors
- Verify you're logged in

### "File upload failed"
- Check file type (PDF, TXT, MP3, WAV, M4A)
- Max file size: 50MB
- Check browser console for upload errors

### "Processing stuck on pending"
- N8N webhook might not be configured
- Check Supabase secrets are set correctly
- Check N8N webhook URL is accessible
- Look at function logs in Supabase dashboard

### "No summary appearing"
- Wait 30 seconds (N8N processing takes time)
- Check N8N workflow is running
- Verify N8N webhook responses in logs
- Check callback URL is correct

## Next Steps

1. **Import N8N Workflows**
   - Go to your N8N instance
   - Import the JSON files from `/n8n` folder
   - Configure webhook URLs

2. **Customize**
   - Change notebook colors/icons
   - Add custom tags or categories
   - Create notebook templates

3. **Advanced Features**
   - Chat with sources
   - Generate podcast audio
   - Export as PDF/Markdown
   - Create quizzes from content

## Support

For detailed setup instructions, see: `SETUP_GUIDE.md`

For database schema details, see: `SETUP_GUIDE.md` → Database Schema section

## That's It! 🎉

You now have a fully functional notebook application with AI-powered document processing!

Start by:
1. Creating a notebook
2. Adding your first source
3. Watching the summary appear in real-time
