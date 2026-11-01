# Supabase Database & Auth Configuration for CropGuard AI

This folder contains SQL migration scripts and configuration guides for the CropGuard AI project.

## 1. How to Apply Migrations to Your Supabase Project

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

---

## 2. Supabase Auth Deep Linking & Password Recovery Configuration (URGENT)

To ensure the password recovery email properly opens the CropGuard AI Android mobile app instead of redirecting to `localhost`, configure these two settings in the Supabase Dashboard:

### A. Add Android Deep Link to Redirect URLs
1. In the Supabase Dashboard, go to **Authentication** -> **URL Configuration**.
2. Under **Redirect URLs**, click **Add URL**.
3. Add the exact Android app deep link:
   ```text
   com.cropguard.ai://reset-password
   ```
   *(Optional: You can also add wildcard `com.cropguard.ai://*` to cover all future deep links).*
4. Click **Save**.

> **Note:** If this URL is not in the Redirect URLs allowlist, Supabase security automatically rejects the mobile redirect and falls back to `Site URL` (`http://localhost...`), which causes the "localhost refused to connect" error on mobile phones.

### B. Verify Reset Password Email Template
1. In the Supabase Dashboard, navigate to **Authentication** -> **Email Templates** -> **Reset Password**.
2. Ensure the link points to `{{ .ConfirmationURL }}` (the Supabase confirmation URL which embeds the mobile redirect parameter), **not** `{{ .SiteURL }}`.
3. Recommended template body:
   ```html
   <h2>Reset Your CropGuard AI Password</h2>
   <p>Follow this link to set a new password for your CropGuard AI account:</p>
   <p><a href="{{ .ConfirmationURL }}">Reset Password</a></p>
   <p>If you did not request this, please ignore this email.</p>
   ```
4. Click **Save Changes**.

---

## 3. Safety Guarantee
- The migration uses `CREATE TABLE IF NOT EXISTS` and `ON CONFLICT DO UPDATE / DO NOTHING`.
- It **does not drop** any existing external tables or data.
- Row-Level Security (RLS) is enabled by default to protect user data privacy.
