-- ====================================================================
-- COASTWATCH: Kebijakan RLS DELETE untuk Menghapus Laporan (CRUD: Delete)
-- ====================================================================

-- 1. Kebijakan DELETE untuk tabel reports
DROP POLICY IF EXISTS "Admin dapat menghapus laporan" ON public.reports;
CREATE POLICY "Admin dapat menghapus laporan"
ON public.reports FOR DELETE USING (true);

-- 2. Kebijakan DELETE untuk tabel report_media
DROP POLICY IF EXISTS "Admin dapat menghapus media laporan" ON public.report_media;
CREATE POLICY "Admin dapat menghapus media laporan"
ON public.report_media FOR DELETE USING (true);

-- 3. Kebijakan DELETE untuk tabel report_reviews
DROP POLICY IF EXISTS "Admin dapat menghapus reviews" ON public.report_reviews;
CREATE POLICY "Admin dapat menghapus reviews"
ON public.report_reviews FOR DELETE USING (true);

-- 4. Kebijakan DELETE untuk tabel report_cleanups
DROP POLICY IF EXISTS "Admin dapat menghapus cleanups" ON public.report_cleanups;
CREATE POLICY "Admin dapat menghapus cleanups"
ON public.report_cleanups FOR DELETE USING (true);

-- 5. Kebijakan DELETE untuk tabel report_status_history
DROP POLICY IF EXISTS "Admin dapat menghapus riwayat status" ON public.report_status_history;
CREATE POLICY "Admin dapat menghapus riwayat status"
ON public.report_status_history FOR DELETE USING (true);
