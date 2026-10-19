# Struktur Folder CoastWatch (Sederhana)

Struktur ini mengikuti `desain.md` CoastWatch. Ada **3 role akun**: Pelapor (`reporter`), Relawan/Pekerja Pembersih (`cleaner`), dan Admin (`admin`). **Pengunjung/Guest bukan role akun**; Guest adalah pengguna yang belum login dan hanya mengakses halaman publik.

## 1. Struktur folder

```text
coastwatch/
├── mobile/                         # Aplikasi Flutter Android
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/                   # Konfigurasi, tema, routing
│   │   ├── models/                 # Model laporan, kategori, profil, tugas
│   │   ├── services/               # Supabase, Auth, kamera, GPS, EXIF, API
│   │   ├── shared/                 # Widget umum yang dipakai lintas halaman
│   │   ├── public/                 # Layar Guest/pengunjung tanpa login
│   │   │   ├── home_screen.dart
│   │   │   ├── public_map_screen.dart
│   │   │   └── public_report_detail_screen.dart
│   │   └── roles/
│   │       ├── reporter/           # Role Pelapor
│   │       │   ├── screens/
│   │       │   └── widgets/
│   │       └── cleaner/            # Role Relawan/Pekerja Pembersih
│   │           ├── screens/
│   │           └── widgets/
│   └── test/
│
├── admin_web/                      # Panel Admin terpisah (Flutter Web)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/                   # Routing, tema, konfigurasi
│   │   ├── services/               # Supabase dan pemanggilan API
│   │   └── roles/
│   │       └── admin/              # Role Admin
│   │           ├── screens/        # Antrean, tinjau laporan, kategori, audit
│   │           └── widgets/
│   └── test/
│
├── supabase/
│   ├── migrations/                 # Tabel, relasi, PostGIS, RLS, Storage policy
│   ├── functions/
│   │   ├── submit-report/           # Pengajuan dan validasi EXIF laporan
│   │   ├── admin-review-report/     # Verifikasi/penolakan oleh Admin
│   │   ├── cleanup-report/          # Tugas dan bukti pembersihan Relawan
│   │   └── map-reports/             # Data marker sesuai izin akses
│   └── seed.sql                    # Data awal kategori
│
├── docs/
│   ├── desain.md
│   └── struktur-folder.md
├── README.md
└── .gitignore
```

## 2. Pembagian akses

| Jenis pengguna | Lokasi kode | Fungsi utama |
|---|---|---|
| Pengunjung / Guest (belum login, bukan role akun) | `mobile/lib/public/` | Melihat Beranda, peta publik, dan detail laporan yang boleh dilihat publik. Tidak dapat membuat laporan atau mengakses data personal. |
| Pelapor (`reporter`) | `mobile/lib/roles/reporter/` | Mengambil foto ber-geotag, membuat dan mengirim laporan, serta melihat laporan dan status miliknya. |
| Relawan/Pekerja Pembersih (`cleaner`) | `mobile/lib/roles/cleaner/` | Melihat laporan terverifikasi yang tersedia, mengambil tugas pembersihan, dan mengirim foto bukti sesudah pembersihan. |
| Admin (`admin`) | `admin_web/lib/roles/admin/` | Memverifikasi/menolak laporan, menandai duplikat, mengelola kategori, memantau tugas, dan melihat audit. Admin memakai panel web terpisah. |

## 3. Aturan penempatan kode

1. Guest tidak dibuat sebagai role akun dan tidak dimasukkan ke `roles/`. Halaman publik diletakkan di `mobile/lib/public/`.
2. Tiga role akun adalah `reporter`, `cleaner`, dan `admin`. Pelapor dan Relawan menggunakan aplikasi mobile; Admin menggunakan panel web.
3. Komponen yang dipakai beberapa bagian aplikasi, seperti kartu laporan, tema, pembaca EXIF, kamera, lokasi, dan koneksi Supabase, diletakkan di `shared/`, `core/`, `models/`, atau `services/`, bukan diduplikasi per role.
4. Semua hak akses harus tetap diverifikasi oleh Supabase RLS dan Edge Functions. Menyembunyikan tombol di UI saja tidak cukup.
5. Jangan memasukkan `service_role` key, secret backend, atau kredensial database ke aplikasi mobile, web client, maupun repositori.
6. Mulai dengan folder dan file yang benar-benar diperlukan. Tambahkan subfolder baru hanya ketika jumlah kode sudah membutuhkannya.

## 4. Urutan implementasi yang disarankan

1. Siapkan proyek Flutter mobile, panel Admin Flutter Web, dan proyek Supabase.
2. Buat layar publik Guest: Beranda, Peta, dan detail laporan publik.
3. Buat autentikasi lalu arahkan akun berdasarkan role `reporter` atau `cleaner` ke halaman masing-masing; role `admin` masuk melalui panel web.
4. Implementasikan kamera, penulisan EXIF, pengajuan laporan, dan validasi EXIF di backend.
5. Implementasikan antrean serta keputusan verifikasi Admin.
6. Implementasikan tugas Relawan dan unggah foto bukti pembersihan ber-geotag.
7. Uji akses RLS, status laporan, unggah foto, koneksi gagal, dan alur end-to-end.
