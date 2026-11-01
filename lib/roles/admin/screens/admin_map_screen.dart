import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants.dart';
import '../../../models/report_model.dart';
import '../../../services/report_service.dart';

class AdminMapScreen extends StatefulWidget {
  final ValueChanged<String> onNavigateToReview;

  const AdminMapScreen({
    super.key,
    required this.onNavigateToReview,
  });

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final MapController _mapController = MapController();
  final ReportService _reportService = ReportService();

  ReportModel? _inspectedReport;
  final String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    final all = _reportService.reports;
    if (all.isNotEmpty) {
      _inspectedReport = all.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _reportService,
      builder: (context, _) {
        final reports = _reportService.reports.where((r) {
          if (_selectedCategory != 'all' && r.categoryId != _selectedCategory) return false;
          return true;
        }).toList();

        final activeReport = _inspectedReport ?? (reports.isNotEmpty ? reports.first : null);

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isDesktop = w >= 980;

            return Stack(
              children: [
                // 1. OpenStreetMap Leaflet View
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: activeReport != null
                        ? LatLng(activeReport.latitude, activeReport.longitude)
                        : const LatLng(-6.012498, 106.689211),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: AppConstants.osmTileUrl,
                      userAgentPackageName: AppConstants.osmUserAgent,
                    ),
                    MarkerLayer(
                      markers: reports.map((rep) {
                        final isSelected = activeReport?.id == rep.id;
                        return Marker(
                          point: LatLng(rep.latitude, rep.longitude),
                          width: isSelected ? 36 : 26,
                          height: isSelected ? 36 : 26,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _inspectedReport = rep;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Container(
                                  width: isSelected ? 8 : 5,
                                  height: isSelected ? 8 : 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // 2. Top Header Bar (No icons)
                Positioned(
                  top: 14,
                  left: 14,
                  right: isDesktop && activeReport != null ? 390 : 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Peta Laporan Pesisir',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '${reports.length} Titik Terdata',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),

                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Layer: Standar Pesisir OSM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Zoom Controls (+ and - text buttons)
                Positioned(
                  left: 14,
                  bottom: isDesktop ? 20 : (activeReport != null ? 240 : 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Center(child: Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        InkWell(
                          onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Center(child: Text('−', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Right Inspector Panel
                if (activeReport != null)
                  if (isDesktop)
                    Positioned(
                      top: 14,
                      right: 14,
                      bottom: 14,
                      width: 360,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: _buildInspectorContent(activeReport),
                      ),
                    )
                  else
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 260),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: _buildInspectorContent(activeReport),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  // INSPECTOR CONTENT (Pure typography, no icons)
  Widget _buildInspectorContent(ReportModel report) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('INSPEKSI TITIK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                Row(
                  children: [
                    const Text('Detail Koordinat ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(3)),
                      child: Text('#${report.id}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
            TextButton(
              onPressed: () => setState(() => _inspectedReport = null),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
              ),
              child: const Text('[Tutup]', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Photo with EXIF Geotag tag
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  report.beforePhotoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(color: const Color(0xFF1E293B)),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                color: Colors.black.withValues(alpha: 0.8),
                child: Text(
                  'EXIF: ${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)} (±4m)',
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Kategori Temuan (HIGH CONTRAST)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Kategori:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                report.categoryName,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        const Divider(height: 14, color: Color(0xFFE2E8F0)),

        // Status Laporan
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Status:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF0F172A)),
              ),
              child: Text(
                report.status.label.toUpperCase(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        const Divider(height: 14, color: Color(0xFFE2E8F0)),

        // Wilayah
        const Text('Wilayah Pesisir:', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        Text(report.locationName ?? 'Estuari Teluk Naga, Banten', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),

        const SizedBox(height: 12),

        // Action Buttons
        ElevatedButton(
          onPressed: () => widget.onNavigateToReview(report.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('Buka Meja Kerja Verifikasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: '${report.latitude}, ${report.longitude}'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Koordinat disalin ke papan klip.')),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F172A),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: Text('Salin Koordinat (${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
