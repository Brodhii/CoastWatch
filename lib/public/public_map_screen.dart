import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/category_model.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../shared/status_badge.dart';

class PublicMapScreen extends StatefulWidget {
  const PublicMapScreen({super.key});

  @override
  State<PublicMapScreen> createState() => _PublicMapScreenState();
}

class _PublicMapScreenState extends State<PublicMapScreen> {
  final MapController _mapController = MapController();
  final ReportService _reportService = ReportService();

  String? _selectedCategoryId;
  ReportModel? _selectedReport;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _reportService,
      builder: (context, _) {
        final reports = _reportService.getPublicReports(categoryId: _selectedCategoryId);
        final categories = CategoryModel.defaultCategories;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Peta Laporan Publik'),
            actions: [
              IconButton(
                tooltip: 'Pusatkan Peta',
                icon: const Icon(Icons.my_location, size: 20),
                onPressed: () {
                  _mapController.move(
                    const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
                    AppConstants.defaultZoom,
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // 1. FlutterMap OpenStreetMap
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
                  initialZoom: AppConstants.defaultZoom,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _selectedReport = null;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: AppConstants.osmTileUrl,
                    userAgentPackageName: AppConstants.osmUserAgent,
                    maxZoom: 19,
                  ),
                  // Markers for verified public reports
                  MarkerLayer(
                    markers: reports.map((report) {
                      final isSelected = _selectedReport?.id == report.id;
                      return Marker(
                        point: LatLng(report.latitude, report.longitude),
                        width: isSelected ? 48 : 38,
                        height: isSelected ? 48 : 38,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedReport = report;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.navy : AppTheme.teal,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: AppTheme.white,
                              size: isSelected ? 26 : 20,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // 2. Category Filter Chips (Top Overlay)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFilterChip(
                        label: 'Semua Kategori',
                        isSelected: _selectedCategoryId == null,
                        onSelected: () {
                          setState(() {
                            _selectedCategoryId = null;
                          });
                        },
                      ),
                      ...categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _buildFilterChip(
                              label: cat.name,
                              isSelected: _selectedCategoryId == cat.id,
                              onSelected: () {
                                setState(() {
                                  _selectedCategoryId = cat.id;
                                });
                              },
                            ),
                          )),
                    ],
                  ),
                ),
              ),

              // 3. Attribution Note at Bottom-Left
              Positioned(
                bottom: _selectedReport != null ? 190 : 16,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Text(
                    '© OpenStreetMap contributors • Hanya Laporan Terverifikasi',
                    style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ),
              ),

              // 4. Selected Report Bottom Sheet / Card
              if (_selectedReport != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildReportSummaryCard(_selectedReport!),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.navy : AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.navy : AppTheme.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildReportSummaryCard(ReportModel report) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: _buildThumbnail(report.beforePhotoUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            report.categoryName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.navy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _selectedReport = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.locationName ?? report.formattedCoordinates,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: report.status, isCompact: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.publicReportDetail,
                  arguments: report.id,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy,
                foregroundColor: AppTheme.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Lihat Detail Laporan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    } else if (url.isNotEmpty) {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _fallback());
      }
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: AppTheme.background,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: AppTheme.textMuted, size: 24),
      ),
    );
  }
}
