import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final bool isAccurate;
  final String? warningMessage;
  final bool isFallback;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.isAccurate,
    this.warningMessage,
    this.isFallback = false,
  });

  String get formattedDisplay {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lngDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}° $latDir, ${longitude.abs().toStringAsFixed(4)}° $lngDir (±${accuracy.toStringAsFixed(0)}m)';
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Memeriksa apakah GPS/layanan lokasi aktif pada perangkat
  Future<bool> isServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Memeriksa status izin lokasi
  Future<LocationPermission> checkPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  /// Meminta izin akses lokasi kepada pengguna secara aktif
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Membuka pengaturan GPS perangkat
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Membuka pengaturan aplikasi (jika izin ditolak permanen)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Memeriksa dan memastikan izin lokasi aktif
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Mengambil lokasi GPS nyata perangkat dengan akurasi tinggi.
  /// Jika [strict] = true, wajib menggunakan GPS nyata dan melempar Exception jika GPS mati/izin ditolak.
  Future<LocationResult?> getCurrentLocation({bool strict = false}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (strict) {
          throw Exception('Layanan lokasi (GPS) pada perangkat Anda belum aktif. Harap aktifkan GPS untuk merekam data laporan pesisir.');
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (strict) {
          throw Exception('Izin akses lokasi ditolak. CoastWatch mewajibkan akses lokasi nyata agar titik temuan pesisir sah dan akurat.');
        }
      }

      // Ambil posisi terakhir yang diketahui terlebih dahulu jika ada
      Position? position = await Geolocator.getLastKnownPosition();

      // Dapatkan posisi GPS terkini perangkat secara akurat (timeout 15 detik untuk web/GPS lock)
      try {
        final freshPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
        position = freshPosition;
      } catch (gpsErr) {
        debugPrint('[LocationService] Fresh GPS position notice: $gpsErr');
        if (position == null && strict) {
          throw Exception('Gagal mendapatkan sinyal GPS nyata: $gpsErr. Pastikan Anda berada di area terbuka dengan GPS aktif.');
        }
      }

      if (position != null) {
        final isAccurate = position.accuracy <= AppConstants.maxAccuracyThresholdMeters;
        String? warning;
        if (!isAccurate) {
          warning = 'Akurasi GPS ±${position.accuracy.toStringAsFixed(0)}m. Disarankan mengambil foto di area terbuka dekat garis pantai.';
        }

        return LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
          isAccurate: isAccurate,
          warningMessage: warning,
          isFallback: false,
        );
      }

      if (strict) {
        throw Exception('Titik lokasi GPS nyata tidak terdeteksi. Harap periksa koneksi GPS perangkat Anda.');
      }

      // Fallback hanya digunakan untuk preview awal jika strict = false
      return LocationResult(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        accuracy: 15.0,
        timestamp: DateTime.now(),
        isAccurate: true,
        warningMessage: 'Izin lokasi belum aktif. Menampilkan area referensi pesisir.',
        isFallback: true,
      );
    } catch (e) {
      debugPrint('[LocationService] Failed to obtain GPS location: $e');
      if (strict) rethrow;
      return LocationResult(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        accuracy: 15.0,
        timestamp: DateTime.now(),
        isAccurate: true,
        warningMessage: 'GPS perangkat belum merespons: $e',
        isFallback: true,
      );
    }
  }

  /// Mendapatkan nama wilayah pesisir dari koordinat GPS nyata (reverse geocoding)
  static Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=14&addressdetails=1');
      final resp = await http.get(url, headers: {
        'User-Agent': 'CoastWatch-App/1.0',
      }).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final beach = address['natural'] ?? address['leisure'] ?? address['amenity'] ?? address['beach'];
          final subdistrict = address['suburb'] ?? address['village'] ?? address['town'] ?? address['city_district'];
          final city = address['city'] ?? address['regency'] ?? address['county'];

          final parts = [beach, subdistrict, city].where((p) => p != null && p.toString().isNotEmpty).toList();
          if (parts.isNotEmpty) {
            return 'Pesisir ${parts.join(', ')}';
          }
        }
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName.split(',').take(2).join(', ').trim();
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Reverse geocode error: $e');
    }
    return 'Wilayah Pesisir (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
  }

  static bool validateCoordinates(double lat, double lng) {
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    if (lat == 0.0 && lng == 0.0) return false; // Suspicious null island
    return true;
  }

  /// Calculate spatial distance in meters between two coordinates using WGS84 ellipsoid
  static double calculateDistanceMeters(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Check whether cleaner is within proximity radius (default: 50m) of target report coordinate
  static bool isWithinProximity(
    double lat1,
    double lng1,
    double lat2,
    double lng2, {
    double maxMeters = AppConstants.maxCleanerProximityMeters,
  }) {
    return calculateDistanceMeters(lat1, lng1, lat2, lng2) <= maxMeters;
  }

  /// Helper to format distance nicely (e.g. "25 m" or "1.4 km")
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} meter';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
