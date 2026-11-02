import 'dart:async';
import 'dart:convert';

import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;

/// Resultado de la geocodificación de una dirección.
class GeoResult {
  final double lat;
  final double lng;
  /// true = coordenada confiable. false = sólo se pudo ubicar la comuna/barrio.
  final bool preciso;
  final String? comunaInferida;

  GeoResult({
    required this.lat,
    required this.lng,
    required this.preciso,
    this.comunaInferida,
  });
}

/// Geocodificación de direcciones colombianas (Cali) de forma robusta.
///
/// El problema original: direcciones tipo "Cra 52A # 16-58" se enviaban con la
/// comuna pegada y sin normalizar, lo que hacía que el geocoder devolviera un
/// punto de otra comuna. Aquí se normaliza la dirección, se busca la calle
/// exacta acotada a la zona de Cali y se valida contra la comuna indicada.
class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  static const double _caliLatMin = 3.25;
  static const double _caliLatMax = 3.60;
  static const double _caliLngMin = -76.70;
  static const double _caliLngMax = -76.35;

  static const Map<String, String> _roadNames = {
    'cra': 'Carrera',
    'crr': 'Carrera',
    'carr': 'Carrera',
    'kr': 'Carrera',
    'kra': 'Carrera',
    'cr': 'Carrera',
    'cll': 'Calle',
    'cl': 'Calle',
    'ca': 'Calle',
    'tv': 'Transversal',
    'tra': 'Transversal',
    'tr': 'Transversal',
    'transv': 'Transversal',
    'diag': 'Diagonal',
    'dg': 'Diagonal',
    'av': 'Avenida',
    'avn': 'Avenida',
    'autop': 'Autopista',
    'clz': 'Calzada',
    'cc': 'Circular',
  };

  static const String _userAgent = 'DonaEduca-App/1.0 (contacto: donaeduca.app@gmail.com)';

  /// Normaliza una dirección colombiana para que sea entendible por un geocoder.
  /// Ej: "cra52a#16-58" -> "Carrera 52A # 16 - 58"
  static String normalizeDireccion(String direccion) {
    var s = direccion.trim().replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll('#', ' # ');
    s = s.replaceAll(' - ', '-');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Abreviaciones pegadas o casi pegadas al número: "cra52a", "cll 16", "av. 3N"...
    s = s.replaceAllMapped(
      RegExp(r'\b(cra|crr|carr|kr|kra|cr|cll|cl|ca|tv|tra|tr|transv|diag|dg|av|avn|autop|clz|cc)\s*\.?\s*(?=\d)', caseSensitive: false),
      (m) => '${_roadNames[m.group(1)!.toLowerCase()] ?? m.group(0)!} ',
    );

    // Nombres completos / variantes con espacio, por si llegaron como tal.
    final rules = <(RegExp, String)>[
      (RegExp(r'\bautopista\b', caseSensitive: false), 'Autopista'),
      (RegExp(r'\bavenida\b|\bav\.?\b|\bave\.?\b|\bav\.s\b', caseSensitive: false), 'Avenida'),
      (RegExp(r'\bdiagonal\b|\bdiag\.?\b|\bdg\.?\b', caseSensitive: false), 'Diagonal'),
      (RegExp(r'\btransversal\b|\btransv\.?\b|\btv\.?\b|\btra\.?\b|\btr\.?\b', caseSensitive: false), 'Transversal'),
      (RegExp(r'\bcarrera\b|\bcarr\.?\b|\bcrr\.?\b|\bkra\.?\b|\bcra\.?\b|\bkr\.?\b|\bcr\.?\b', caseSensitive: false), 'Carrera'),
      (RegExp(r'\bcalle\b|\bcll\.?\b|\bcl\.?\b|\bcal\.?\b', caseSensitive: false), 'Calle'),
      (RegExp(r'\bcalzada\b|\bclz\.?\b', caseSensitive: false), 'Calzada'),
      (RegExp(r'\bcircular\b|\bcirc\.?\b|\bcc\.?\b', caseSensitive: false), 'Circular'),
      (RegExp(r'\bpasaje\b', caseSensitive: false), 'Pasaje'),
      (RegExp(r'\bpaseo\b', caseSensitive: false), 'Paseo'),
      (RegExp(r'\bvía\b|\bvia\b', caseSensitive: false), 'Vía'),
    ];
    for (final (regex, replacement) in rules) {
      s = s.replaceAll(regex, replacement);
    }

    s = s.replaceAll('#', ' #');
    s = s.replaceAll(' - ', '-');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Geocodifica una dirección (preferiblemente en Cali, Colombia).
  ///
  /// Estrategia:
  ///  1. Busca la calle exacta (sin la comuna en el texto) acotada a Cali.
  ///  2. Valida la comuna/barrio del resultado contra la comuna indicada.
  ///  3. Si no hay coincidencia, cae al centroide de la comuna (coarse).
  Future<GeoResult?> geocodeDireccion({
    required String direccion,
    String? comuna,
  }) async {
    final dirNorm = normalizeDireccion(direccion);
    if (dirNorm.isEmpty) return null;
    final roadLower = _roadPart(dirNorm);
    final wantsCali = !dirNorm.toLowerCase().contains('cali');

    final candidates = <_Cand>[];

    // 1) Nominatim (OpenStreetMap) acotado a Colombia y a la caja de Cali.
    final queries = <String>[
      if (wantsCali) '$dirNorm, Cali, Colombia' else dirNorm,
      if (wantsCali) '$dirNorm, Santiago de Cali' else dirNorm,
    ];
    for (final q in queries) {
      try {
        final res = await _nominatimSearch(q);
        for (final r in res) {
          final cand = _Cand.fromNominatim(r);
          if (!_enCali(cand.lat, cand.lng)) continue;
          candidates.add(cand);
          if (candidates.length >= 6) break;
        }
      } catch (_) {}
      if (candidates.length >= 6) break;
    }

    // 2) Geocoder de la plataforma (Google en Android / Apple en iOS).
    try {
      final places = await geo.Geocoding()
          .locationFromAddress('$dirNorm, Cali, Colombia')
          .timeout(const Duration(seconds: 8));
      for (final p in places.take(3)) {
        if (!_enCali(p.latitude, p.longitude)) continue;
        final cand = _Cand(lat: p.latitude, lng: p.longitude, source: 'platform');
        final rev = await _nominatimReverse(cand.lat, cand.lng);
        if (rev != null) {
          cand.road = rev['address']?['road'] as String?;
          cand.comuna = _comunaDe(rev['address']);
          cand.suburb = rev['address']?['suburb'] as String? ?? rev['display_name']?.toString();
        }
        candidates.add(cand);
      }
    } catch (_) {}

    // 3) Puntuar y elegir el mejor candidato.
    for (final c in candidates) {
      _score(c, roadLower, comuna);
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));

    if (candidates.isNotEmpty && candidates.first.score > 0) {
      final best = candidates.first;
      return GeoResult(
        lat: best.lat,
        lng: best.lng,
        preciso: true,
        comunaInferida: best.comuna ?? best.suburb,
      );
    }

    // 4) Fallback: centroide de la comuna/barrio.
    return _geocodeComuna(comuna);
  }

  Future<GeoResult?> _geocodeComuna(String? comuna) async {
    if (comuna == null || comuna.trim().isEmpty) return null;
    final text = comuna.trim();
    final numero = _comunaNumero(text);

    final queries = <String>[
      if (numero != null) 'Comuna $numero, Cali, Colombia',
      '$text, Cali, Colombia',
    ];

    for (final q in queries) {
      try {
        final res = await _nominatimSearch(q);
        for (final r in res) {
          final cand = _Cand.fromNominatim(r);
          if (!_enCali(cand.lat, cand.lng)) continue;
          return GeoResult(lat: cand.lat, lng: cand.lng, preciso: false, comunaInferida: text);
        }
      } catch (_) {}
    }

    try {
      final places = await geo.Geocoding()
          .locationFromAddress('$text, Cali, Colombia')
          .timeout(const Duration(seconds: 8));
      for (final p in places.take(3)) {
        if (!_enCali(p.latitude, p.longitude)) continue;
        return GeoResult(lat: p.latitude, lng: p.longitude, preciso: false, comunaInferida: text);
      }
    } catch (_) {}

    return null;
  }

  // --- Helpers ---

  static Future<List<Map<String, dynamic>>> _nominatimSearch(String q) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '8',
      'countrycodes': 'co',
      'viewbox': '-76.80,3.70,-76.30,3.15',
      'bounded': '1',
    });
    final res = await http.get(uri, headers: {
      'User-Agent': _userAgent,
      'Referer': 'https://donaeduca.app',
    }).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body) as List<dynamic>;
    return body.whereType<Map<String, dynamic>>().toList();
  }

  static Future<Map<String, dynamic>?> _nominatimReverse(double lat, double lng) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'addressdetails': '1',
      'format': 'jsonv2',
    });
    final res = await http.get(uri, headers: {
      'User-Agent': _userAgent,
      'Referer': 'https://donaeduca.app',
    }).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Extrae la parte de "calle/avenida" de una dirección normalizada.
  /// Ej: "Carrera 52A # 16 - 58" -> "carrera 52a"
  static String _roadPart(String dirNorm) {
    final cleaned = dirNorm.toLowerCase();
    final m = RegExp(r'\b(carrera|calle|transversal|diagonal|avenida|autopista|circular|calzada|pasaje|paseo|vía)\s+([0-9]+[a-z]*)')
        .firstMatch(cleaned);
    if (m != null) return '${m.group(1)} ${m.group(2)}';
    final cleanedNoHash = dirNorm.toLowerCase().split('#').first.trim();
    return cleanedNoHash;
  }

  static bool _enCali(double lat, double lng) =>
      lat >= _caliLatMin && lat <= _caliLatMax && lng >= _caliLngMin && lng <= _caliLngMax;

  static String? _comunaDe(Map<String, dynamic>? address) {
    if (address == null) return null;
    final candidates = ['city_district', 'suburb', 'district', 'neighbourhood'];
    for (final key in candidates) {
      final v = address[key];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  static int? _comunaNumero(String? text) {
    if (text == null) return null;
    final m = RegExp(r'comuna\s*(\d+)', caseSensitive: false).firstMatch(text);
    return m != null ? int.tryParse(m.group(1)!) : null;
  }

  static void _score(_Cand c, String roadLower, String? comuna) {
    var score = 0;

    final roadKey = roadLower.replaceAll(RegExp(r'\s+'), '');
    final candRoad = (c.road ?? '').toLowerCase().replaceAll(RegExp(r'[\.\s]'), '');
    if (roadKey.isNotEmpty && candRoad.isNotEmpty && candRoad.contains(roadKey)) {
      score += 100;
    }

    final candComuna = _comunaNumero(c.comuna);
    final statedComuna = _comunaNumero(comuna);
    if (candComuna != null && statedComuna != null) {
      score += candComuna == statedComuna ? 50 : -40;
    }

    if (c.isHouse) score += 30;

    c.score = score;
  }
}

class _Cand {
  final double lat;
  final double lng;
  final String source;
  String? road;
  String? comuna;
  String? suburb;
  bool isHouse = false;
  int score = 0;

  _Cand({required this.lat, required this.lng, required this.source});

  factory _Cand.fromNominatim(Map<String, dynamic> r) {
    final address = r['address'] as Map<String, dynamic>?;
    final cand = _Cand(
      lat: double.tryParse(r['lat']?.toString() ?? '') ?? 0,
      lng: double.tryParse(r['lon']?.toString() ?? '') ?? 0,
      source: 'nominatim',
    );
    cand.road = address?['road'] as String?;
    cand.suburb = address?['suburb'] as String?;
    cand.comuna = _Cand._comunaCandidata(address, r['display_name']?.toString());
    cand.isHouse = (r['addresstype'] == 'house' ||
        r['addresstype'] == 'building' ||
        (address?['building'] != null));
    return cand;
  }

  static String? _comunaCandidata(Map<String, dynamic>? address, String? display) {
    final fromAddr = GeocodingService._comunaDe(address);
    if (fromAddr != null) return fromAddr;
    if (display != null) {
      final m = RegExp(r'comuna\s*\d+', caseSensitive: false).firstMatch(display);
      if (m != null) return m.group(0);
    }
    return null;
  }
}