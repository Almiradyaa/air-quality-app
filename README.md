| Keterangan | Detail |
| :--- | :--- |
| **Nama** | Dita Ayodya Al Mira |
| **NIM** | D121241008 |
| **Kelas** | Pemrograman Mobile B |

# Air Quality App

Aplikasi mobile berbasis **Flutter** untuk memantau indeks kualitas udara (*Air Quality Index* / AQI) secara *real-time* di berbagai kota. Aplikasi ini dirancang untuk menerapkan konsep pengambilan data dari REST API eksternal, penanganan antarmuka asinkron (*Asynchronous UI*), serta penyimpanan data lokal di perangkat pengguna.

---

## Fitur Utama

1. **Pemantauan Kualitas Udara Real-Time (REST API)**
   - Mengambil data indeks kualitas udara (AQI) terkini berdasarkan nama kota dari layanan Public API (WAQI / IQAir / OpenWeather).
2. **Asynchronous UI yang Responsif**
   - Menggunakan widget `FutureBuilder` untuk mengelola dan menampilkan status antarmuka secara dinamis pada kondisi **Loading** (menunggu respon server), **Success** (data berhasil ditampilkan), dan **Error** (gagal memuat data atau kota tidak ditemukan)[cite: 6].
3. **Penyimpanan Data Lokal (Local Storage)**
   - Menyimpan preferensi pengguna secara lokal menggunakan `SharedPreferences` (untuk mengingat kota terakhir yang dicari) atau `SQLite` (untuk menyimpan daftar riwayat pencarian)[cite: 6].

---

## Teknologi & Paket yang Digunakan

* **Framework:** [Flutter](https://flutter.dev/) (Dart)[cite: 1, 4]
* **Networking:** `http` / `dio` (untuk komunikasi REST API)
* **Local Storage:** `shared_preferences` / `sqflite`[cite: 6]
* **State & Async Handling:** `FutureBuilder`[cite: 6]

---

## Struktur Proyek

```text
air_quality_app/
├── android/            # Konfigurasi platform Android (Kotlin)
├── ios/                # Konfigurasi platform iOS
├── lib/                # Kode sumber utama aplikasi Flutter
│   └── main.dart       # Entry point & UI utama aplikasi
├── test/               # Pengujian unit & widget
├── pubspec.yaml        # Daftar dependensi dan aset proyek
└── README.md           # Dokumentasi proyek
