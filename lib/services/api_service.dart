import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/air_quality_model.dart';

class ApiService {
  static Future<AirQualityModel> fetchAirQuality(String city) async {
    try {
      final String trimmedCity = city.trim();
      if (trimmedCity.isEmpty) {
        return AirQualityModel(status: 'error', cityName: city);
      }

      // 1. Geocoding API (Mencari koordinat kota)
      final geoUrl = Uri.https(
        'geocoding-api.open-meteo.com',
        '/v1/search',
        {
          'name': trimmedCity,
          'count': '1',
          'language': 'en',
          'format': 'json',
        },
      );

      final geoResponse = await http.get(geoUrl);

      if (geoResponse.statusCode != 200) {
        return AirQualityModel(status: 'error', cityName: city);
      }

      final geoData = jsonDecode(geoResponse.body);
      if (geoData['results'] == null || (geoData['results'] as List).isEmpty) {
        return AirQualityModel(status: 'error', cityName: city);
      }

      final firstResult = geoData['results'][0];
      final double lat = firstResult['latitude'];
      final double lon = firstResult['longitude'];
      final String officialName = firstResult['name'] ?? city;

      // 2. Air Quality API (Mengambil indeks AQI, PM2.5, PM10)
      final aqUrl = Uri.https(
        'air-quality-api.open-meteo.com',
        '/v1/air-quality',
        {
          'latitude': '$lat',
          'longitude': '$lon',
          'current': 'us_aqi,pm2_5,pm10',
        },
      );

      final aqResponse = await http.get(aqUrl);

      if (aqResponse.statusCode == 200) {
        final aqData = jsonDecode(aqResponse.body);
        return AirQualityModel.fromOpenMeteo(officialName, aqData);
      } else {
        return AirQualityModel(status: 'error', cityName: city);
      }
    } catch (e) {
      return AirQualityModel(status: 'error', cityName: city);
    }
  }
}