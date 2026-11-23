import 'package:flutter/services.dart';
import 'package:hyphenation/hyphenation.dart' as hyph;
import 'package:book_reader_app/features/reader/data/parsers/text_paginator.dart'
    show Hyphenator;

/// Singleton-обёртка над hyphenation для русского языка.
/// Кэш результатов живёт в hyph.Hyphenator и переиспользуется
/// между вызовами — смена шрифта не сбрасывает кэш.
class RuHyphenator implements Hyphenator {
  final hyph.Hyphenator _impl;

  RuHyphenator(this._impl);

  @override
  List<int> breakPositions(String word) {
    if (word.length < 5) return const [];  // 2 слева + 1 дефис + 2 справа минимум
    try {
      return _impl.breakOffsets(word);
    } catch (_) {
      return const [];  // защита от неожиданных слов
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