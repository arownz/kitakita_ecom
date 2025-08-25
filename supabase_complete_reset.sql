-- ============================================================================
-- COMPLETE SUPABASE DATABASE RESET & RECONSTRUCTION SCRIPT
-- Run this script in Supabase SQL Editor to fix all authentication issues
-- ============================================================================

-- 1. DROP ALL EXISTING TABLES AND POLICIES (Clean Slate)
-- ============================================================================

-- Drop triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop functions
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.update_user_profile(uuid, text, text, text, text, text);
DROP FUNCTION IF EXISTS public.confirm_user_email(text, uuid);
DROP FUNCTION IF EXISTS public.send_verification_email(text, uuid);

-- Drop all policies
DO $$ 
DECLARE 
    pol RECORD;
BEGIN 
    FOR pol IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP 
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
    END LOOP;
END $$;

-- Drop storage policies
DO $$ 
DECLARE 
    pol RECORD;
BEGIN 
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects'
    LOOP 
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
    END LOOP;
END $$;

-- Drop all tables (in correct order due to foreign keys)
DROP TABLE IF EXISTS public.user_reviews CASCADE;
DROP TABLE IF EXISTS public.user_favorites CASCADE;
DROP TABLE IF EXISTS public.transactions CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.product_images CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.conversations CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;
DROP TABLE IF EXISTS public.categories CASCADE;

-- Drop storage bucket
DELETE FROM storage.objects WHERE bucket_id = 'profile-images';
DELETE FROM storage.buckets WHERE id = 'profile-images';
DELETE FROM storage.objects WHERE bucket_id = 'product-images';
DELETE FROM storage.buckets WHERE id = 'product-images';

-- 2. CREATE STORAGE BUCKETS
-- ============================================================================

-- Profile images bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-images',
    'profile-images',
    true,
    10485760, -- 10MB
    ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp']
);

-- Product images bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-images',
    'product-images',
    true,
    20971520, -- 20MB (larger for product photos)
    ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp']
);

-- 3. CREATE ALL TABLES
-- ============================================================================

-- Categories table
CREATE TABLE public.categories (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    description text,
    icon_name text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT NOW(),
    updated_at timestamptz DEFAULT NOW(),
    CONSTRAINT categories_pkey PRIMARY KEY (id)
);

-- User profiles table (MAIN TABLE FOR REGISTRATION DATA)
CREATE TABLE public.user_profiles (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid UNIQUE NOT NULL,
    student_id text UNIQUE,
    first_name text,
    last_name text,
    phone_number text,
    email text NOT NULL,
    role text DEFAULT 'student' CHECK (role IN ('student', 'admin')),
    is_verified boolean DEFAULT false,
    profile_image_url text,
    created_at timestamptz DEFAULT NOW(),
    updated_at timestamptz DEFAULT NOW(),
    CONSTRAINT user_profiles_pkey PRIMARY KEY (id),
    CONSTRAINT user_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Products table
CREATE TABLE public.products (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    seller_id uuid,
    category_id uuid,
    title text NOT NULL,
    description text NOT NULL,
    price numeric NOT NULL CHECK (price >= 0),
    condition text CHECK (condition IN ('new', 'like_new', 'good', 'fair', 'poor')),
    is_available boolean DEFAULT true,
    is_featured boolean DEFAULT false,
    location text,
    tags text[],
    images text[],
    view_count integer DEFAULT 0,
    favorite_count integer DEFAULT 0,
    created_at timestamptz DEFAULT NOW(),
    updated_at timestamptz DEFAULT NOW(),
    CONSTRAINT products_pkey PRIMARY KEY (id),
    CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id),
    CONSTRAINT products_seller_id_fkey FOREIGN KEY (seller_id) REFERENCES public.user_profiles(user_id)
);

-- Conversations table
CREATE TABLE public.conversations (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    buyer_id uuid,
    seller_id uuid,
    product_id uuid,
    last_message_at timestamptz DEFAULT NOW(),
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT NOW(),
    CONSTRAINT conversations_pkey PRIMARY KEY (id),
    CONSTRAINT conversations_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES public.user_profiles(user_id),
    CONSTRAINT conversations_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id),
    CONSTRAINT conversations_seller_id_fkey FOREIGN KEY (seller_id) REFERENCES public.user_profiles(user_id)
);

-- Messages table
CREATE TABLE public.messages (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    conversation_id uuid,
    sender_id uuid,
    content text NOT NULL,
    message_type text DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'system')),
    is_read boolean DEFAULT false,
    created_at timestamptz DEFAULT NOW(),
    CONSTRAINT messages_pkey PRIMARY KEY (id),
    CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id),
    CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.user_profiles(user_id)
);

-- Notifications table
CREATE TABLE public.notifications (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid,
    title text NOT NULL,
    message text NOT NULL,
    type text NOT NULL CHECK (type IN ('message', 'transaction', 'report', 'system', 'favorite')),
    data jsonb,
    is_read boolean DEFAULT false,
    created_at timestamptz DEFAULT NOW(),
    CONSTRAINT notifications_pkey PRIMARY KEY (id),
    CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(user_id)
);

-- Product images table
CREATE TABLE public.product_images (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    product_id uuid,
    image_url text NOT NULL,
    is_primary boolean DEFAULT false,
    alt_text text,
    sort_order integer DEFAULT 0,
    created_at timestamptz DEFAULT NOW(),
    CONSTRAINT product_images_pkey PRIMARY KEY (id),
    CONSTRAINT product_images_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);

-- Transactions table
CREATE TABLE public.transactions (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    product_id uuid,
    buyer_id uuid,
    seller_id uuid,
    amount numeric NOT NULL,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'cancelled')),
    payment_method text,
    meeting_location text,
    meeting_time timestamptz,
    notes text,
    created_at timestamptz DEFAULT NOW(),
    completed_at timestamptz,
    CONSTRAINT transactions_pkey PRIMARY KEY (id),
    CONSTRAINT transactions_seller_id_fkey FOREIGN KEY (seller_id) REFERENCES public.user_profiles(user_id),
    CONSTRAINT transactions_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES public.user_profiles(user_id),
    CONSTRAINT transactions_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);

-- User favorites table
CREATE TABLE public.user_favorites (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid,
    product_id uuid,
    created_at timestamptz DEFAULT NOW(),
    CONSTRAINT user_favorites_pkey PRIMARY KEY (id),
    CONSTRAINT user_favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(user_id),
    CONSTRAINT user_favorites_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);

-- Reports table
CREATE TABLE public.reports (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    reporter_id uuid,
    reported_user_id uuid,
    product_id uuid,
    report_type text NOT NULL CHECK (report_type IN ('scam', 'inappropriate_content', 'fake_product', 'harassment', 'spam', 'other')),
    description text NOT NULL,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    admin_notes text,
    resolved_by uuid,
    created_at timestamptz DEFAULT NOW(),
    resolved_at timestamptz,
    CONSTRAINT reports_pkey PRIMARY KEY (id),
    CONSTRAINT reports_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id),
    CONSTRAINT reports_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.user_profiles(user_id),
    CONSTRAINT reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.user_profiles(user_id),
    CONSTRAINT reports_reported_user_id_fkey FOREIGN KEY (reported_user_id) REFERENCES public.user_profiles(user_id)
);

-- User reviews table
CREATE TABLE public.user_reviews (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    reviewer_id uuid,
    reviewed_user_id uuid,
    transaction_id uuid,
    rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text text,
    created_at timestamptz DEFAULT NOW(),
    CONSTRAINT user_reviews_pkey PRIMARY KEY (id),
    CONSTRAINT user_reviews_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id),
    CONSTRAINT user_reviews_reviewed_user_id_fkey FOREIGN KEY (reviewed_user_id) REFERENCES public.user_profiles(user_id),
    CONSTRAINT user_reviews_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES public.user_profiles(user_id)
);

-- 4. CREATE RLS POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_reviews ENABLE ROW LEVEL SECURITY;

-- User profiles policies (CRITICAL FOR REGISTRATION)
CREATE POLICY "Anyone can view profiles" ON public.user_profiles FOR SELECT TO public USING (true);
CREATE POLICY "Users can create their own profile" ON public.user_profiles FOR INSERT TO public WITH CHECK (auth.uid() = user_id OR auth.uid() IS NULL);
CREATE POLICY "Users can update their own profile" ON public.user_profiles FOR UPDATE TO public USING (auth.uid() = user_id);

-- Categories policies
CREATE POLICY "Anyone can view categories" ON public.categories FOR SELECT TO public USING (true);

-- Products policies
CREATE POLICY "Anyone can view products" ON public.products FOR SELECT TO public USING (true);
CREATE POLICY "Authenticated users can create products" ON public.products FOR INSERT TO authenticated WITH CHECK (auth.uid() = seller_id);
CREATE POLICY "Users can update their own products" ON public.products FOR UPDATE TO authenticated USING (auth.uid() = seller_id);

-- Other table policies (basic setup)
CREATE POLICY "Users can view their conversations" ON public.conversations FOR SELECT TO authenticated USING (auth.uid() = buyer_id OR auth.uid() = seller_id);
CREATE POLICY "Users can create conversations" ON public.conversations FOR INSERT TO authenticated WITH CHECK (auth.uid() = buyer_id OR auth.uid() = seller_id);

CREATE POLICY "Users can view conversation messages" ON public.messages FOR SELECT TO authenticated USING (
    auth.uid() IN (
        SELECT buyer_id FROM public.conversations WHERE id = conversation_id
        UNION
        SELECT seller_id FROM public.conversations WHERE id = conversation_id
    )
);

-- 5. CREATE STORAGE POLICIES
-- ============================================================================

-- Profile images policies
CREATE POLICY "Anyone can view profile images" ON storage.objects FOR SELECT TO public USING (bucket_id = 'profile-images');
CREATE POLICY "Authenticated users can upload profile images" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'profile-images');
CREATE POLICY "Users can update their profile images" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'profile-images');
CREATE POLICY "Users can delete their profile images" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'profile-images');

-- Product images policies
CREATE POLICY "Anyone can view product images" ON storage.objects FOR SELECT TO public USING (bucket_id = 'product-images');
CREATE POLICY "Authenticated users can upload product images" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'product-images');
CREATE POLICY "Users can update their product images" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'product-images' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Users can delete their product images" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'product-images' AND (storage.foldername(name))[1] = auth.uid()::text);

-- 6. CREATE FUNCTIONS
-- ============================================================================

-- Function to auto-create user profile when auth user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.user_profiles (
        user_id, 
        email, 
        role, 
        is_verified,
        created_at, 
        updated_at
    )
    VALUES (
        NEW.id, 
        NEW.email, 
        'student', 
        false,
        NOW(), 
        NOW()
    );
    RETURN NEW;
EXCEPTION
    WHEN others THEN
        -- Log error but don't fail the user creation
        RAISE WARNING 'Failed to create user profile for %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to safely update user profile (FIXED VERSION)
CREATE OR REPLACE FUNCTION public.update_user_profile(
    p_user_id uuid,
    p_student_id text DEFAULT NULL,
    p_first_name text DEFAULT NULL,
    p_last_name text DEFAULT NULL,
    p_phone_number text DEFAULT NULL,
    p_profile_image_url text DEFAULT NULL
)
RETURNS json AS $$
DECLARE
    result_record RECORD;
BEGIN
    -- Update the user profile with provided data
    UPDATE public.user_profiles 
    SET 
        student_id = COALESCE(p_student_id, student_id),
        first_name = COALESCE(p_first_name, first_name),
        last_name = COALESCE(p_last_name, last_name),
        phone_number = COALESCE(p_phone_number, phone_number),
        profile_image_url = COALESCE(p_profile_image_url, profile_image_url),
        updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING * INTO result_record;

    -- Check if update was successful
    IF result_record.user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User profile not found',
            'user_id', p_user_id
        );
    END IF;

    -- Return success with updated data
    RETURN json_build_object(
        'success', true,
        'data', row_to_json(result_record)
    );

EXCEPTION
    WHEN others THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'user_id', p_user_id
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Email confirmation function
CREATE OR REPLACE FUNCTION public.confirm_user_email(
    user_email text,
    user_uuid uuid DEFAULT NULL
)
RETURNS json AS $$
DECLARE
    target_user_id uuid;
BEGIN
    -- Find user by email if UUID not provided
    IF user_uuid IS NULL THEN
        SELECT id INTO target_user_id 
        FROM auth.users 
        WHERE email = user_email;
    ELSE
        target_user_id := user_uuid;
    END IF;

    -- Update verification status
    UPDATE public.user_profiles 
    SET is_verified = true, updated_at = NOW() 
    WHERE user_id = target_user_id;

    RETURN json_build_object(
        'success', true,
        'message', 'Email confirmed successfully',
        'user_id', target_user_id
    );

EXCEPTION
    WHEN others THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Send verification email function
CREATE OR REPLACE FUNCTION public.send_verification_email(
    user_email text,
    user_uuid uuid DEFAULT NULL
)
RETURNS json AS $$
BEGIN
    -- This is a placeholder - implement actual email sending logic here
    RETURN json_build_object(
        'success', true,
        'message', 'Verification email sent',
        'email', user_email
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. CREATE TRIGGERS
-- ============================================================================

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 8. INSERT SAMPLE DATA
-- ============================================================================

-- Insert sample categories
INSERT INTO public.categories (name, description, icon_name) VALUES
    ('Electronics', 'Phones, laptops, gadgets', 'devices'),
    ('Books', 'Textbooks, novels, study materials', 'book'),
    ('Clothing', 'Shirts, pants, shoes, accessories', 'shirt'),
    ('Sports', 'Equipment, gear, apparel', 'fitness'),
    ('Food', 'Snacks, beverages, meal plans', 'restaurant'),
    ('Services', 'Tutoring, delivery, odd jobs', 'build'),
    ('Other', 'Miscellaneous items', 'category');

-- ============================================================================
-- SCRIPT COMPLETE
-- ============================================================================

-- Verify setup
SELECT 'Database setup completed successfully!' as status;
SELECT COUNT(*) as category_count FROM public.categories;
SELECT 'RLS enabled on user_profiles: ' || (SELECT TRUE FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_profiles' AND rowsecurity = true) as rls_status;
