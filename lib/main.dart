import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const KebunApp());

// ---------------------------------------------------------------
// APLIKASI
// ---------------------------------------------------------------
class KebunApp extends StatelessWidget {
  const KebunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jadwal Kebun',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const BerandaPage(),
    );
  }
}

// ---------------------------------------------------------------
// MODEL DATA
// ---------------------------------------------------------------
enum JenisKegiatan { tanam, siram, panen }

extension JenisKegiatanInfo on JenisKegiatan {
  String get label {
    switch (this) {
      case JenisKegiatan.tanam:
        return 'Tanam';
      case JenisKegiatan.siram:
        return 'Siram';
      case JenisKegiatan.panen:
        return 'Panen';
    }
  }

  IconData get ikon {
    switch (this) {
      case JenisKegiatan.tanam:
        return Icons.grass;
      case JenisKegiatan.siram:
        return Icons.water_drop;
      case JenisKegiatan.panen:
        return Icons.agriculture;
    }
  }

  Color get warna {
    switch (this) {
      case JenisKegiatan.tanam:
        return Colors.green;
      case JenisKegiatan.siram:
        return Colors.blue;
      case JenisKegiatan.panen:
        return Colors.orange;
    }
  }
}

class Kegiatan {
  final String id;
  final String tanaman;
  final JenisKegiatan jenis;
  final DateTime tanggal;
  final String catatan;
  bool selesai;

  Kegiatan({
    required this.id,
    required this.tanaman,
    required this.jenis,
    required this.tanggal,
    this.catatan = '',
    this.selesai = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanaman': tanaman,
        'jenis': jenis.name,
        'tanggal': tanggal.toIso8601String(),
        'catatan': catatan,
        'selesai': selesai,
      };

  factory Kegiatan.fromJson(Map<String, dynamic> j) => Kegiatan(
        id: j['id'] as String,
        tanaman: j['tanaman'] as String,
        jenis: JenisKegiatan.values.byName(j['jenis'] as String),
        tanggal: DateTime.parse(j['tanggal'] as String),
        catatan: (j['catatan'] ?? '') as String,
        selesai: (j['selesai'] ?? false) as bool,
      );
}

// ---------------------------------------------------------------
// FUNGSI BANTU
// ---------------------------------------------------------------
DateTime hariSaja(DateTime d) => DateTime(d.year, d.month, d.day);

String teksTanggal(DateTime d) {
  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  return '${d.day} ${bulan[d.month - 1]} ${d.year}';
}

// ---------------------------------------------------------------
// HALAMAN BERANDA
// ---------------------------------------------------------------
class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  List<Kegiatan> _semua = [];
  JenisKegiatan? _filter; // null = tampilkan semua
  bool _siap = false;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    final prefs = await SharedPreferences.getInstance();
    final teks = prefs.getString('kegiatan');
    if (teks != null) {
      final data = jsonDecode(teks) as List;
      _semua = data
          .map((e) => Kegiatan.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    setState(() => _siap = true);
  }

  Future<void> _simpanData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'kegiatan',
      jsonEncode(_semua.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _tambah() async {
    final hasil = await Navigator.of(context).push<List<Kegiatan>>(
      MaterialPageRoute(builder: (_) => const FormKegiatanPage()),
    );
    if (hasil != null) {
      setState(() => _semua.addAll(hasil));
      await _simpanData();
    }
  }

  void _hapus(Kegiatan k) {
    setState(() => _semua.remove(k));
    _simpanData();
  }

  void _ubahSelesai(Kegiatan k, bool nilai) {
    setState(() => k.selesai = nilai);
    _simpanData();
  }

  @override
  Widget build(BuildContext context) {
    final hariIni = hariSaja(DateTime.now());

    final daftar = _semua
        .where((k) => _filter == null || k.jenis == _filter)
        .toList();
    daftar.sort((a, b) {
      if (a.selesai != b.selesai) return a.selesai ? 1 : -1;
      return a.tanggal.compareTo(b.tanggal);
    });

    final jumlahTerlambat =
        _semua.where((k) => !k.selesai && k.tanggal.isBefore(hariIni)).length;
    final jumlahHariIni = _semua
        .where((k) => !k.selesai && hariSaja(k.tanggal) == hariIni)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kebun'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambah,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jadwal'),
      ),
      body: !_siap
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _kartuRingkasan(
                              'Hari ini',
                              jumlahHariIni,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _kartuRingkasan(
                              'Terlambat',
                              jumlahTerlambat,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Semua'),
                            selected: _filter == null,
                            onSelected: (_) => setState(() => _filter = null),
                          ),
                          for (final j in JenisKegiatan.values)
                            ChoiceChip(
                              label: Text(j.label),
                              selected: _filter == j,
                              onSelected: (_) => setState(() => _filter = j),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: daftar.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Belum ada jadwal.\nTekan tombol "Tambah Jadwal" di bawah.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 0, 12, 90),
                              itemCount: daftar.length,
                              itemBuilder: (context, i) =>
                                  _itemKegiatan(daftar[i], hariIni),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _kartuRingkasan(String judul, int jumlah, Color warna) {
    return Card(
      color: warna.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              '$jumlah',
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: warna),
            ),
            Text(judul),
          ],
        ),
      ),
    );
  }

  Widget _itemKegiatan(Kegiatan k, DateTime hariIni) {
    final tgl = hariSaja(k.tanggal);
    String status;
    Color warnaStatus;

    if (k.selesai) {
      status = 'Selesai';
      warnaStatus = Colors.grey;
    } else if (tgl.isBefore(hariIni)) {
      status = 'Terlambat';
      warnaStatus = Colors.red;
    } else if (tgl == hariIni) {
      status = 'Hari ini';
      warnaStatus = Colors.orange;
    } else {
      status = '${tgl.difference(hariIni).inDays} hari lagi';
      warnaStatus = Colors.blueGrey;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: k.jenis.warna.withAlpha(40),
          child: Icon(k.jenis.ikon, color: k.jenis.warna),
        ),
        title: Text(
          k.tanaman,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: k.selesai ? TextDecoration.lineThrough : null,
          ),
        ),
        isThreeLine: k.catatan.isNotEmpty,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${k.jenis.label} • ${teksTanggal(k.tanggal)}'),
            Text(
              status,
              style: TextStyle(
                  color: warnaStatus, fontWeight: FontWeight.w600),
            ),
            if (k.catatan.isNotEmpty) Text(k.catatan),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: k.selesai,
              onChanged: (v) => _ubahSelesai(k, v ?? false),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus',
              onPressed: () => _hapus(k),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// HALAMAN FORM TAMBAH JADWAL
// ---------------------------------------------------------------
class FormKegiatanPage extends StatefulWidget {
  const FormKegiatanPage({super.key});

  @override
  State<FormKegiatanPage> createState() => _FormKegiatanPageState();
}

class _FormKegiatanPageState extends State<FormKegiatanPage> {
  static const _contohTanaman = [
    'Kelapa Sawit',
    'Karet',
    'Kopi',
    'Kakao',
    'Kelapa',
    'Teh',
    'Cengkeh',
    'Lada',
  ];

  final _tanamanC = TextEditingController();
  final _catatanC = TextEditingController();
  final _intervalC = TextEditingController(text: '2');
  final _jumlahC = TextEditingController(text: '10');

  JenisKegiatan _jenis = JenisKegiatan.tanam;
  DateTime _tanggal = hariSaja(DateTime.now());
  bool _ulang = false;

  @override
  void dispose() {
    _tanamanC.dispose();
    _catatanC.dispose();
    _intervalC.dispose();
    _jumlahC.dispose();
    super.dispose();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _pilihTanggal() async {
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (dipilih != null) {
      setState(() => _tanggal = hariSaja(dipilih));
    }
  }

  void _simpan() {
    final nama = _tanamanC.text.trim();
    if (nama.isEmpty) {
      _pesan('Isi nama tanaman dulu');
      return;
    }

    int jumlah = 1;
    int interval = 1;

    if (_jenis == JenisKegiatan.siram && _ulang) {
      interval = int.tryParse(_intervalC.text) ?? 0;
      jumlah = int.tryParse(_jumlahC.text) ?? 0;
      if (interval < 1 || jumlah < 1 || jumlah > 100) {
        _pesan('Interval minimal 1 hari, jumlah 1 sampai 100');
        return;
      }
    }

    final dasarId = DateTime.now().microsecondsSinceEpoch;
    final hasil = <Kegiatan>[];
    for (var i = 0; i < jumlah; i++) {
      hasil.add(
        Kegiatan(
          id: '${dasarId}_$i',
          tanaman: nama,
          jenis: _jenis,
          tanggal: DateTime(
            _tanggal.year,
            _tanggal.month,
            _tanggal.day + (interval * i),
          ),
          catatan: _catatanC.text.trim(),
        ),
      );
    }

    Navigator.of(context).pop(hasil);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Jadwal')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _tanamanC,
                decoration: const InputDecoration(
                  labelText: 'Nama tanaman',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in _contohTanaman)
                    ActionChip(
                      label: Text(t),
                      onPressed: () => setState(() => _tanamanC.text = t),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Jenis kegiatan'),
              const SizedBox(height: 8),
              SegmentedButton<JenisKegiatan>(
                segments: [
                  for (final j in JenisKegiatan.values)
                    ButtonSegment(
                      value: j,
                      label: Text(j.label),
                      icon: Icon(j.ikon),
                    ),
                ],
                selected: {_jenis},
                onSelectionChanged: (s) => setState(() => _jenis = s.first),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _pilihTanggal,
                icon: const Icon(Icons.calendar_today),
                label: Text('Tanggal: ${teksTanggal(_tanggal)}'),
              ),
              if (_jenis == JenisKegiatan.siram) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Ulangi penyiraman'),
                  subtitle: const Text('Buat jadwal siram otomatis'),
                  value: _ulang,
                  onChanged: (v) => setState(() => _ulang = v),
                ),
                if (_ulang)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _intervalC,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tiap berapa hari',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _jumlahC,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Berapa kali',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _catatanC,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (boleh kosong)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _simpan,
                icon: const Icon(Icons.save),
                label: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}