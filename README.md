# 📱 MoneyTracker - Android Native Personal Finance App

Aplikasi pengelolaan keuangan harian offline-first berbasis Android native (Flutter) dengan sistem **Envelope Budgeting** dan **Dynamic Daily Meal Radar**, didesain menggunakan **Material Design 3** & **Dark Mode** elegan yang dioptimalkan untuk navigasi satu tangan di smartphone.

---

## 🎯 Fitur Utama

1. **Dashboard Utama & Envelope Budgeting**:
   - **Summary Card**: Total Anggaran Bulanan, Total Pengeluaran, Sisa Saldo Tersedia, serta selector bulan.
   - **Pos Anggaran (Budget Envelopes)**: Progress bar dinamis per kategori:
     - 🟢 **Hijau**: Pengeluaran aman (<75%).
     - 🟡 **Kuning**: Peringatan mendekati batas (75% - 100%).
     - 🔴 **Merah**: Melebihi anggaran (*Overbudget*).
   - **Dynamic Daily Meal Gauge**:
     - Formula perhitungan otomatis:
       $$\text{Jatah Makan Harian} = \frac{\text{Sisa Budget Makan Bulan Ini}}{\text{Sisa Hari dalam Bulan Ini}}$$
     - Dilengkapi arc gauge dinamis, perbandingan terhadap target ideal (~Rp60.000/hari), dan tips finansial kontekstual harian.

2. **Input Pengeluaran Cepat (Quick Add Modal)**:
   - Floating Action Button (+) di bagian bawah yang mudah dijangkau satu jempol.
   - Numpad kalkulator khusus dengan tombol cepat `000` (Ribu), `⌫`, dan `C`.
   - Chip preset nominal instan: `+15rb`, `+25rb`, `+50rb`, `+100rb`.
   - Selector kategori horizontal dengan ikon & warna khas.
   - Pilihan tanggal fleksibel dan saran catatan cepat (*Makan Siang, Kopi, Bensin, dll.*).

3. **Log Transaksi & Filter**:
   - Pengelompokan transaksi otomatis per tanggal (*Hari Ini, Kemarin, atau Tanggal Lengkap*) dengan sub-total pengeluaran harian.
   - Fitur **Swipe to Delete** dengan konfirmasi dialog.
   - Fitur **Tap to Edit** untuk memperbarui nominal, kategori, catatan, atau tanggal transaksi.
   - Filter instan berdasarkan kategori dan bilah pencarian catatan.

4. **Pengaturan & Cadangan Offline-First (SQLite)**:
   - Ubah pagu/target nominal masing-masing amplop anggaran secara dinamis.
   - **Ekspor Cadangan (JSON)**: Membagikan file cadangan langsung ke Google Drive, WhatsApp, Telegram, atau File Manager HP.
   - **Impor Cadangan**: Memulihkan database dari file `.json` dengan validasi otomatis.
   - Sakelar Tema (Dark Mode / Light Mode).
   - Opsi reset ke 8 pos anggaran bawaan.

---

## 💰 Struktur Anggaran Bawaan (Total: Rp4.500.000)

| Pos Anggaran / Envelope | Pagu Bawaan | Ikon | Keterangan |
| :--- | :--- | :---: | :--- |
| **Tabungan & Investasi** | Rp1.000.000 | 💰 | Tabungan awal bulan |
| **Makan & Minum** | Rp1.800.000 | 🍛 | ~Rp60.000/hari (Terhubung ke Radar Harian) |
| **Laundry** | Rp250.000 | 🧺 | Cuci pakaian mingguan/kiloan |
| **Listrik** | Rp200.000 | ⚡ | Token / tagihan PLN bulanan |
| **Wi-Fi** | Rp200.000 | 📶 | Internet rumah |
| **Transport & Pulsa** | Rp400.000 | 🚗 | Bensin & paket data smartphone |
| **Senang-senang / Hiburan** | Rp400.000 | 🎮 | Bioskop, kopi santai, hobi |
| **Dana Cadangan & Medis** | Rp250.000 | 🩺 | Obat-obatan & keperluan darurat |
| **TOTAL ANGGARAN** | **Rp4.500.000** | | |

---

## 🏗️ Struktur Arsitektur Project

```text
moneytracker/
├── android/                         # Konfigurasi Gradle & Manifest Android Native
│   ├── app/
│   │   ├── build.gradle             # Android SDK 34, minSdk 21, multiDex
│   │   └── src/main/
│   │       ├── AndroidManifest.xml  # Izin storage & konfigurasi orientasi
│   │       └── kotlin/com/example/moneytracker/MainActivity.kt
│   ├── build.gradle
│   ├── gradle.properties
│   └── settings.gradle
├── lib/
│   ├── main.dart                    # Entry point aplikasi, localization id_ID, providers
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart      # Dark/Light color palette & budget status helper
│   │   │   └── app_constants.dart   # Baseline Rp4.5jt, presets, saran catatan
│   │   ├── theme/
│   │   │   └── app_theme.dart       # Material Design 3 ThemeData (Dark & Light)
│   │   └── utils/
│   │       ├── currency_formatter.dart # Format Rupiah e.g. "Rp1.800.000"
│   │       └── date_formatter.dart     # Format tanggal Indonesia & sisa hari
│   ├── data/
│   │   ├── models/
│   │   │   ├── budget_category.dart    # Model kategori & 8 default envelopes
│   │   │   └── transaction_item.dart   # Model transaksi SQLite
│   │   ├── database/
│   │   │   └── database_helper.dart    # SQLite singleton (CRUD, aggregate query)
│   │   └── services/
│   │       └── backup_service.dart     # JSON export & file picker restore
│   ├── providers/
│   │   ├── finance_provider.dart       # State management anggaran & radar makan
│   │   └── theme_provider.dart         # Pengatur tema Dark/Light
│   └── screens/
│       ├── main_screen.dart            # Shell navigasi bawah + FAB (+)
│       ├── dashboard/
│       │   ├── dashboard_screen.dart
│       │   └── widgets/
│       │       ├── summary_card.dart
│       │       ├── daily_meal_gauge.dart # Visual arc gauge sisa jatah makan
│       │       └── budget_envelope_card.dart
│       ├── transactions/
│       │   ├── transactions_screen.dart # List transaksi grouping tanggal
│       │   └── widgets/
│       │       ├── transaction_tile.dart       # Swipe to delete tile
│       │       └── edit_transaction_dialog.dart
│       ├── quick_add/
│       │   └── quick_add_sheet.dart    # Modal numpad + preset + chip kategori
│       └── settings/
│           ├── settings_screen.dart    # Kelola pagu, backup/restore JSON
│           └── widgets/
│               └── edit_budget_dialog.dart
├── pubspec.yaml                     # Dependensi Flutter (sqflite, provider, intl, dll.)
└── analysis_options.yaml
```

---

## 🚀 Panduan Setup & Menjalankan di Local

### 1. Prasyarat
- Pastikan **Flutter SDK (versi 3.19.0 atau lebih baru)** dan **Android SDK / Android Studio** sudah terinstal di komputer.
- Cek kesiapan sistem dengan perintah:
  ```bash
  flutter doctor
  ```

### 2. Mengambil Dependensi
Buka terminal di direktori folder project:
```bash
cd moneytracker
flutter pub get
```

### 3. Menjalankan di Emulator / HP Android (Debug Mode)
Hubungkan HP Android via kabel USB (pastikan *USB Debugging* aktif di Developer Options) atau nyalakan Android Emulator, lalu jalankan:
```bash
flutter run
```

---

## 📦 Panduan Build File Installer .APK

Aplikasi ini bisa langsung di-compile menjadi file `.apk` siap pasang ke smartphone Android:

### Opsi A: Build Universal APK Release (Paling Praktis)
Perintah ini menghasilkan 1 file APK universal yang bisa diinstal di semua jenis prosesor smartphone Android:
```bash
flutter build apk --release
```

📁 **Lokasi File APK Hasil Build:**
```text
moneytracker/build/app/outputs/flutter-apk/app-release.apk
```

---

### Opsi B: Build Split Per-ABI (Ukuran File APK Jauh Lebih Kecil)
Smartphone modern biasanya menggunakan prosesor `arm64-v8a`. Opsi ini memecah APK sesuai arsitektur prosesor sehingga ukuran download/install jauh lebih ramping (~15-20 MB):
```bash
flutter build apk --split-per-abi
```

📁 **Lokasi File APK Hasil Build:**
```text
moneytracker/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
moneytracker/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
moneytracker/build/app/outputs/flutter-apk/app-x86_64-release.apk
```
*(Untuk hampir semua HP Android masa kini, gunakan file `app-arm64-v8a-release.apk`)*.

---

## 📲 Cara Memindahkan & Menginstal ke HP Android

1. Salin file `app-release.apk` (atau `app-arm64-v8a-release.apk`) ke HP Anda melalui:
   - Kabel data USB (pindah ke folder `Download` di HP).
   - Kirim ke diri sendiri melalui WhatsApp Web / Telegram Saved Messages.
   - Upload ke Google Drive dan unduh di HP.
2. Buka aplikasi **File Manager** di HP Anda, temukan file `.apk` tersebut.
3. Ketuk file `.apk` untuk menginstal.
4. Jika muncul peringatan *"Install unknown apps"* atau *"Sumber tidak dikenal"*, izinkan izin instalasi untuk File Manager Anda.
5. Aplikasi **MoneyTracker** siap digunakan 100% offline tanpa perlu koneksi internet atau backend server!
