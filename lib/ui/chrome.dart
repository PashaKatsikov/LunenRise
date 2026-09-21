import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/art.dart';
import '../game/atlas.dart';
import '../game/paths.dart';
import 'c.dart';

class Sprite extends StatelessWidget {
  final String id;
  final double height;
  final bool glow;

  const Sprite(this.id, {super.key, required this.height, this.glow = false});

  @override
  Widget build(BuildContext context) {
    final f = Atlas.frame(id);
    final img = Art.sheet(f.sheet);
    final w = height * (f.w / f.h);
    return CustomPaint(
      size: Size(w, height),
      painter: _SpritePainter(img, f.src, glow),
    );
  }
}

class FilePic extends StatelessWidget {
  final String path;
  final BoxFit fit;
  const FilePic(this.path, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FullPainter(Art.file(path), fit),
      child: const SizedBox.expand(),
    );
  }
}

class _FullPainter extends CustomPainter {
  final ui.Image img;
  final BoxFit fit;
  _FullPainter(this.img, this.fit);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final FittedSizes fs = applyBoxFit(fit, src.size, size);
    final dst = Alignment.center.inscribe(fs.destination, Offset.zero & size);
    final s = Alignment.center.inscribe(fs.source, src);
    canvas.drawImageRect(
      img,
      s,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _FullPainter old) =>
      old.img != img || old.fit != fit;
}

class _SpritePainter extends CustomPainter {
  final ui.Image img;
  final Rect src;
  final bool glow;
  _SpritePainter(this.img, this.src, this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Offset.zero & size;
    if (glow) {
      canvas.drawImageRect(
        img,
        src,
        dst.inflate(3),
        Paint()
          ..colorFilter = const ColorFilter.mode(
            Color(0x66FFF2A0),
            BlendMode.srcATop,
          )
          ..filterQuality = FilterQuality.low,
      );
    }
    canvas.drawImageRect(
      img,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _SpritePainter old) =>
      old.img != img || old.src != src || old.glow != glow;
}

class Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final double maxWidth;
  final double maxHeight;

  const Panel({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.maxWidth = 640,
    this.maxHeight = 420,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final w = maxWidth.clamp(240.0, screen.width * 0.94);
    final h = maxHeight.clamp(180.0, screen.height * 0.92);
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: w,
        height: h,
        child: CustomPaint(
          painter: const _PanelPainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: T.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onClose != null)
                      _RoundIcon(icon: Icons.close_rounded, onTap: onClose!),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelPainter extends CustomPainter {
  const _PanelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    canvas.drawRRect(r, Paint()..color = C.panel);
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..shader = const LinearGradient(
          colors: [C.line, C.line2, C.line],
        ).createShader(Offset.zero & size),
    );
    final inner = r.deflate(5);
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x33FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF3A4A88), Color(0xFF1A2458)],
          ),
          border: Border.all(color: C.line, width: 1.2),
        ),
        child: Icon(icon, size: 18, color: C.text),
      ),
    );
  }
}

class PillBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final List<Color> colors;
  final double height;
  final double? width;
  final double size;

  const PillBtn(
    this.label, {
    super.key,
    this.onTap,
    this.colors = const [C.gold, C.gold2],
    this.height = 44,
    this.width,
    this.size = 16,
  });

  factory PillBtn.green(
    String label, {
    VoidCallback? onTap,
    double? width,
    double height = 48,
  }) {
    return PillBtn(
      label,
      onTap: onTap,
      colors: const [C.mint, C.mint2],
      width: width,
      height: height,
      size: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
            border: Border.all(color: Colors.white24, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size,
                letterSpacing: 0.8,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SideBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const SideBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3D4F9A), Color(0xFF1A275C)],
          ),
          border: Border.all(color: C.line, width: 1.3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: C.gold, size: 22),
            const SizedBox(height: 2),
            Text(label, style: T.num.copyWith(fontSize: 10, color: C.gold)),
          ],
        ),
      ),
    );
  }
}

class ChipRes extends StatelessWidget {
  final String sprite;
  final String value;
  const ChipRes({super.key, required this.sprite, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.fromLTRB(6, 3, 10, 3),
      decoration: BoxDecoration(
        color: C.chip,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x55F4C24A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Sprite(sprite, height: 22),
          const SizedBox(width: 4),
          Text(value, style: T.num),
        ],
      ),
    );
  }
}

class Logo extends StatelessWidget {
  final double height;
  const Logo({super.key, this.height = 160});

  @override
  Widget build(BuildContext context) {
    final img = Art.file(Paths.logo);
    final w = height * (img.width / img.height);
    return CustomPaint(
      size: Size(w, height),
      painter: _FullPainter(img, BoxFit.contain),
    );
  }
}

class Dim extends StatelessWidget {
  final VoidCallback? onTap;
  const Dim({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(color: const Color(0xB4000000)),
    );
  }
}
