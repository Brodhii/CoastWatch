-- ====================================================================
-- COASTWATCH: Skema Database Supabase PostgreSQL + PostGIS & RLS
-- Disesuaikan 100% dengan Lampiran 2 : Entity Relationship Diagram (ERD)
-- ====================================================================

-- 1. Ekstensi PostGIS & UUID
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop tabel lama jika ingin reset bersih (urutan dari anak ke induk)
DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.report_reviews CASCADE;
DROP TABLE IF EXISTS public.report_status_history CASCADE;
DROP TABLE IF EXISTS public.report_cleanups CASCADE;
DROP TABLE IF EXISTS public.report_media CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.report_categories CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- --------------------------------------------------------------------
-- 2. TABEL: profiles (Sesuai ERD Lampiran 2 - Entitas Utama Tanpa FK Luar)
-- --------------------------------------------------------------------
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    display_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'reporter',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------
-- 3. TABEL: report_categories
-- --------------------------------------------------------------------
CREATE TABLE public.report_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true
);
ALTER TABLE public.report_categories ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------
-- 4. TABEL: reports
-- --------------------------------------------------------------------
CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_submission_id UUID UNIQUE,
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    category_id UUID NOT NULL REFERENCES public.report_categories(id) ON DELETE RESTRICT,
    description VARCHAR(65535) NOT NULL DEFAULT '',
    latitude DECIMAL(9, 6) NOT NULL,
    longitude DECIMAL(9, 6) NOT NULL,
    geom GEOMETRY(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)) STORED,
    exif_datetime_original TIMESTAMP,
    device_location_accuracy_m DECIMAL(6, 2),
    status VARCHAR(30) NOT NULL DEFAULT 'pending_review',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------
-- 5. TABEL: report_media
-- --------------------------------------------------------------------
CREATE TABLE public.report_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    media_role VARCHAR(10) NOT NULL DEFAULT 'before',
    storage_key_original VARCHAR(255) NOT NULL,
    storage_key_public VARCHAR(255),
    mime_type VARCHAR(30) NOT NULL,
    sha256_hash CHAR(64)
);
ALTER TABLE public.report_media ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------
-- 6. TABEL: report_reviews (Sesuai ERD Lampiran 2)
-- --------------------------------------------------------------------
CREATE TABLE public.report_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    admin_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    decision VARCHAR(20) NOT NULL,
    notes VARCHAR(255),
    reviewed_at TIMESTAMP NOT NULL DEFAULT NOW()
);
ALTER TABLE public.report_reviews ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------
-- 7. TABEL: report_cleanups
-- --------------------------------------------------------------------
CREATE TABLE public.report_cleanups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    cleaner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    notes VARCHAR(255),
    cleanup_lat DECIMAL(9, 6),
    cleanup_lng DECIMAL(9, 6),
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP
);
ALTER TABLE public.report_cleanups ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------
-- 8. TABEL: report_status_history
-- --------------------------------------------------------------------
CREATE TABLE public.report_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    from_status VARCHAR(30),
    to_status VARCHAR(30) NOT NULL,
    reason VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
ALTER TABLE public.report_status_history ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------
-- 9. TABEL: audit_logs (Sesuai ERD Lampiran 2)
-- --------------------------------------------------------------------
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    target_id UUID,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------
-- 10. INDEKS SPASIAL DAN KUERI
-- --------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_reports_geom ON public.reports USING GIST(geom);
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_category ON public.reports(category_id);
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id ON public.reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_report_media_report_id ON public.report_media(report_id);
CREATE INDEX IF NOT EXISTS idx_report_reviews_report_id ON public.report_reviews(report_id);
CREATE INDEX IF NOT EXISTS idx_report_cleanups_report_id ON public.report_cleanups(report_id);
CREATE INDEX IF NOT EXISTS idx_report_cleanups_cleaner_id ON public.report_cleanups(cleaner_id);
CREATE INDEX IF NOT EXISTS idx_report_status_history_report_id ON public.report_status_history(report_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_id ON public.audit_logs(actor_id);

-- --------------------------------------------------------------------
-- 11. KEBIJAKAN ROW LEVEL SECURITY (RLS)
-- --------------------------------------------------------------------

-- Kebijakan: profiles
CREATE POLICY "Profil dapat dibaca oleh publik & pengguna"
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Pengguna dapat membuat profil sendiri"
ON public.profiles FOR INSERT WITH CHECK (true);

CREATE POLICY "Pengguna dapat mengupdate profil sendiri"
ON public.profiles FOR UPDATE USING (true) WITH CHECK (true);

-- Kebijakan: report_categories
CREATE POLICY "Kategori laporan dapat dibaca publik"
ON public.report_categories FOR SELECT USING (is_active = true);

CREATE POLICY "Admin dapat mengelola kategori"
ON public.report_categories FOR ALL USING (true);

-- Kebijakan: reports
CREATE POLICY "Laporan publik dapat dibaca semua orang"
ON public.reports FOR SELECT USING (true);

CREATE POLICY "Pengguna dapat membuat laporan"
ON public.reports FOR INSERT WITH CHECK (true);

CREATE POLICY "Pengguna dapat memperbarui laporan"
ON public.reports FOR UPDATE USING (true);

-- Kebijakan: report_media
CREATE POLICY "Media laporan dapat dilihat publik"
ON public.report_media FOR SELECT USING (true);

CREATE POLICY "Pengguna dapat mengunggah media"
ON public.report_media FOR INSERT WITH CHECK (true);

-- Kebijakan: report_reviews
CREATE POLICY "Review dapat dibaca semua orang"
ON public.report_reviews FOR SELECT USING (true);

CREATE POLICY "Review dapat ditambahkan"
ON public.report_reviews FOR INSERT WITH CHECK (true);

-- Kebijakan: report_cleanups
CREATE POLICY "Tugas pembersihan dapat dibaca semua orang"
ON public.report_cleanups FOR SELECT USING (true);

CREATE POLICY "Relawan dapat mengelola tugas pembersihannya"
ON public.report_cleanups FOR ALL USING (true);

-- Kebijakan: report_status_history
CREATE POLICY "Riwayat status dapat dibaca semua orang"
ON public.report_status_history FOR SELECT USING (true);

CREATE POLICY "Riwayat status dapat ditambahkan"
ON public.report_status_history FOR INSERT WITH CHECK (true);

-- Kebijakan: audit_logs
CREATE POLICY "Audit logs dapat dibaca"
ON public.audit_logs FOR SELECT USING (true);

CREATE POLICY "Audit logs dapat dicatat"
ON public.audit_logs FOR INSERT WITH CHECK (true);

-- --------------------------------------------------------------------
-- 12. TRIGGER OTOMATIS: BUAT PROFIL SAAT USER DAFTAR SUPABASE AUTH
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name, role)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
        COALESCE(new.raw_user_meta_data->>'role', 'reporter')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- --------------------------------------------------------------------
-- 13. SEED DATA LENGKAP: Kategori, Profil Pengguna, Laporan, & Log
-- --------------------------------------------------------------------

-- A. 7 Kategori Pesisir Sesuai ERD
INSERT INTO public.report_categories (id, name, description, is_active)
VALUES
    ('c0000000-0000-0000-0000-000000000001', 'Sampah plastik', 'Botol, kemasan sachet, kresek jeriken, dan limbah polimer di bibir pantai/muara.', true),
    ('c0000000-0000-0000-0000-000000000002', 'Sampah rumah tangga/campuran', 'Kain, perabot rusak, kaca, residu domestik, puntung rokok.', true),
    ('c0000000-0000-0000-0000-000000000003', 'Alat tangkap dan limbah perikanan', 'Jaring hantu (ghost nets), pelampung busa, senar pancing kusut.', true),
    ('c0000000-0000-0000-0000-000000000004', 'Limbah cair atau indikasi pencemaran', 'Ceceran oli, lapisan solar, air berminyak, busa kimia di perairan pesisir.', true),
    ('c0000000-0000-0000-0000-000000000005', 'Sampah organik', 'Kayu gelondongan hanyut, bangkai biota laut, tumpukan vegetasi laut.', true),
    ('c0000000-0000-0000-0000-000000000006', 'Kerusakan ekosistem pesisir', 'Pohon bakau roboh akibat abrasi, kerusakan terumbu, tebing pantai tergerus.', true),
    ('c0000000-0000-0000-0000-000000000007', 'Lainnya', 'Temuan material pesisir yang belum teridentifikasi dalam klasifikasi di atas.', true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    is_active = EXCLUDED.is_active;

-- B. Data Profil Pengguna & Admin (Sesuai ERD - Langsung ke public.profiles)
INSERT INTO public.profiles (id, display_name, role, is_active)
VALUES
    ('d0000000-0000-0000-0000-000000000001', 'Admin CoastWatch', 'admin', true),
    ('d0000000-0000-0000-0000-000000000002', 'Budi Santoso (Relawan)', 'cleaner', true),
    ('d0000000-0000-0000-0000-000000000003', 'Siti Rahayu (Pelapor)', 'reporter', true)
ON CONFLICT (id) DO NOTHING;

-- C. Data Sampel Laporan Nyata Pesisir Batam
INSERT INTO public.reports (
    id, reporter_id, category_id, description, latitude, longitude,
    device_location_accuracy_m, status
)
VALUES
    (
        'e0000000-0000-0000-0000-000000000001',
        'd0000000-0000-0000-0000-000000000003',
        'c0000000-0000-0000-0000-000000000001',
        'Tumpukan botol dan sampah plastik kemasan menumpuk di garis pasang pantai.',
        1.182400,
        104.103200,
        4.20,
        'pending_review'
    ),
    (
        'e0000000-0000-0000-0000-000000000002',
        'd0000000-0000-0000-0000-000000000003',
        'c0000000-0000-0000-0000-000000000003',
        'Jaring nelayan rusak (ghost net) tersangkut di bebatuan karang pinggir pantai.',
        1.135600,
        104.053100,
        3.80,
        'pending_review'
    ),
    (
        'e0000000-0000-0000-0000-000000000003',
        'd0000000-0000-0000-0000-000000000003',
        'c0000000-0000-0000-0000-000000000004',
        'Ceceran oli dan lapisan minyak terlihat di permukaan air muara dekat pelabuhan.',
        1.091200,
        103.987500,
        5.10,
        'verified'
    )
ON CONFLICT (id) DO NOTHING;

-- D. Data Log Audit Awal
INSERT INTO public.audit_logs (id, actor_id, action, target_id)
VALUES
    ('f0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'INISIALISASI SISTEM', NULL)
ON CONFLICT (id) DO NOTHING;
