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

  // Cache geocoding di memori agar performa cepat dan hemat request
  static final Map<String, String> _addressCache = {};

  static String _cacheKey(double lat, double lng) =>
      '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

  /// Mengambil nama lokasi dari cache jika sudah pernah di-resolve sebelumnya
  static String? getCachedAddress(double lat, double lng) =>
      _addressCache[_cacheKey(lat, lng)];

  /// Menyimpan nama lokasi ke cache memori
  static void cacheAddress(double lat, double lng, String address) {
    if (address.trim().isNotEmpty) {
      _addressCache[_cacheKey(lat, lng)] = address.trim();
    }
  }

  /// Mendapatkan nama tempat/lokasi nyata di mana kita berada dari koordinat GPS
  static Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    final key = _cacheKey(lat, lng);
    if (_addressCache.containsKey(key)) {
      return _addressCache[key];
    }

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');
      final resp = await http.get(url, headers: {
        'User-Agent': 'CoastWatch-App/1.0',
      }).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road = address['road'] ?? address['pedestrian'] ?? address['street'] ?? address['path'];
          final beach = address['beach'] ?? address['natural'] ?? address['leisure'] ?? address['amenity'];
          final area = address['neighbourhood'] ?? address['suburb'] ?? address['village'] ?? address['hamlet'];
          final district = address['city_district'] ?? address['subdistrict'];
          final city = address['town'] ?? address['city'] ?? address['county'] ?? address['regency'];

          final place = beach ?? road;
          final subArea = area ?? district;
          final region = city;

          final parts = [place, subArea, region].where((p) => p != null && p.toString().trim().isNotEmpty).toList();
          if (parts.isNotEmpty) {
            final formatted = parts.join(', ');
            _addressCache[key] = formatted;
            return formatted;
          }
        }
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          final formatted = displayName.split(',').take(3).join(', ').trim();
          _addressCache[key] = formatted;
          return formatted;
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Reverse geocode error: $e');
    }

    // Jika gagal / offline, gunakan koordinat GPS nyata yang presisi tempat perangkat berada
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    final fallbackCoords = '${lat.abs().toStringAsFixed(4)}° $latDir, ${lng.abs().toStringAsFixed(4)}° $lngDir';
    _addressCache[key] = fallbackCoords;
    return fallbackCoords;
  }

  /// Helper untuk memastikan nama lokasi selalu riil tempat perangkat berada
  static Future<String> resolveRealLocation(double lat, double lng) async {
    final cached = getCachedAddress(lat, lng);
    if (cached != null && cached.isNotEmpty) return cached;
    final resolved = await getAddressFromCoordinates(lat, lng);
    if (resolved != null && resolved.isNotEmpty) return resolved;
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}° $latDir, ${lng.abs().toStringAsFixed(4)}° $lngDir';
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
