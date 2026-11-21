class AirQualityModel {
  final String status;
  final String cityName;
  final int aqi;
  final double pm25;
  final double pm10;

  AirQualityModel({
    required this.status,
    required this.cityName,
    this.aqi = 0,
    this.pm25 = 0.0,
    this.pm10 = 0.0,
  });

  // Getter alias untuk usAqi agar tidak error jika dipanggil dengan .usAqi
  int get usAqi => aqi;

  // Factory constructor dari Open-Meteo API
  factory AirQualityModel.fromOpenMeteo(String cityName, Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>? ?? {};

    return AirQualityModel(
      status: 'success',
      cityName: cityName,
      aqi: (current['us_aqi'] as num?)?.toInt() ?? 0,
      pm25: (current['pm2_5'] as num?)?.toDouble() ?? 0.0,
      pm10: (current['pm10'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Getter kategori berdasarkan nilai AQI
  String get category {
    if (aqi <= 50) return 'Baik (Good)';
    if (aqi <= 100) return 'Sedang (Moderate)';
    if (aqi <= 150) return 'Tidak Sehat (Sensitive)';
    if (aqi <= 200) return 'Sangat Tidak Sehat';
    return 'Berbahaya (Hazardous)';
  }

  // Getter rekomendasi kesehatan otomatis
  String get healthAdvice {
    if (aqi <= 50) {
      return 'Kualitas udara sangat baik. Sangat aman untuk beraktivitas atau berolahraga di luar ruangan.';
    } else if (aqi <= 100) {
      return 'Kualitas udara sedang. Kelompok sensitif disarankan mengurangi aktivitas luar ruangan berlebih.';
    } else if (aqi <= 150) {
      return 'Gunakan masker saat keluar rumah. Anak-anak dan kelompok sensitif sebaiknya berada di dalam ruangan.';
    } else if (aqi <= 200) {
      return 'Hindari aktivitas outdoor. Gunakan masker N95 jika terpaksa keluar dan nyalakan air purifier.';
    } else {
      return 'Peringatan kesehatan bahaya tinggi! Tetap di dalam ruangan dan pastikan ventilasi tertutup rapat.';
    }
  }
}