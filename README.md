# Whisper pipeline — local

Project ini berupa notebook Jupyter untuk transkripsi file WAV dan klasifikasi
intent berbasis kata kunci. Tidak membutuhkan API key; model berjalan lokal.
Setup dan pemuatan model pertama membutuhkan internet.

## VS Code notebook

Buka `intent.ipynb` langsung di VS Code. Klik kernel di kanan atas, pilih
**Select Another Kernel → Python Environments → whisper-pipeline (.venv/bin/python)**.
Pakai Python 3.12 dalam `.venv`, lalu jalankan cell berurutan dengan **Shift+Enter**.
Tidak perlu menjalankan `start-local.sh` untuk memakai editor notebook VS Code.

Pengaturan workspace `.vscode/settings.json` menunjuk ke environment project;
`.vscode/notebook.env` menyediakan path FFmpeg dan cache model untuk kernel.
Setelah mengubah pengaturan ini, restart kernel. Path dalam `notebook.env`
perlu disesuaikan jika folder project dipindah.

Untuk repo Hugging Face privat, isi token dengan akses baca di file `.env` pada
root project:

```dotenv
HF_TOKEN=hf_your_token_here
```

Cell pertama notebook `intent.ipynb` otomatis membaca `.env` sebelum memuat model.
Restart kernel setelah mengganti token, lalu jalankan cell dari atas. `.env`
diabaikan Git; `.env.example` hanya template. Token boleh dikosongkan untuk
model publik atau checkpoint lokal. Login CLI tidak diperlukan jika memakai `.env`.

## Menjalankan

```bash
cd /Users/fandika/Projects/whisper-pipeline
bash setup-local.sh
bash start-local.sh
```

Buka URL `http://127.0.0.1:8888/lab?token=...` yang muncul di terminal.
Pilih kernel **Python (whisper-pipeline)** lalu jalankan cell berurutan.
Hentikan server dengan **Ctrl+C** di terminal.

Dependency, FFmpeg, kernel Jupyter, dan cache model disimpan dalam project
(`.venv/`, `.local/`, `.cache/`). Setup menggunakan `uv` jika tersedia,
atau `python3` dan pip. Python 3.12 digunakan untuk environment lokal ini.

## Notebook

- `intent.ipynb`: perbandingan beberapa model pada WAV di `selected_audio/`;
  hasil baru disimpan ke `model_comparison.csv`.
- `faster_intent.ipynb`: faster-whisper dengan CPU dan int8, seluruh audio di `audio/`.
- `intent_with_appending.ipynb`: OpenAI Whisper dengan prefix audio;
  menggunakan tiga file di `selected_audio/` yang tercatat dalam
  `fall_prediction_audio_log.csv`. Hasil gabungan ada di `appended_audio/`.
- `intent-manual.ipynb`: klasifikasi dari kolom `Manual Transcription`, tanpa model audio.

Notebook `intent.ipynb` membaca folder langsung, tanpa input CSV. Edit array
`MODELS` di cell konfigurasi untuk memilih `tiny`, `base`, `small`, dan lainnya:

```python
MODELS = [
    {"name": "base", "backend": "whisper", "model": "base"},
    {"name": "small", "backend": "whisper", "model": "small"},
    {"name": "parakeet_v3", "backend": "nemo", "model": "nvidia/parakeet-tdt-0.6b-v3", "pretrained": True},
    # {"name": "local_nemo", "backend": "nemo", "model": "~/Downloads/YOUR_MODEL.nemo"},
    # {"name": "finetuned", "backend": "huggingface", "model": "norillalearning/YOUR_MODEL_REPO"},
]
```

Gunakan nama yang unik. Backend `huggingface` memakai checkpoint Whisper lengkap
dalam format Transformers (bukan adapter LoRA saja atau model CTranslate2).
Isi `model` dengan ID repo model, bukan URL profil organisasi. Jika repo tidak
menyediakan tokenizer/processor, tambahkan `"processor": "openai/whisper-small"`
dengan base yang sesuai dengan model tersebut. Model diunduh saat pertama dipakai;
inferensi berjalan lokal. Implementasi mengikuti [dokumentasi Whisper Hugging Face](https://huggingface.co/docs/transformers/v4.57.1/en/model_doc/whisper).

Untuk checkpoint ASR lokal `.nemo` (misalnya Parakeet), instal dependency tambahan
di kernel notebook sekali:

```python
%pip install -r requirements-nemo.txt
```

Restart kernel, lalu aktifkan entry `backend: "nemo"` dalam `MODELS` dan isi path
file sebenarnya. Path absolut, relatif terhadap folder project, serta `~/Downloads/`
didukung. Loader memakai `ASRModel.restore_from(..., map_location="cpu")` dan
tidak mengunduh checkpoint dari Hugging Face. Hasil NeMo masuk ke kolom per model
yang sama dengan backend lain. File yang hilang atau gagal dimuat dilaporkan sebagai
`load_error` tanpa menghentikan model lain. Checkpoint harus berupa model ASR
dengan API transkripsi standar NeMo dan sample rate 16 kHz. Lihat
[dokumentasi inferensi NeMo](https://docs.nvidia.com/nemo/speech/nightly/asr/inference.html).
Jika checkpoint memiliki adapter tetapi masih menunjuk encoder biasa, loader
memilih kelas encoder adapter yang terdaftar di NeMo sebelum restore. Seluruh
weight tetap dimuat dengan `strict=True`; file checkpoint asli tidak diubah.

Backend `huggingface` di notebook ini khusus checkpoint Whisper Transformers.
Untuk Parakeet, gunakan backend `nemo` dengan path checkpoint lokal atau ID
model NeMo yang dipublikasikan (akses repo tetap dibutuhkan jika privat).
Untuk ID model NeMo yang dipublikasikan, gunakan `backend: "nemo"` dengan
`"pretrained": True` seperti entry `parakeet_v3` di atas. NeMo mengunduh checkpoint
ke cache project saat pertama dipakai, lalu memuatnya dengan loader yang sama.
Model [nvidia/parakeet-tdt-0.6b-v3](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3)
sudah aktif dalam array `MODELS`; hasilnya memakai kolom berawalan `parakeet_v3 |`.
Untuk repo yang nama file checkpoint-nya berbeda dari nama repo, isi `filename`:

```python
{"name": "parakeet_finetuned", "backend": "nemo",
 "model": "norillalearning/parakeet_finetuned", "pretrained": True,
 "filename": "parakeet_fullft_finetuned.nemo"}
```

File ini diunduh langsung melalui Hugging Face Hub menggunakan `HF_TOKEN` dari
`.env`, lalu dimuat dengan NeMo. Repo tersebut berisi checkpoint `.nemo`, sehingga
bukan input untuk backend `huggingface` yang khusus Whisper Transformers.
Kolom ID model di CSV menyertakan nama file checkpoint agar hasil bisa dilacak.

CSV berisi satu baris per file, durasi audio, dan kolom per model: ID model,
transkripsi, intent `decision`, intent `reason`, waktu proses (ms), status dan
pesan error. Setiap run menghasilkan perbandingan baru dan mengganti `OUTPUT_CSV`.
CSV log asli tidak diubah. File WAV baru tidak harus tercatat dalam log.

Semua model memakai audio mono 16 kHz yang sama pada CPU/float32. Backend Whisper
memakai bahasa Inggris, beam size 5 dan prompt kata kunci yang sama. NeMo memakai
pengaturan decoding checkpoint; `LANGUAGE` dan prompt kata kunci Whisper tidak
diteruskan ke NeMo, sehingga perbandingan antarbackend juga mencerminkan perbedaan
decoder. Audio didekode sekali sebelum pengukuran. Waktu proses mencakup inferensi
dan persiapan fitur, tanpa download/loading model, decoding WAV atau klasifikasi
intent. Ini pengukuran satu run, bukan benchmark berulang atau skor akurasi.
Model dijalankan bergiliran; kegagalan suatu model/file dicatat tanpa membatalkan
hasil model lain. Cell terakhir menampilkan ringkasan waktu dan jumlah keberhasilan.

**Notebook batch lainnya menulis hasil ke file `INPUT_CSV`.** Untuk percobaan, salin
CSV lalu ubah `INPUT_CSV` ke path salinan sebelum menjalankan cell batch.
Baris yang sudah mempunyai hasil intent dilewati; kosongkan kolom hasil pada
salinan CSV jika ingin transkripsi ulang.

Untuk notebook lainnya, default CSV adalah `reason_prediction_audio_log.csv`, kecuali notebook appending
yang memakai `fall_prediction_audio_log.csv`. `BATCH_STATE = "default"` menggunakan gabungan
prompt dan menghasilkan `default.unknown` pada tahap awal; cell klasifikasi
berikutnya mengisi intent `decision` dan `reason`.

Perbandingan `intent.ipynb` secara default memakai `tiny` dan `base`.
File audio diproses di mesin lokal; waktu proses tergantung CPU dan panjang audio.
