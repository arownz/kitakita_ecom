-- KitaKita E-Commerce Database Schema - SIMPLIFIED VERSION
-- Run this in your Supabase SQL Editor to fix the recursion issues

-- Drop existing policies to start fresh
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can delete profiles" ON user_profiles;

-- Create a function to check if user is admin (avoids recursion)
CREATE OR REPLACE FUNCTION is_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE user_id = user_uuid AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate user_profiles policies without recursion
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = auth.uid());

-- Admin policies using the function
CREATE POLICY "Admins can view all profiles" ON user_profiles
    FOR SELECT USING (is_admin(auth.uid()));

CREATE POLICY "Admins can update all profiles" ON user_profiles
    FOR UPDATE USING (is_admin(auth.uid()));

CREATE POLICY "Admins can delete profiles" ON user_profiles
    FOR DELETE USING (is_admin(auth.uid()));

-- Fix other admin policies
DROP POLICY IF EXISTS "Admins can manage all products" ON products;
CREATE POLICY "Admins can manage all products" ON products
    FOR ALL USING (is_admin(auth.uid()));

DROP POLICY IF EXISTS "Admins can manage all reports" ON reports;
CREATE POLICY "Admins can manage all reports" ON reports
    FOR ALL USING (is_admin(auth.uid()));

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON user_profiles TO authenticated;
GRANT ALL ON products TO authenticated;
GRANT ALL ON categories TO authenticated;
GRANT ALL ON user_favorites TO authenticated;
GRANT ALL ON conversations TO authenticated;
GRANT ALL ON messages TO authenticated;
GRANT ALL ON reports TO authenticated;
GRANT ALL ON notifications TO authenticated;
GRANT ALL ON user_reviews TO authenticated;
GRANT ALL ON transactions TO authenticated;
