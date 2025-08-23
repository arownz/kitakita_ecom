-- Fix infinite recursion in user_profiles RLS policies
-- Run this in your Supabase SQL Editor

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can read all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON user_profiles;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON user_profiles;

-- Create simpler, non-recursive policies
CREATE POLICY "Public read access to user profiles" ON user_profiles
FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON user_profiles
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON user_profiles
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Ensure RLS is enabled
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Also fix any potential issues with products table
DROP POLICY IF EXISTS "Users can view available products" ON products;
DROP POLICY IF EXISTS "Users can insert own products" ON products;
DROP POLICY IF EXISTS "Users can update own products" ON products;

CREATE POLICY "Public read access to products" ON products
FOR SELECT USING (true);

CREATE POLICY "Users can insert own products" ON products
FOR INSERT WITH CHECK (auth.uid() = seller_id);

CREATE POLICY "Users can update own products" ON products
FOR UPDATE USING (auth.uid() = seller_id);

-- Enable RLS on products
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Create a test user with unverified email for testing
-- (You can skip this if you don't want a test user)
-- INSERT INTO auth.users (id, email, email_confirmed_at, created_at, updated_at, raw_user_meta_data)
-- VALUES (
--   gen_random_uuid(),
--   'test@example.com', 
--   NULL, -- Unverified email
--   now(),
--   now(),
--   '{"first_name": "Test", "last_name": "User"}'::jsonb
-- );
