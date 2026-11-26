import 'package:flutter/services.dart';
import 'package:hyphenation/hyphenation.dart' as hyph;
import 'package:book_reader_app/features/reader/data/parsers/text_paginator.dart'
    show Hyphenator;

/// Singleton-обёртка над hyphenation для русского языка.
/// Кэш результатов живёт в hyph.Hyphenator и переиспользуется
/// между вызовами — смена шрифта не сбрасывает кэш.
class RuHyphenator implements Hyphenator {
  final hyph.Hyphenator _impl;

  /// Кэш: слово → позиции разрыва.
  /// В книге на 6000 параграфов ~587k слов, но уникальных — 30–50k.
  /// Кэш даёт 5-10x ускорение на повторных словах.
  final Map<String, List<int>> _cache = {};

  RuHyphenator(this._impl);

  @override
  List<int> breakPositions(String word) {
    // Кэш первым — до length check, чтобы "и", "в" тоже кэшировались
    final cached = _cache[word];
    if (cached != null) return cached;

    if (word.length < 5) {
      _cache[word] = const [];
      return const [];
    }

    try {
      final result = _impl.breakOffsets(word);
      _cache[word] = result;
      return result;
    } catch (_) {
      _cache[word] = const [];
      return const [];
    }
  }
}

class HyphenatorProvider {
  static Hyphenator? _instance;
  static Future<Hyphenator>? _loading;

  /// Один на приложение. Кэш переживает смену шрифта/размера.
  static Future<Hyphenator> instance() {
    if (_instance != null) return Future.value(_instance!);
    return _loading ??= _load();
  }

  static Future<Hyphenator> _load() async {
    final source = await rootBundle.loadString('assets/patterns/hyph-ru.tex');
    // leftMin: 2 — минимум 2 символа до переноса ("би-блиотека")
    // rightMin: 3 — минимум 3 символа после переноса ("библио-тека")
    final impl = hyph.Hyphenator.fromSource(
      source,
      leftMin: 2,
      rightMin: 3,
    );
    _instance = RuHyphenator(impl);
    return _instance!;
  }
}