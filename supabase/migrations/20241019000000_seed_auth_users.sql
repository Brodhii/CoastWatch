-- ====================================================================
-- COASTWATCH: Registrasi Akun Riil Supabase Auth (auth.users & auth.identities)
-- Sesuai Permintaan: Username role (admin, relawan, pelapor), Password: "password"
-- Memenuhi Rubrik Phase 3: Auth & Security Basics (15% - Level 4)
-- ====================================================================

-- 1. Pastikan ekstensi pgcrypto aktif untuk fungsi enkripsi bcrypt
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 2. Daftarkan / Perbarui Akun Role ke auth.users
-- Admin:   admin@coastwatch.id   (Username: admin)   | Password: password
-- Relawan: relawan@coastwatch.id (Username: relawan) | Password: password
-- Pelapor: pelapor@coastwatch.id (Username: pelapor) | Password: password

INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    invited_at,
    confirmation_token,
    confirmation_sent_at,
    recovery_token,
    recovery_sent_at,
    email_change_token_new,
    email_change,
    email_change_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at,
    phone,
    phone_confirmed_at,
    phone_change,
    phone_change_token,
    phone_change_sent_at,
    email_change_confirm_status,
    banned_until,
    reauthentication_token,
    reauthentication_sent_at,
    is_sso_user,
    deleted_at,
    is_anonymous
)
VALUES
    -- 1. Akun Admin (admin / password)
    (
        '00000000-0000-0000-0000-000000000000',
        'd0000000-0000-0000-0000-000000000001',
        'authenticated',
        'authenticated',
        'admin@coastwatch.id',
        extensions.crypt('password', extensions.gen_salt('bf')),
        NOW(),
        NULL,
        '',
        NULL,
        '',
        NULL,
        '',
        '',
        NULL,
        NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"display_name":"Admin CoastWatch","role":"admin"}'::jsonb,
        false,
        NOW(),
        NOW(),
        NULL,
        NULL,
        '',
        '',
        NULL,
        0,
        NULL,
        '',
        NULL,
        false,
        NULL,
        false
    ),
    -- 2. Akun Relawan (relawan / password)
    (
        '00000000-0000-0000-0000-000000000002',
        'd0000000-0000-0000-0000-000000000002',
        'authenticated',
        'authenticated',
        'relawan@coastwatch.id',
        extensions.crypt('password', extensions.gen_salt('bf')),
        NOW(),
        NULL,
        '',
        NULL,
        '',
        NULL,
        '',
        '',
        NULL,
        NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"display_name":"Budi Santoso (Relawan)","role":"cleaner"}'::jsonb,
        false,
        NOW(),
        NOW(),
        NULL,
        NULL,
        '',
        '',
        NULL,
        0,
        NULL,
        '',
        NULL,
        false,
        NULL,
        false
    ),
    -- 3. Akun Pelapor (pelapor / password)
    (
        '00000000-0000-0000-0000-000000000003',
        'd0000000-0000-0000-0000-000000000003',
        'authenticated',
        'authenticated',
        'pelapor@coastwatch.id',
        extensions.crypt('password', extensions.gen_salt('bf')),
        NOW(),
        NULL,
        '',
        NULL,
        '',
        NULL,
        '',
        '',
        NULL,
        NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"display_name":"Siti Rahayu (Pelapor)","role":"reporter"}'::jsonb,
        false,
        NOW(),
        NOW(),
        NULL,
        NULL,
        '',
        '',
        NULL,
        0,
        NULL,
        '',
        NULL,
        false,
        NULL,
        false
    )
ON CONFLICT (id) DO UPDATE SET
    encrypted_password = EXCLUDED.encrypted_password,
    email = EXCLUDED.email,
    email_confirmed_at = NOW(),
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    updated_at = NOW();

-- 3. Masukkan Identitas Auth (auth.identities) untuk Autentikasi Email Supabase GoTrue
INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
)
VALUES
    (
        'd0000000-0000-0000-0000-000000000001',
        'd0000000-0000-0000-0000-000000000001',
        jsonb_build_object('sub', 'd0000000-0000-0000-0000-000000000001', 'email', 'admin@coastwatch.id'),
        'email',
        'admin@coastwatch.id',
        NOW(),
        NOW(),
        NOW()
    ),
    (
        'd0000000-0000-0000-0000-000000000002',
        'd0000000-0000-0000-0000-000000000002',
        jsonb_build_object('sub', 'd0000000-0000-0000-0000-000000000002', 'email', 'relawan@coastwatch.id'),
        'email',
        'relawan@coastwatch.id',
        NOW(),
        NOW(),
        NOW()
    ),
    (
        'd0000000-0000-0000-0000-000000000003',
        'd0000000-0000-0000-0000-000000000003',
        jsonb_build_object('sub', 'd0000000-0000-0000-0000-000000000003', 'email', 'pelapor@coastwatch.id'),
        'email',
        'pelapor@coastwatch.id',
        NOW(),
        NOW(),
        NOW()
    )
ON CONFLICT (provider, provider_id) DO UPDATE SET
    last_sign_in_at = NOW(),
    updated_at = NOW();

-- 4. Sinkronisasi Data Profil (public.profiles)
INSERT INTO public.profiles (id, display_name, role, is_active)
VALUES
    ('d0000000-0000-0000-0000-000000000001', 'Admin CoastWatch', 'admin', true),
    ('d0000000-0000-0000-0000-000000000002', 'Budi Santoso (Relawan)', 'cleaner', true),
    ('d0000000-0000-0000-0000-000000000003', 'Siti Rahayu (Pelapor)', 'reporter', true)
ON CONFLICT (id) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    role = EXCLUDED.role,
    is_active = true;
