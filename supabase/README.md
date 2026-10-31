# Supabase Database Migrations for CropGuard AI

This folder contains SQL migration scripts for the CropGuard AI project.

## How to Apply Migrations to Your Existing Supabase Project

1. Log in to your Supabase Dashboard: [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project: `cxzayeoqbocryekkqiyk`
3. In the left navigation bar, open the **SQL Editor**.
4. Click **New Query**.
5. Copy the contents of [`migrations/001_initial_schema.sql`](file:///c:/Users/Dell/Desktop/crop_guard/supabase/migrations/001_initial_schema.sql) and paste them into the SQL Editor.
6. Click **Run**.
7. Confirm that the following tables and storage buckets are visible in the **Table Editor** and **Storage**:
   - `profiles`
   - `pest_categories` (seeded with 6 target agricultural pests in English & Telugu)
   - `uploaded_images`
   - `predictions`
   - `detection_items`
   - Storage bucket: `cropguard-images`

## Safety Guarantee
- The migration uses `CREATE TABLE IF NOT EXISTS` and `ON CONFLICT DO UPDATE / DO NOTHING`.
- It **does not drop** any existing external tables or data.
- Row-Level Security (RLS) is enabled by default to protect user data privacy.
