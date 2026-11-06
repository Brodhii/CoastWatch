-- ====================================================================
-- COASTWATCH: Seed Data Master Kategori Pesisir (UUID)
-- Sesuai ERD Lampiran 2
-- ====================================================================

INSERT INTO public.report_categories (id, name, description, is_active)
VALUES
    ('c0000000-0000-0000-0000-000000000001', 'Sampah plastik', 'Botol, kantong kresek, kemasan sachet, styrofoam, dan fragmen plastik yang terlihat di pesisir.', true),
    ('c0000000-0000-0000-0000-000000000002', 'Sampah rumah tangga/campuran', 'Sampah campuran rumah tangga yang menumpuk di garis pantai atau muara sungai.', true),
    ('c0000000-0000-0000-0000-000000000003', 'Alat tangkap dan limbah perikanan', 'Jaring terbengkalai (ghost net), tali tambang kapal, pelampung, atau alat tangkap rusak.', true),
    ('c0000000-0000-0000-0000-000000000004', 'Limbah cair atau indikasi pencemaran', 'Lapisan minyak, buih mencurigakan, atau perubahan warna air laut yang mencolok.', true),
    ('c0000000-0000-0000-0000-000000000005', 'Sampah organik', 'Tumpukan sisa tumbuhan, kayu gelondongan hanyut, atau bahan organik yang mengotori pantai.', true),
    ('c0000000-0000-0000-0000-000000000006', 'Kerusakan ekosistem pesisir', 'Indikasi kerusakan vegetasi mangrove, terumbu karang terdampar, atau abrasi abnormal.', true),
    ('c0000000-0000-0000-0000-000000000007', 'Lainnya', 'Masalah pesisir di luar kategori utama (wajib menyertakan deskripsi rinci).', true)
ON CONFLICT (id) DO UPDATE 
SET 
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    is_active = EXCLUDED.is_active;
