-- ====================================================================
-- COASTWATCH: Skema Database Supabase PostgreSQL + PostGIS & RLS
-- Mengacu pada desain.md & struktur-folder.md
-- ====================================================================

-- 1. Aktifkan Ekstensi PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. ENUM Tipe Data
CREATE TYPE user_role AS ENUM ('reporter', 'cleaner', 'admin');
CREATE TYPE report_status AS ENUM (
    'pending_review',
    'verified',
    'in_progress',
    'cleaned',
    'rejected',
    'duplicate'
);
CREATE TYPE media_role AS ENUM ('before', 'after');

-- 3. Tabel Profiles (Terhubung ke Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'reporter',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Tabel Kategori Laporan (Master Data)
CREATE TABLE IF NOT EXISTS public.report_categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Tabel Laporan (Reports)
CREATE TABLE IF NOT EXISTS public.reports (
    id TEXT PRIMARY KEY,
    client_submission_id UUID UNIQUE,
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    category_id TEXT NOT NULL REFERENCES public.report_categories(id) ON DELETE RESTRICT,
    description TEXT NOT NULL DEFAULT '',
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    geom GEOMETRY(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)) STORED,
    location_name TEXT,
    exif_datetime_original TIMESTAMPTZ,
    device_location_accuracy_m NUMERIC(6, 2),
    metadata_validation_status TEXT NOT NULL DEFAULT 'valid',
    status report_status NOT NULL DEFAULT 'pending_review',
    duplicate_of TEXT REFERENCES public.reports(id) ON DELETE SET NULL,
    visibility TEXT NOT NULL DEFAULT 'public',
    rejection_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Tabel Media Laporan (Report Media: Before & After)
CREATE TABLE IF NOT EXISTS public.report_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id TEXT NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    media_role media_role NOT NULL DEFAULT 'before',
    storage_key_original TEXT NOT NULL,
    storage_key_public TEXT,
    file_size_bytes INT NOT NULL,
    mime_type TEXT NOT NULL,
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    exif_datetime_original TIMESTAMPTZ,
    uploaded_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Tabel Tugas Pembersihan Relawan (Report Cleanups)
CREATE TABLE IF NOT EXISTS public.report_cleanups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id TEXT NOT NULL UNIQUE REFERENCES public.reports(id) ON DELETE CASCADE,
    cleaner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    notes TEXT,
    cleanup_lat NUMERIC(10, 7),
    cleanup_lng NUMERIC(10, 7),
    cleanup_exif_datetime_original TIMESTAMPTZ,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'in_progress',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Tabel Riwayat Status (Audit Trail)
CREATE TABLE IF NOT EXISTS public.report_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id TEXT NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    from_status report_status,
    to_status report_status NOT NULL,
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    actor_name TEXT,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. Indeks Spasial & Kueri
CREATE INDEX IF NOT EXISTS idx_reports_geom ON public.reports USING GIST(geom);
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_category ON public.reports(category_id);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports(created_at DESC);

-- 10. Fungsi Query Peta Publik (Hanya Verified & Tanpa Identitas Pelapor)
CREATE OR REPLACE FUNCTION get_public_map_reports(
    min_lat NUMERIC,
    min_lng NUMERIC,
    max_lat NUMERIC,
    max_lng NUMERIC,
    cat_id TEXT DEFAULT NULL
)
RETURNS TABLE (
    id TEXT,
    category_id TEXT,
    category_name TEXT,
    latitude NUMERIC,
    longitude NUMERIC,
    location_name TEXT,
    created_at TIMESTAMPTZ,
    status report_status
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        r.category_id,
        c.name AS category_name,
        r.latitude,
        r.longitude,
        r.location_name,
        r.created_at,
        r.status
    FROM public.reports r
    JOIN public.report_categories c ON r.category_id = c.id
    WHERE r.status = 'verified'
      AND r.visibility = 'public'
      AND r.latitude BETWEEN min_lat AND max_lat
      AND r.longitude BETWEEN min_lng AND max_lng
      AND (cat_id IS NULL OR r.category_id = cat_id);
END;
$$;

-- 11. Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_cleanups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_status_history ENABLE ROW LEVEL SECURITY;

-- Kebijakan Baca Publik: Hanya laporan terverifikasi yang dapat dibaca umum
CREATE POLICY "Laporan publik terverifikasi dapat dibaca semua orang"
ON public.reports FOR SELECT
USING (status = 'verified' AND visibility = 'public');

-- Kebijakan Pelapor: Dapat membaca dan mengelola laporan miliknya sendiri
CREATE POLICY "Pelapor dapat membaca laporan sendiri"
ON public.reports FOR SELECT
TO authenticated
USING (reporter_id = auth.uid());
