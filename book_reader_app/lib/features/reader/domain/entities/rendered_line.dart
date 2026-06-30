import 'package:flutter/painting.dart';

class RenderedLine {
  final String text;
  final TextStyle style;
  final double offsetX;
  final double offsetY;
  final double height;
  final bool isHyphenated;
  final TextAlign textAlign;   
  final double lineWidth;      

  const RenderedLine({
    required this.text,
    required this.style,
    required this.offsetX,
    required this.offsetY,
    required this.height,
    this.isHyphenated = false,
    this.textAlign = TextAlign.justify,
    required this.lineWidth,
  });
}