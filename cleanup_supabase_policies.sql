-- Complete cleanup and reset of RLS policies
-- Run this in your Supabase SQL Editor to clean up all duplicate policies

-- === USER_PROFILES TABLE CLEANUP ===
-- Drop ALL existing policies on user_profiles
DROP POLICY IF EXISTS "admin_all_access_profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can delete profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "allow_insert_own_profile" ON user_profiles;
DROP POLICY IF EXISTS "allow_select_own_profile" ON user_profiles;
DROP POLICY IF EXISTS "allow_update_own_profile" ON user_profiles;
DROP POLICY IF EXISTS "Public read access to user profiles" ON user_profiles;
DROP POLICY IF EXISTS "user_profiles_insert_policy" ON user_profiles;
DROP POLICY IF EXISTS "user_profiles_select_policy" ON user_profiles;
DROP POLICY IF EXISTS "user_profiles_update_policy" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can read all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON user_profiles;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON user_profiles;

-- Create clean, simple policies for user_profiles
CREATE POLICY "Anyone can read user profiles" ON user_profiles
FOR SELECT USING (true);

CREATE POLICY "Users can create their own profile" ON user_profiles
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON user_profiles
FOR UPDATE USING (auth.uid() = user_id);

-- === PRODUCTS TABLE CLEANUP ===
-- Drop existing policies on products
DROP POLICY IF EXISTS "Users can view available products" ON products;
DROP POLICY IF EXISTS "Users can insert own products" ON products;
DROP POLICY IF EXISTS "Users can update own products" ON products;
DROP POLICY IF EXISTS "Public read access to products" ON products;

-- Create clean policies for products
CREATE POLICY "Anyone can read products" ON products
FOR SELECT USING (true);

CREATE POLICY "Users can create their own products" ON products
FOR INSERT WITH CHECK (auth.uid() = seller_id);

CREATE POLICY "Users can update their own products" ON products
FOR UPDATE USING (auth.uid() = seller_id);

-- === STORAGE POLICIES CLEANUP ===
-- Note: Storage policies might need to be cleaned manually in the Storage section

-- === ENABLE RLS ===
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- === VERIFY POLICIES ===
-- Run this to see the current policies after cleanup:
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
-- FROM pg_policies 
-- WHERE tablename IN ('user_profiles', 'products') 
-- ORDER BY tablename, policyname;
