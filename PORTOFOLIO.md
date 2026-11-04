## Masalah
Koin di pengalaman Roblox tercecer dan tidak menarik. Pemain mengejar koin satu per satu. Retensi turun karena loop koleksi terasa lambat.

## Yang Dibangun
Coin Magnet: kolektibel koin dengan power-up magnet di Luau. Magnet menarik koin dalam radius. Ada batas per pemain. Koin kembali setelah cooldown. Berkas hasil: CoinMagnet.lua (6197 B), config.json (221 B), README.md (2087 B).

## Keputusan Teknis
Logika magnet dipisah ke satu modul Luau agar mudah diuji. Parameter radius, batas, dan cooldown ditaruh di config.json, bukan hardcode. README memuat cara pasang dan cara ubah parameter. Struktur ini menjaga perubahan perilaku tetap di satu berkas konfigurasi.

## Bukti
QC berjalan 0,61 detik. Lapis aktif: kode. Lapis lulus: kode. Temuan: 0. Rincian berkas: 1 Lua, 2 JSON, 0 Python, 0 JavaScript, 4 lain.

## Batasan
Fakta QC hanya mencakup lapis kode. Uji beban pemain banyak dan uji main langsung belum tercatat di fakta ini. Angka retensi dan pendapatan tidak tersedia dan tidak diklaim.