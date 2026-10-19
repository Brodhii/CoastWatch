-- ====================================================================
-- COASTWATCH: Seed Data Master Kategori Pesisir
-- Mengacu pada desain.md Bab 10.1
-- ====================================================================

INSERT INTO public.report_categories (id, name, description, is_active, sort_order)
VALUES
    ('plastic', 'Sampah plastik', 'Botol, kantong kresek, kemasan sachet, styrofoam, dan fragmen plastik yang terlihat di pesisir.', true, 1),
    ('household', 'Sampah rumah tangga/campuran', 'Sampah campuran rumah tangga yang menumpuk di garis pantai atau muara sungai.', true, 2),
    ('fishing', 'Alat tangkap dan limbah perikanan', 'Jaring terbengkalai (ghost net), tali tambang kapal, pelampung, atau alat tangkap rusak.', true, 3),
    ('liquid', 'Limbah cair atau indikasi pencemaran', 'Lapisan minyak, buih mencurigakan, atau perubahan warna air laut yang mencolok.', true, 4),
    ('organic', 'Sampah organik', 'Tumpukan sisa tumbuhan, kayu gelondongan hanyut, atau bahan organik yang mengotori pantai.', true, 5),
    ('ecosystem', 'Kerusakan ekosistem pesisir', 'Indikasi kerusakan vegetasi mangrove, terumbu karang terdampar, atau abrasi abnormal.', true, 6),
    ('other', 'Lainnya', 'Masalah pesisir di luar kategori utama (wajib menyertakan deskripsi rinci).', true, 7)
ON CONFLICT (id) DO UPDATE 
SET 
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    sort_order = EXCLUDED.sort_order;
