import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:exif/exif.dart';
import 'location_service.dart';

class ExifDataResult {
  final double? latitude;
  final double? longitude;
  final DateTime? dateTimeOriginal;
  final bool hasGps;
  final String statusMessage;
  final Map<String, dynamic> rawTags;

  const ExifDataResult({
    this.latitude,
    this.longitude,
    this.dateTimeOriginal,
    required this.hasGps,
    required this.statusMessage,
    this.rawTags = const {},
  });

  bool get isValid => hasGps && latitude != null && longitude != null && LocationService.validateCoordinates(latitude!, longitude!);

  String get formattedCoordinates {
    if (!isValid) return 'Koordinat tidak ditemukan';
    final latDir = latitude! >= 0 ? 'N' : 'S';
    final lngDir = longitude! >= 0 ? 'E' : 'W';
    return '${latitude!.abs().toStringAsFixed(4)}° $latDir, ${longitude!.abs().toStringAsFixed(4)}° $lngDir';
  }
}

class ExifService {
  static final ExifService _instance = ExifService._internal();
  factory ExifService() => _instance;
  ExifService._internal();

  /// Reads EXIF metadata from file and extracts GPS coordinates + DateTimeOriginal
  Future<ExifDataResult> extractExifData(File imageFile, {LocationResult? fallbackLocation}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isEmpty) {
        debugPrint('[ExifService] No EXIF tags found in image bytes.');
        // If device camera didn't write EXIF tags into the JPEG header directly,
        // use fallback device location acquired during capture to ensure geotagged report works
        if (fallbackLocation != null) {
          return ExifDataResult(
            latitude: fallbackLocation.latitude,
            longitude: fallbackLocation.longitude,
            dateTimeOriginal: fallbackLocation.timestamp,
            hasGps: true,
            statusMessage: 'Geotag berhasil disematkan dari sensor GPS perangkat saat pengambilan foto.',
          );
        }
        return const ExifDataResult(
          hasGps: false,
          statusMessage: 'GPS tidak ditemukan — ambil ulang foto menggunakan kamera aplikasi dengan izin lokasi aktif.',
        );
      }

      double? lat;
      double? lng;
      DateTime? dateTime;

      // Extract GPS Latitude
      if (data.containsKey('GPS GPSLatitude') && data.containsKey('GPS GPSLatitudeRef')) {
        final latValues = data['GPS GPSLatitude']?.values.toList();
        final latRef = data['GPS GPSLatitudeRef']?.printable;
        if (latValues != null && latValues.isNotEmpty) {
          lat = _convertGpsCoordinate(latValues);
          if (latRef == 'S') lat = -lat;
        }
      }

      // Extract GPS Longitude
      if (data.containsKey('GPS GPSLongitude') && data.containsKey('GPS GPSLongitudeRef')) {
        final lngValues = data['GPS GPSLongitude']?.values.toList();
        final lngRef = data['GPS GPSLongitudeRef']?.printable;
        if (lngValues != null && lngValues.isNotEmpty) {
          lng = _convertGpsCoordinate(lngValues);
          if (lngRef == 'W') lng = -lng;
        }
      }

      // Extract DateTimeOriginal
      if (data.containsKey('EXIF DateTimeOriginal')) {
        final dtStr = data['EXIF DateTimeOriginal']?.printable;
        if (dtStr != null && dtStr.isNotEmpty) {
          try {
            // Format: "YYYY:MM:DD HH:MM:SS"
            final parts = dtStr.split(' ');
            final dateParts = parts[0].replaceAll(':', '-');
            dateTime = DateTime.tryParse('$dateParts ${parts[1]}');
          } catch (_) {}
        }
      }

      // Fallback if image EXIF doesn't have GPS tags but capture location is provided
      if ((lat == null || lng == null) && fallbackLocation != null) {
        return ExifDataResult(
          latitude: fallbackLocation.latitude,
          longitude: fallbackLocation.longitude,
          dateTimeOriginal: dateTime ?? fallbackLocation.timestamp,
          hasGps: true,
          statusMessage: 'Geotag disinkronkan dari GPS perangkat saat pemotretan.',
          rawTags: data.map((k, v) => MapEntry(k, v.printable)),
        );
      }

      if (lat != null && lng != null && LocationService.validateCoordinates(lat, lng)) {
        return ExifDataResult(
          latitude: lat,
          longitude: lng,
          dateTimeOriginal: dateTime ?? DateTime.now(),
          hasGps: true,
          statusMessage: 'Koordinat GPS EXIF valid ditemukan pada foto.',
          rawTags: data.map((k, v) => MapEntry(k, v.printable)),
        );
      }

      return const ExifDataResult(
        hasGps: false,
        statusMessage: 'GPS tidak ditemukan — ambil ulang foto dengan GPS aktif.',
      );
    } catch (e) {
      debugPrint('[ExifService] Error extracting EXIF: $e');
      if (fallbackLocation != null) {
        return ExifDataResult(
          latitude: fallbackLocation.latitude,
          longitude: fallbackLocation.longitude,
          dateTimeOriginal: fallbackLocation.timestamp,
          hasGps: true,
          statusMessage: 'Geotag berhasil diproses dari koordinat pemotretan.',
        );
      }
      return ExifDataResult(
        hasGps: false,
        statusMessage: 'Gagal membaca metadata EXIF: $e',
      );
    }
  }

  static double _convertGpsCoordinate(List<dynamic> values) {
    double degrees = _toDouble(values[0]);
    double minutes = values.length > 1 ? _toDouble(values[1]) : 0.0;
    double seconds = values.length > 2 ? _toDouble(values[2]) : 0.0;
    return degrees + (minutes / 60.0) + (seconds / 3600.0);
  }

  static double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is Ratio) return val.numerator / val.denominator;
    return 0.0;
  }
}
