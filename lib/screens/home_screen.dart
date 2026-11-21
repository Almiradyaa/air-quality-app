import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/air_quality_model.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _cityController = TextEditingController();
  late Future<AirQualityModel> _airQualityFuture;
  String _currentCity = "Jakarta";

  @override
  void initState() {
    super.initState();
    _loadSavedCity();
  }

  // Membaca kota pencarian terakhir dari penyimpanan lokal
  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('last_city') ?? "Jakarta";
    setState(() {
      _currentCity = savedCity;
      _cityController.text = savedCity;
      _airQualityFuture = ApiService.fetchAirQuality(savedCity);
    });
  }

  // Menyimpan kota pencarian baru ke penyimpanan lokal
  Future<void> _searchCity() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_city', city);

    setState(() {
      _currentCity = city;
      _airQualityFuture = ApiService.fetchAirQuality(city);
    });
  }

  Color _getAqiColor(int? aqi) {
    if (aqi == null) return Colors.grey;
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.amber;
    if (aqi <= 150) return Colors.orange;
    return Colors.red;
  }

  String _getAqiStatus(int? aqi) {
    if (aqi == null) return "Tidak Ada Data";
    if (aqi <= 50) return "Baik (Good)";
    if (aqi <= 100) return "Sedang (Moderate)";
    if (aqi <= 150) return "Tidak Sehat (Sensitif)";
    return "Berbahaya / Tidak Sehat";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Air Quality App'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Kolom Pencarian Kota
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama kota...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _searchCity(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _searchCity,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // FutureBuilder untuk menangani status Loading, Error, & Data Muncul
            Expanded(
              child: FutureBuilder<AirQualityModel>(
                future: _airQualityFuture,
                builder: (context, snapshot) {
                  // 1. Loading State
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Mengambil data dari Open-Meteo...'),
                        ],
                      ),
                    );
                  }

                  // 2. Error State
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.status != 'ok') {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal mengambil data untuk "$_currentCity".\nPastikan nama kota benar atau cek koneksi internet.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _searchCity,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }

                  // 3. Success State (Data Tampil)
                  final data = snapshot.data!;
                  final aqi = data.usAqi ?? 0;
                  final aqiColor = _getAqiColor(aqi);

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: aqiColor,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Text(
                                  data.cityName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '$aqi',
                                  style: const TextStyle(
                                    fontSize: 72,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'US AQI Index',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getAqiStatus(aqi),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildDetailItem(
                                  Icons.air,
                                  'PM2.5',
                                  data.pm25 != null
                                      ? '${data.pm25} µg/m³'
                                      : '-',
                                ),
                                _buildDetailItem(
                                  Icons.cloud,
                                  'PM10',
                                  data.pm10 != null
                                      ? '${data.pm10} µg/m³'
                                      : '-',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}