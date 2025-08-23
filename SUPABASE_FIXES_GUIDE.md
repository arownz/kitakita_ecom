# 🔧 Supabase Database Fixes Guide

## 🚨 Critical: Fix RLS Policy Conflicts

You currently have **multiple duplicate policies** that are causing conflicts. Follow these steps:

### Step 1: Clean Up All Policies

1. **Open Supabase Dashboard** → Your Project → **SQL Editor**
2. **Run the script** `cleanup_supabase_policies.sql`
3. **Wait for completion** (should take ~30 seconds)

### Step 2: Verify Clean Policies

After running the cleanup, you should have **only these policies**:

#### user_profiles table:

- ✅ `Anyone can read user profiles` (SELECT)
- ✅ `Users can create their own profile` (INSERT)
- ✅ `Users can update their own profile` (UPDATE)

#### products table:

- ✅ `Anyone can read products` (SELECT)
- ✅ `Users can create their own products` (INSERT)
- ✅ `Users can update their own products` (UPDATE)

## 📧 Testing Email Verification Banner

### Why the banner doesn't show:

Your account is **already verified** (`emailConfirmedAt: 2025-08-22T10:05:34.384023Z`)

### To test the verification banner:

#### Option 1: Create New Unverified Account

1. **Register** with a new email
2. **Don't click** the verification link
3. **Login** - you should see the banner

#### Option 2: Unverify Current Account (SQL)

```sql
UPDATE auth.users
SET email_confirmed_at = NULL
WHERE email = 'pasionhf@students.nu-dasma.edu.ph';
```

## 🔍 Expected Results After Fixes

### ✅ Database Issues Fixed:

- ❌ No more "infinite recursion detected"
- ❌ No more profile creation errors
- ✅ User profiles load correctly
- ✅ Products display properly

### ✅ UI Issues Fixed:

- ❌ No more RenderFlex overflow errors
- ✅ Sidebar navigation works smoothly
- ✅ All layouts are responsive

### ✅ Authentication Fixed:

- ✅ Logout redirects to landing page
- ✅ Auth state clears completely
- ✅ User data disappears after logout
- ✅ Email verification banner works for unverified users

## 🧪 Testing Checklist

After running the SQL cleanup, test these:

- [ ] **Login** → Should go to home page
- [ ] **Logout** → Should go to landing page
- [ ] **Profile page** → Should load without errors
- [ ] **Add product** → Should work without RLS errors
- [ ] **Navigate between pages** → No overflow errors
- [ ] **Sidebar** → Should expand/collapse smoothly

## 📝 Storage Policies (Manual Cleanup)

If you still have storage issues, manually check:

### Supabase Dashboard → Storage → Policies

Should have **only these** for each bucket:

#### product_images:

- Anyone can view product images (SELECT)
- Users can upload own product images (INSERT)
- Users can update own product images (UPDATE)
- Users can delete own product images (DELETE)

#### profile_images:

- Anyone can view profile images (SELECT)
- Users can upload own profile images (INSERT)
- Users can update own profile images (UPDATE)
- Users can delete own profile images (DELETE)

## 🔧 Emergency Reset (If Issues Persist)

If problems continue after cleanup:

```sql
-- Nuclear option: Disable RLS temporarily
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;

-- Test the app - it should work without RLS
-- Then re-enable with clean policies
```

## 📞 Need Help?

If issues persist after these fixes:

1. Check the **browser console** for specific errors
2. Check **Supabase logs** in the dashboard
3. **Take screenshots** of any remaining errors
4. **Share the specific error messages**

The app should work perfectly after running the cleanup script! 🎉
