import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:shot_on_iphone/watermark/watermark.dart';

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final String text;
  final TextStyle style;
  final logo;
  final bool showlogo;
  final int position;

  ImagePainter({
    required this.image,
    required this.text,
    required this.style,
    required this.showlogo,
    required this.position,
    this.logo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Watermark.draw(canvas, image, text, style, size, logo, showlogo, position);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
