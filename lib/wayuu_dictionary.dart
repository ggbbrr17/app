/// Servicio de diccionario Wayuunaiki ↔ Español 100% offline.
///
/// Carga un mapa estático con ~1 360 entradas extraídas de
/// pueblosoriginarios.com/lenguas/wayuu.php y ofrece:
///   • Búsqueda bidireccional (wayuunaiki→español, español→wayuunaiki)
///   • Traducción palabra-por-palabra de frases
///   • Búsqueda difusa (fuzzy) por similitud
///   • Sugerencias de autocompletado
///   • Glosario médico/nutricional prioritario

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class WayuuDictionary {
  // Singleton
  static final WayuuDictionary _instance = WayuuDictionary._();
  factory WayuuDictionary() => _instance;
  WayuuDictionary._();

  /// wayuunaiki → español  (clave en minúsculas)
  Map<String, String> _wayToEsp = {};

  /// español → wayuunaiki  (clave en minúsculas)
  Map<String, String> _espToWay = {};

  /// Lista de todas las claves wayuunaiki para autocompletado
  List<String> _wayKeys = [];

  /// Lista de todas las claves español para autocompletado
  List<String> _espKeys = [];

  bool _loaded = false;

  // ─── Glosario médico/nutricional prioritario (siempre disponible) ──────────
  static const Map<String, String> medicalGlossary = {
    // Cuerpo y salud
    'anasü': 'salud, estar bien',
    'ayuulii': 'enfermedad, estar enfermo',
    'tepichi': 'niño',
    'jintüt': 'nombre (del niño)',
    'jintü': 'niña',
    'kachon': 'edad en meses',
    'nutuma': 'peso',
    'nütüjülü': 'talla, estatura',
    'eküülü': 'comida, alimento',
    'asaa': 'beber',
    'ekaa': 'comer',
    'jawata': 'fiebre',
    'lumaa': 'fiebre',
    'ayollee': 'dolor',
    'asha': 'sangre',
    'aluuwain': 'pecho',
    'asapü': 'espalda',
    'ayee': 'lengua',
    'atüna': 'brazo',
    'asa\'a': 'pierna',
    'aliina': 'muela',
    'ashuku': 'huevo',
    'asalaa': 'carne',
    'wüin': 'agua',
    'kasachiki': 'sal',
    'süchii': 'azúcar',
    'ipa': 'tierra',
    'ka\'i': 'sol, día',
    'kashi': 'luna, mes',
    // Nutrición
    'katsinshi': 'fuerte, sano',
    'aürülaa': 'flaco',
    'waima': 'mucho, bastante',
    'anasü aa\'in': 'bienestar',
    'o\'u': 'barriga, estómago',
    'muac': 'perímetro braquial',
    // Familia
    'ashii': 'padre',
    'ei': 'madre',
    'alüin': 'nieto',
    'atuushi': 'abuelo',
    'awala': 'hermano',
    // Agricultura
    'apünajaa': 'sembrar',
    'wunu\'u': 'árbol, planta',
    'apanai': 'hoja',
    'asii': 'flor',
    'asema': 'leña, fuego',
    'joutai': 'viento',
    'juya': 'lluvia, invierno',
    // Diagnóstico
    'jülüja aa\'in': 'precaución, peligro',
    'cho\'ujaasü': 'necesita, urgente',
    'ataralüichi': 'adulto',
    'piichi': 'casa',
    'wayuu': 'persona, gente',
    'alijuna': 'persona no wayuu',
    'pütchi': 'palabra, mensaje',
    'ekirajaa': 'enseñar, aprender',
  };

  // ─── Inicialización ────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_loaded) return;

    // Cargar diccionario desde asset JSON
    try {
      final jsonStr =
          await rootBundle.loadString('assets/wayuu_dictionary.json');
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      data.forEach((key, value) {
        final k = key.trim().toLowerCase();
        final v = value.toString().trim();
        _wayToEsp[k] = v;
        // Para el reverso, usamos la primera palabra significativa del español
        final espKey = _extractMainWord(v).toLowerCase();
        if (espKey.isNotEmpty) {
          _espToWay[espKey] = key.trim();
        }
      });
    } catch (e) {
      // Si falla el JSON, usar solo el glosario médico
      print('⚠️ wayuu_dictionary.json no encontrado, usando glosario médico');
    }

    // Añadir glosario médico (tiene prioridad)
    medicalGlossary.forEach((way, esp) {
      _wayToEsp[way.toLowerCase()] = esp;
      final espKey = _extractMainWord(esp).toLowerCase();
      if (espKey.isNotEmpty) {
        _espToWay[espKey] = way;
      }
    });

    _wayKeys = _wayToEsp.keys.toList()..sort();
    _espKeys = _espToWay.keys.toList()..sort();
    _loaded = true;
    print('📖 Diccionario Wayuunaiki cargado: ${_wayToEsp.length} entradas');
  }

  String _extractMainWord(String definition) {
    // Quitar prefijos gramaticales como "v.t.", "n.", "adj.", etc.
    String clean = definition
        .replaceAll(RegExp(r'^(v\.[a-z]+\.?|n\.(pos\.)?|adj\.?|adv\.?|posp\.?|conj\.?|interj\.?|pron\.?|abs\.?)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^\d+\.\s*'), '');
    // Tomar primera palabra o frase antes de coma/punto/paréntesis
    final match = RegExp(r'^([^,;.(]+)').firstMatch(clean);
    return match?.group(1)?.trim() ?? clean.trim();
  }

  // ─── Búsquedas ─────────────────────────────────────────────────────────────

  /// Buscar palabra wayuunaiki → definición en español
  String? lookupWayuu(String word) {
    return _wayToEsp[word.toLowerCase().trim()];
  }

  /// Buscar palabra español → wayuunaiki
  String? lookupSpanish(String word) {
    return _espToWay[word.toLowerCase().trim()];
  }

  /// Búsqueda bidireccional: intenta ambos sentidos
  Map<String, String>? lookupAny(String word) {
    final w = word.toLowerCase().trim();
    final espResult = _wayToEsp[w];
    if (espResult != null) {
      return {'wayuunaiki': word, 'español': espResult, 'direction': 'way→esp'};
    }
    final wayResult = _espToWay[w];
    if (wayResult != null) {
      return {'wayuunaiki': wayResult, 'español': word, 'direction': 'esp→way'};
    }
    return null;
  }

  /// Búsqueda difusa: encuentra entradas similares
  List<Map<String, String>> fuzzySearch(String query, {int limit = 10}) {
    final q = query.toLowerCase().trim();
    final results = <Map<String, String>>[];

    // Buscar en claves wayuunaiki
    for (final key in _wayKeys) {
      if (key.contains(q) || q.contains(key)) {
        results.add({
          'wayuunaiki': key,
          'español': _wayToEsp[key]!,
          'match': 'wayuunaiki',
        });
      }
    }

    // Buscar en definiciones español
    _wayToEsp.forEach((way, esp) {
      if (esp.toLowerCase().contains(q)) {
        results.add({
          'wayuunaiki': way,
          'español': esp,
          'match': 'español',
        });
      }
    });

    // Eliminar duplicados
    final seen = <String>{};
    results.retainWhere((r) => seen.add(r['wayuunaiki']!));

    return results.take(limit).toList();
  }

  /// Autocompletado: sugerencias que empiezan con el prefijo
  List<String> autocomplete(String prefix, {bool wayuunaiki = true, int limit = 8}) {
    final p = prefix.toLowerCase().trim();
    final keys = wayuunaiki ? _wayKeys : _espKeys;
    return keys.where((k) => k.startsWith(p)).take(limit).toList();
  }

  /// Traducir frase palabra por palabra (Español → Wayuunaiki)
  String translateToWayuunaiki(String spanishText) {
    final words = spanishText.toLowerCase().split(RegExp(r'\s+'));
    final translated = <String>[];
    final notFound = <String>[];

    for (final word in words) {
      final clean = word.replaceAll(RegExp(r'[^\wáéíóúüñ]'), '');
      if (clean.isEmpty) continue;

      final result = _espToWay[clean];
      if (result != null) {
        translated.add(result);
      } else {
        // Intentar búsqueda parcial en definiciones
        String? found;
        _wayToEsp.forEach((way, esp) {
          if (found == null && esp.toLowerCase().contains(clean)) {
            found = way;
          }
        });
        if (found != null) {
          translated.add(found!);
        } else {
          translated.add('[$clean]');
          notFound.add(clean);
        }
      }
    }

    String result = translated.join(' ');
    if (notFound.isNotEmpty) {
      result += '\n\n⚠️ Palabras sin traducción directa: ${notFound.join(", ")}';
    }
    return result;
  }

  /// Traducir frase palabra por palabra (Wayuunaiki → Español)
  String translateToSpanish(String wayuuText) {
    final words = wayuuText.toLowerCase().split(RegExp(r'\s+'));
    final translated = <String>[];
    final notFound = <String>[];

    for (final word in words) {
      final clean = word.replaceAll(RegExp(r'[^\wáéíóúüñ\'']'), '');
      if (clean.isEmpty) continue;

      final result = _wayToEsp[clean];
      if (result != null) {
        // Extraer significado principal
        translated.add(_extractMainWord(result));
      } else {
        translated.add('[$clean]');
        notFound.add(clean);
      }
    }

    String result = translated.join(' ');
    if (notFound.isNotEmpty) {
      result += '\n\n⚠️ Palabras sin traducción directa: ${notFound.join(", ")}';
    }
    return result;
  }

  /// Detectar idioma de entrada (heurística simple)
  String detectLanguage(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    int wayuuHits = 0;
    int espHits = 0;

    for (final word in words) {
      final clean = word.replaceAll(RegExp(r'[^\wáéíóúüñ\'']'), '');
      if (_wayToEsp.containsKey(clean)) wayuuHits++;
      if (_espToWay.containsKey(clean)) espHits++;
    }

    // Caracteres típicos de wayuunaiki
    if (text.contains("ü") || text.contains("'") && text.contains("aa")) {
      wayuuHits += 2;
    }

    if (wayuuHits > espHits) return 'wayuunaiki';
    if (espHits > wayuuHits) return 'español';
    return 'desconocido';
  }

  /// Traducción automática bidireccional
  String autoTranslate(String text) {
    final lang = detectLanguage(text);
    if (lang == 'wayuunaiki') {
      return '🇪🇸 Español:\n${translateToSpanish(text)}';
    } else {
      return '🌵 Wayuunaiki:\n${translateToWayuunaiki(text)}';
    }
  }

  /// Obtener todo el glosario médico formateado
  String getMedicalGlossaryFormatted() {
    final buffer = StringBuffer();
    buffer.writeln('📋 GLOSARIO MÉDICO WAYUUNAIKI');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    medicalGlossary.forEach((way, esp) {
      buffer.writeln('  $way  →  $esp');
    });
    return buffer.toString();
  }

  /// Estadísticas del diccionario
  Map<String, int> get stats => {
    'total_wayuunaiki': _wayToEsp.length,
    'total_español': _espToWay.length,
    'glosario_medico': medicalGlossary.length,
  };

  bool get isLoaded => _loaded;
}
