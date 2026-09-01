# Roadmap — Rencana Keuangan

Dokumen ini mencatat rancangan pengembangan berikutnya untuk fitur **Cicilan** dan **Tabungan** pada Dompetku. Fitur belum diimplementasikan pada aplikasi.

## Prinsip pencatatan

- **Saldo tersedia** adalah Cash + E-Wallet + Bank.
- **Cicilan yang dibayar** adalah pengeluaran: mengurangi saldo tersedia dan budget bulanan.
- **Setoran tabungan** adalah perpindahan aset: mengurangi saldo tersedia dan menambah saldo tabungan; tidak dihitung sebagai pengeluaran budget.
- Semua data rencana keuangan harus ikut dalam export/import backup JSON.

## Fitur 1 — Cicilan

### Data cicilan

| Data | Keterangan |
|---|---|
| Nama cicilan | Contoh: Cicilan Mobil |
| Penyedia | Leasing, bank, atau pihak lain |
| Sumber dana default | Cash, E-Wallet, atau Bank |
| Jadwal pembayaran | Nominal dan tanggal jatuh tempo tiap pembayaran |
| Status | Aktif, Lunas, atau Dibatalkan |

### Data setiap pembayaran

| Data | Keterangan |
|---|---|
| Urutan | Bayar ke-1, ke-2, dan seterusnya |
| Jatuh tempo | Tanggal pembayaran yang direncanakan |
| Nominal | Dapat berbeda untuk tiap pembayaran |
| Status bayar | Belum dibayar atau Lunas |
| Tanggal dibayar | Diisi saat pembayaran dilakukan |
| Sumber dana aktual | Dipilih saat pembayaran dilakukan |
| ID transaksi | Tautan ke transaksi pengeluaran otomatis |

### Alur pembayaran

1. Pengguna membuka detail cicilan dan memilih pembayaran yang belum lunas.
2. Pengguna menekan **Bayar cicilan** lalu memilih sumber dana.
3. Aplikasi meminta konfirmasi.
4. Saldo sumber dana dan sisa budget langsung berkurang.
5. Aplikasi membuat transaksi pengeluaran yang ditautkan ke jadwal cicilan.
6. Pembayaran ditandai lunas dan progres cicilan diperbarui.

## Fitur 2 — Tabungan

### Data tabungan

| Data | Keterangan |
|---|---|
| Nama tabungan | Contoh: Tabungan Bersama |
| Target nominal | Opsional |
| Target tanggal | Opsional |
| Kontributor | Contoh: Suami dan Istri |
| Saldo tabungan | Total seluruh setoran dikurangi penarikan |
| Status | Aktif atau Selesai |

### Data setoran atau penarikan

| Data | Keterangan |
|---|---|
| Tipe | Setoran atau Penarikan |
| Kontributor | Suami, Istri, atau kontributor lain |
| Nominal | Nilai transaksi |
| Tanggal | Tanggal pencatatan |
| Sumber dana | Cash, E-Wallet, atau Bank |
| Catatan | Opsional |

### Alur setoran tabungan

1. Pengguna membuka tabungan dan menekan **Tambah setoran**.
2. Pengguna memilih kontributor, nominal, tanggal, dan sumber dana.
3. Saldo sumber dana berkurang; saldo tabungan bertambah dengan nominal yang sama.
4. Total setoran per kontributor dan progres target dihitung otomatis.
5. Setoran tidak dicatat sebagai pengeluaran budget karena tetap merupakan aset pengguna.

## Dampak dashboard yang direncanakan

- Saldo tersedia: Cash + E-Wallet + Bank.
- Total tabungan: seluruh saldo tabungan aktif.
- Total aset: Saldo tersedia + Total tabungan.
- Ringkasan cicilan: jumlah cicilan aktif, pembayaran terdekat, dan total kewajiban tersisa.

## Tahapan implementasi

1. Model data dan penyimpanan lokal untuk cicilan serta jadwal pembayaran.
2. Halaman daftar/detail cicilan dan aksi bayar yang menghasilkan transaksi pengeluaran otomatis.
3. Model data tabungan, kontributor, setoran, serta penarikan.
4. Ringkasan aset dan rencana keuangan di dashboard.
5. Menambahkan data cicilan/tabungan ke skema backup JSON.
6. Opsional: notifikasi pengingat jatuh tempo yang hanya aktif atas persetujuan pengguna.

## Studi Kasus Nyata — Isi Manual

Tambahkan contoh kebutuhan nyata di bawah ini sebelum implementasi dimulai.

### Cicilan

- Nama cicilan:
- Penyedia:
- Sumber dana pembayaran:
- Jadwal pembayaran:
- Kondisi khusus (nominal berbeda, denda, pembayaran dipercepat, dan lain-lain):

### Tabungan

- Nama tabungan:
- Target nominal dan tanggal:
- Kontributor:
- Pola setoran:
- Sumber dana:
- Aturan penarikan atau kondisi khusus:
