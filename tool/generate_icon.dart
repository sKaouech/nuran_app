// Script outil : génère l'icône PNG 1024×1024 de Nuran en utilisant dart:ui.
// Exécution : `flutter test tool/generate_icon.dart` (pour avoir dart:ui dispo)
//
// Le logo représente la lettre ن (nūn) sur fond vert sapin, avec un halo
// or rappelant la lumière (Nūr).

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

const int size = 1024;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Génère l\'icône PNG Nuran', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final center = const Offset(size / 2, size / 2);

    // 1. Fond circulaire vert sapin
    canvas.drawCircle(
      center,
      size / 2,
      Paint()..color = const Color(0xFF1B5E4F),
    );

    // 2. Halos or
    canvas.drawCircle(
      center,
      420,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFB8860B).withValues(alpha: 0.4)
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      center,
      380,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFB8860B).withValues(alpha: 0.25)
        ..strokeWidth = 2,
    );

    // 3. Étoile à 8 branches en arrière-plan
    _drawEightPointStar(
      canvas,
      center,
      320,
      const Color(0xFFB8860B).withValues(alpha: 0.18),
    );

    // 4. Lettre ن (nūn) stylisée en blanc crème
    final nunPaint = Paint()..color = const Color(0xFFFFFBF5);
    final bolPath = Path()
      ..moveTo(300, 470)
      ..quadraticBezierTo(300, 720, 512, 720)
      ..quadraticBezierTo(724, 720, 724, 470)
      ..lineTo(670, 470)
      ..quadraticBezierTo(670, 670, 512, 670)
      ..quadraticBezierTo(354, 670, 354, 470)
      ..close();
    canvas.drawPath(bolPath, nunPaint);
    canvas.drawCircle(const Offset(512, 370), 42, nunPaint);

    // 5. Rayons or sous le ن
    canvas.drawLine(
      const Offset(512, 760),
      const Offset(512, 830),
      Paint()
        ..color = const Color(0xFFB8860B).withValues(alpha: 0.7)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    final sidePaint = Paint()
      ..color = const Color(0xFFB8860B).withValues(alpha: 0.5)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        const Offset(442, 780), const Offset(412, 820), sidePaint);
    canvas.drawLine(
        const Offset(582, 780), const Offset(612, 820), sidePaint);

    // Finalize et convertir en PNG
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    expect(byteData, isNotNull);

    final bytes = byteData!.buffer.asUint8List();
    final file = File('assets/branding/icon.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    // ignore: avoid_print
    print('✓ Icône générée : ${file.path} (${bytes.length} bytes)');
  });
}

void _drawEightPointStar(Canvas canvas, Offset center, double radius, Color color) {
  final paint = Paint()..color = color;
  for (final rotation in [0.0, math.pi / 4]) {
    final path = Path();
    final tipLen = radius;
    final waistLen = radius * 0.55;
    for (var i = 0; i < 16; i++) {
      final angle = rotation + (i * math.pi / 8);
      final r = i.isEven ? tipLen : waistLen;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
