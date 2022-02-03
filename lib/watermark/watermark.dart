import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';

Matrix4 sizeToRect(Size src, Rect dst,
    {BoxFit fit = BoxFit.contain, Alignment alignment = Alignment.center}) {
  FittedSizes fs = applyBoxFit(fit, src, dst.size);
  double scaleX = fs.destination.width / fs.source.width;
  double scaleY = fs.destination.height / fs.source.height;
  Size fittedSrc = Size(src.width * scaleX, src.height * scaleY);
  Rect out = alignment.inscribe(fittedSrc, dst);

  return Matrix4.identity()
    ..translate(out.left, out.top)
    ..scale(scaleX, scaleY);
}

class Watermark {
  Watermark.draw(Canvas canvas, ui.Image image, String text, TextStyle style,
      Size size, ui.Image logo, bool showlogo, int position) {
    // 计算四边形的对角线长度
    double dimension =
        math.sqrt(math.pow(size.width, 2) + math.pow(size.height, 2));

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final matrix = sizeToRect(imageSize, Offset.zero & size);
    canvas.transform(matrix.storage);
    canvas.drawImage(image, Offset.zero, Paint());

    math.Point pivotPoint = math.Point(15.0, size.height - 40);

    var yukseklik = (image.height * 2 - pivotPoint.x - 20).roundToDouble();
    var yukseklik2 = (image.height / 1 - pivotPoint.y + 20).roundToDouble();

    //shot on iphone
    var textPainter = TextPainter(
      text: TextSpan(text: "Shot on iPhone", style: style),
      maxLines: null,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
    );
    textPainter.layout(maxWidth: dimension);

    var watermarkMatrix = sizeToRect(
        textPainter.size,
        Offset(pivotPoint.x.toDouble() + 15, pivotPoint.x.toDouble()) &
            Size((image.width / 3.5).roundToDouble(),
                position == 0 ? yukseklik : yukseklik2));
    canvas.transform(watermarkMatrix.storage);
    textPainter.paint(canvas, Offset(showlogo ? 50 : 10, -43));

    // shoted bye
    var textPainterShot = TextPainter(
      text: TextSpan(
          text: "by " + text,
          style: const TextStyle(fontSize: 14, color: Colors.white70)),
      maxLines: null,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
    );
    textPainterShot.layout(maxWidth: dimension);
    textPainterShot.paint(canvas, Offset(showlogo ? 50 : 10, -17));

    //apple logo

    if (showlogo) {
      paintImage(
          canvas: canvas,
          rect: Rect.fromLTWH(0, -45, 42, 42),
          image: logo,
          fit: BoxFit.scaleDown,
          repeat: ImageRepeat.noRepeat,
          scale: 1.0,
          alignment: Alignment.center,
          flipHorizontally: false,
          isAntiAlias: true,
          filterQuality: FilterQuality.high);
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

      canvas.restore();
    }
  }
}
