## Masalah
Koin di Roblox sering tersebar dan pemain kehilangan waktu untuk mengumpulkannya. Power-up magnet menjanjikan pengalaman yang lebih cepat, tetapi tanpa batas per pemain dan mekanisme pemulihan, ekonomi game mudah rusak.

## Yang Dibangun
Coin Magnet: sistem kolektibel koin dengan power-up magnet di Luau. Magnet menarik koin dalam radius. Setiap pemain punya batas tarikan. Koin kembali setelah cooldown. Berkas hasil: `CoinMagnet.lua` (10067 B), `config.json` (221 B), `README.md` (3583 B).

## Keputusan Teknis
Logika inti di Luau. Parameter radius, batas per pemain, dan cooldown dipisah ke `config.json` agar bisa diubah tanpa menyentuh kode. README memuat cara pakai dan batasan. Struktur ini menjaga perubahan tetap terkontrol.

## Bukti
QC berjalan 1.16 detik. Dua lapis aktif: kode dan lulus. Temuan: 0. Rincian berkas: 0 Python, 0 JS, 1 JSON, 1 Lua, 1 lain. Semua lapis aktif lulus.

## Batasan
QC hanya mencakup lapis kode. Uji beban pemain banyak dan pengujian di server produksi belum termasuk. Angka 1.16 detik adalah waktu QC, bukan waktu muat di game.