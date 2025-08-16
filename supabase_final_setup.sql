-- Final Supabase setup for KitaKita ecommerce
-- Run this in Supabase SQL Editor to fix all auth and RLS issues

-- 1. Drop existing policies to start fresh
DROP POLICY IF EXISTS "insert_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "select_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;

-- 2. Create simple, working RLS policies
CREATE POLICY "allow_insert_own_profile" ON public.user_profiles
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "allow_select_own_profile" ON public.user_profiles
  FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "allow_update_own_profile" ON public.user_profiles
  FOR UPDATE 
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 3. Admin access policies
CREATE POLICY "admin_all_access_profiles" ON public.user_profiles
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles up 
      WHERE up.user_id = auth.uid() AND up.role = 'admin'
    )
  );

-- 4. Auto-create profile trigger (improved)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (
    user_id,
    email,
    role,
    is_verified,
    student_id,
    first_name,
    last_name,
    phone_number
  ) VALUES (
    NEW.id,
    NEW.email,
    'student',
    false,
    COALESCE(NEW.raw_user_meta_data->>'student_id', ''),
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone_number', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.user_profiles TO authenticated;
GRANT ALL ON public.categories TO authenticated;
GRANT ALL ON public.products TO authenticated;
GRANT ALL ON public.product_images TO authenticated;
GRANT ALL ON public.user_favorites TO authenticated;
GRANT ALL ON public.conversations TO authenticated;
GRANT ALL ON public.messages TO authenticated;
GRANT ALL ON public.transactions TO authenticated;
GRANT ALL ON public.reports TO authenticated;
GRANT ALL ON public.user_reviews TO authenticated;

-- 7. Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_reviews ENABLE ROW LEVEL SECURITY;

-- 8. Basic policies for other tables
-- Categories (everyone can read, admin can manage)
CREATE POLICY "allow_read_categories" ON public.categories
  FOR SELECT USING (true);

-- Products (everyone can read, users can manage their own)
CREATE POLICY "allow_read_products" ON public.products
  FOR SELECT USING (true);

CREATE POLICY "allow_insert_own_products" ON public.products
  FOR INSERT WITH CHECK (auth.uid() = seller_id);

CREATE POLICY "allow_update_own_products" ON public.products
  FOR UPDATE USING (auth.uid() = seller_id);

CREATE POLICY "allow_delete_own_products" ON public.products
  FOR DELETE USING (auth.uid() = seller_id);

-- User favorites
CREATE POLICY "allow_manage_own_favorites" ON public.user_favorites
  FOR ALL USING (auth.uid() = user_id);

-- Messages and conversations (users can access their own)
CREATE POLICY "allow_own_conversations" ON public.conversations
  FOR ALL USING (
    auth.uid() = buyer_id OR auth.uid() = seller_id
  );

CREATE POLICY "allow_own_messages" ON public.messages
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.conversations c 
      WHERE c.id = conversation_id 
      AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
  );

-- Insert some default categories
INSERT INTO public.categories (name, description) VALUES
  ('Textbooks', 'Academic books and study materials'),
  ('Electronics', 'Gadgets, laptops, and tech accessories'),
  ('Clothing', 'Apparel and fashion items'),
  ('School Supplies', 'Stationery, notebooks, and supplies'),
  ('Sports', 'Sports equipment and gear'),
  ('Food & Drinks', 'Snacks, beverages, and meal deals')
ON CONFLICT (name) DO NOTHING;
