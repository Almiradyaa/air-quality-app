import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'models/air_quality_model.dart';

void main() {
  runApp(const AirQualityApp());
}

class AirQualityApp extends StatelessWidget {
  const AirQualityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Quality App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate Dark Background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _currentCity = 'Jakarta';
  late Future<AirQualityModel> _airQualityFuture;
  List<String> _recentCities = [];

  @override
  void initState() {
    super.initState();
    _loadRecentCities();
    _fetchData(_currentCity);
  }

  Future<void> _loadRecentCities() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentCities = prefs.getStringList('recent_cities') ?? ['Jakarta', 'Bandung', 'Surabaya'];
    });
  }

  Future<void> _saveCityToHistory(String city) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_recentCities.contains(city)) {
      setState(() {
        _recentCities.insert(0, city);
        if (_recentCities.length > 5) _recentCities.removeLast();
      });
      await prefs.setStringList('recent_cities', _recentCities);
    }
  }

  void _fetchData(String city) {
    setState(() {
      _currentCity = city;
      _airQualityFuture = ApiService.fetchAirQuality(city);
    });
    _saveCityToHistory(city);
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF10B981); // Emerald Green
    if (aqi <= 100) return const Color(0xFFF59E0B); // Amber Yellow
    if (aqi <= 150) return const Color(0xFFF97316); // Orange
    if (aqi <= 200) return const Color(0xFFEF4444); // Red
    return const Color(0xFF8B5CF6); // Purple
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 16),

              if (_recentCities.isNotEmpty) _buildRecentCitiesRow(),
              const SizedBox(height: 24),

              // FutureBuilder untuk Penanganan State Asynchronous (Loading, Success, Error)
              FutureBuilder<AirQualityModel>(
                future: _airQualityFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.status == 'error') {
                    return _buildErrorState();
                  }

                  final data = snapshot.data!;
                  final aqiColor = _getAqiColor(data.aqi);

                  return Column(
                    children: [
                      // Hero Circular Glow Card (Design System 01)
                      _buildHeroGaugeCard(data, aqiColor),
                      const SizedBox(height: 20),

                      // Bento Metric Cards Grid (Design System 02)
                      _buildMetricsBentoGrid(data, aqiColor),
                      const SizedBox(height: 20),

                      // Health Advice Card (Design System 01)
                      _buildHealthAdviceCard(data, aqiColor),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Air Quality App',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Pemantau kualitas udara real-time',
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10),
          ),
          child: const Icon(Icons.air_rounded, color: Color(0xFF10B981)),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Cari kota (contoh: Jakarta, Bandung)...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF10B981)),
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                _fetchData(_searchController.text.trim());
                _searchController.clear();
              }
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            _fetchData(value.trim());
            _searchController.clear();
          }
        },
      ),
    );
  }

  Widget _buildRecentCitiesRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _recentCities.map((city) {
          final isSelected = city.toLowerCase() == _currentCity.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(city),
              selected: isSelected,
              onSelected: (_) => _fetchData(city),
              selectedColor: const Color(0xFF10B981).withOpacity(0.2),
              backgroundColor: const Color(0xFF1E293B),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF10B981) : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF10B981) : Colors.white12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroGaugeCard(AirQualityModel data, Color aqiColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: aqiColor.withOpacity(0.18),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            data.cityName.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),

          // Pendar Cahaya Radial Gauge (Design System 01)
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  aqiColor.withOpacity(0.35),
                  aqiColor.withOpacity(0.08),
                  Colors.transparent,
                ],
                stops: const [0.2, 0.7, 1.0],
              ),
              border: Border.all(color: aqiColor.withOpacity(0.4), width: 3),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${data.aqi}',
                    style: const TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const Text(
                    'AQI US',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Status Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: aqiColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: aqiColor.withOpacity(0.5)),
            ),
            child: Text(
              data.category,
              style: TextStyle(
                color: aqiColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsBentoGrid(AirQualityModel data, Color aqiColor) {
    return Row(
      children: [
        Expanded(
          child: _buildBentoCard(
            title: 'PM 2.5',
            value: data.pm25.toStringAsFixed(1),
            unit: 'µg/m³',
            icon: Icons.grain_rounded,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBentoCard(
            title: 'PM 10',
            value: data.pm10.toStringAsFixed(1),
            unit: 'µg/m³',
            icon: Icons.blur_on_rounded,
            color: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthAdviceCard(AirQualityModel data, Color aqiColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            aqiColor.withOpacity(0.2),
            const Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: aqiColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: aqiColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.health_and_safety_rounded, color: aqiColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rekomendasi Kesehatan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.healthAdvice,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: Color(0xFF10B981)),
          SizedBox(height: 16),
          Text(
            'Mengambil data kualitas udara...',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Gagal Memuat Data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Kota "$_currentCity" tidak ditemukan atau koneksi terputus. Coba periksa ejaan nama kota.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _fetchData(_currentCity),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }
}