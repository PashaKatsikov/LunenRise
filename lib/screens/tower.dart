import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/atlas.dart';
import '../game/catalog.dart';
import '../game/game.dart';
import '../ui/c.dart';
import '../ui/chrome.dart';
import 'sheets.dart';

class TowerScreen extends StatefulWidget {
  final LumenGame game;
  const TowerScreen({super.key, required this.game});

  @override
  State<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends State<TowerScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _tick;
  final _box = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tick = createTicker(_on)..start();
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  int _paint = 0;

  void _on(Duration t) {
    if (!_tick.isActive) return;
    if (widget.game.powerSave && (++_paint).isOdd) return;
    if (mounted) setState(() {});
  }

  void _tap(TapDownDetails d) {
    final box = _box.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final l = box.globalToLocal(d.globalPosition);
    final s = box.size;
    widget.game.tapWorld(OffsetN(l.dx / s.width, l.dy / s.height));
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return Scaffold(
      backgroundColor: C.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FilePic(g.bgFor(g.floor)),
          GestureDetector(
            onTapDown: _tap,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              key: _box,
              fit: StackFit.expand,
              children: [_World(game: g)],
            ),
          ),
          _Hud(game: g),
          if (g.placing)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PillBtn(
                  'CANCEL',
                  onTap: g.cancelPlace,
                  colors: const [C.danger, Color(0xFF9A2030)],
                ),
              ),
            ),
          if (g.toast != null)
            Align(
              alignment: const Alignment(0, -0.72),
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xE0121C44),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: C.gold.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    g.toast!,
                    style: T.body,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          if (g.sheet != SheetKind.none) SheetLayer(game: g),
        ],
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  final LumenGame game;
  const _Hud({required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Column(
          children: [
            Row(
              children: [
                _Round(Icons.arrow_back_rounded, onTap: g.back),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChipRes(sprite: 'coins_0', value: compact(g.coins)),
                        const SizedBox(width: 6),
                        ChipRes(sprite: 'fruits_a_0', value: compact(g.fruits)),
                        const SizedBox(width: 6),
                        ChipRes(sprite: 'stars_0', value: compact(g.stars)),
                      ],
                    ),
                  ),
                ),
                _FloorBadge(
                  floor: g.floor,
                  onTap: () => g.openSheet(SheetKind.floors),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      children: [
                        ChipRes(
                          sprite: 'advanced_bells_0',
                          value: compact(g.light),
                        ),
                        const SizedBox(width: 6),
                        ChipRes(
                          sprite: 'lumen_core',
                          value: compact(g.lumenCore),
                        ),
                        const SizedBox(width: 8),
                        _Round(
                          Icons.inventory_2_rounded,
                          onTap: () => g.openSheet(SheetKind.resources),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Expanded(child: IgnorePointer(child: SizedBox.expand())),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: [
                    SideBtn(
                      icon: Icons.construction_rounded,
                      label: 'BUILD',
                      onTap: () => g.openSheet(SheetKind.build),
                    ),
                    const SizedBox(height: 8),
                    SideBtn(
                      icon: Icons.upgrade_rounded,
                      label: 'UPGRADES',
                      onTap: () => g.openSheet(SheetKind.upgrades),
                    ),
                  ],
                ),
                const Expanded(child: IgnorePointer(child: SizedBox.shrink())),
                Column(
                  children: [
                    if (g.event != null)
                      SideBtn(
                        icon: Icons.bolt_rounded,
                        label: 'EVENT',
                        onTap: () => g.openSheet(SheetKind.event),
                      ),
                    if (g.event != null) const SizedBox(height: 8),
                    SideBtn(
                      icon: Icons.map_rounded,
                      label: 'FLOORS',
                      onTap: () => g.openSheet(SheetKind.floors),
                    ),
                    const SizedBox(height: 8),
                    if (g.canAscend)
                      SideBtn(
                        icon: Icons.keyboard_double_arrow_up_rounded,
                        label: 'ASCEND',
                        onTap: g.offerAscend,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Round extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Round(this.icon, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: C.chip,
          border: Border.all(color: C.line, width: 1.2),
        ),
        child: Icon(icon, color: C.text, size: 22),
      ),
    );
  }
}

class _FloorBadge extends StatelessWidget {
  final int floor;
  final VoidCallback onTap;
  const _FloorBadge({required this.floor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF2A3A7A), Color(0xFF151B44)],
          ),
          border: Border.all(color: C.gold, width: 1.4),
        ),
        child: Text('FLOOR $floor', style: T.title.copyWith(fontSize: 14)),
      ),
    );
  }
}

class _World extends StatelessWidget {
  final LumenGame game;
  const _World({required this.game});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final g = game;
        final floor = g.here;
        final pts = <Offset>[];
        for (final s in floor.slots) {
          if (s.building?.active == true) {
            pts.add(Offset(s.pos.x * w, s.pos.y * h - 28));
          }
        }

        final bits = <_Bit>[];

        for (final d in floor.deco) {
          bits.add(_Bit(d.pos.y, _spr(d.sprite, d.h, d.pos, w, h, feet: 0.92)));
        }
        for (final s in floor.slots) {
          if (!s.open && s.building == null) {
            if (g.placing) {
              bits.add(
                _Bit(
                  s.pos.y,
                  _spr(
                    s.lightPlat
                        ? 'light_platforms_${s.plat}'
                        : 'platforms_${s.plat}',
                    78,
                    s.pos,
                    w,
                    h,
                    feet: 0.55,
                    opacity: 0.38,
                  ),
                ),
              );
            }
            continue;
          }
          bits.add(
            _Bit(
              s.pos.y,
              _spr(
                s.lightPlat
                    ? 'light_platforms_${s.plat}'
                    : 'platforms_${s.plat}',
                s.lightPlat ? 86 : 80,
                s.pos,
                w,
                h,
                feet: 0.52,
              ),
            ),
          );
          final b = s.building;
          if (b != null) {
            final def = Catalog.tryItem(b.defId);
            if (def != null) {
              const tallIds = {
                'grand_bell',
                'arch',
                'observatory',
                'energy_core',
              };
              final tall = tallIds.contains(def.sprite);
              bits.add(
                _Bit(
                  s.pos.y + 0.001,
                  _spr(
                    def.sprite,
                    tall ? 118 : 92,
                    OffsetN(s.pos.x, s.pos.y - 0.07),
                    w,
                    h,
                    feet: 0.88,
                    glow: b.active,
                    pulse: b.active ? 1 + sin(b.pulse * 3) * 0.04 : 1,
                  ),
                ),
              );
              if (b.level > 1) {
                bits.add(
                  _Bit(
                    s.pos.y + 0.002,
                    Positioned(
                      left: s.pos.x * w - 14,
                      top: s.pos.y * h - 22,
                      child: IgnorePointer(
                        child: Container(
                          width: 28,
                          height: 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xCC121C44),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: C.gold, width: 1),
                          ),
                          child: Text(
                            'Lv${b.level}',
                            style: T.num.copyWith(fontSize: 9, color: C.gold),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
          } else if (g.placing && s.open) {
            bits.add(
              _Bit(
                s.pos.y,
                Positioned(
                  left: s.pos.x * w - 9,
                  top: s.pos.y * h - 28,
                  child: IgnorePointer(
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: C.mint.withValues(alpha: 0.7),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        }
        for (final p in g.pickups) {
          final bob = sin(g.time * 3.2 + p.phase) * 6;
          bits.add(
            _Bit(
              p.pos.y,
              _spr(g.pickupSprite(p), 36, p.pos, w, h, feet: 0.5, bob: bob),
            ),
          );
        }
        bits.sort((a, b) => a.y.compareTo(b.y));
        bits.add(
          _Bit(g.r.y, _spr(g.rSprite, 62, g.r, w, h, feet: 0.9, glow: true)),
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _NetPainter(pts, g.time)),
            ...bits.map((e) => e.w),
            CustomPaint(painter: _SparkPainter(g, w, h)),
          ],
        );
      },
    );
  }

  Widget _spr(
    String id,
    double height,
    OffsetN p,
    double w,
    double h, {
    required double feet,
    bool glow = false,
    double pulse = 1,
    double bob = 0,
    double opacity = 1,
  }) {
    final f = Atlas.frame(id);
    final hh = height * pulse;
    final ww = hh * (f.w / f.h);
    return Positioned(
      left: p.x * w - ww / 2,
      top: p.y * h - hh * feet + bob,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Sprite(id, height: hh, glow: glow),
        ),
      ),
    );
  }
}

class _Bit {
  final double y;
  final Widget w;
  _Bit(this.y, this.w);
}

class _NetPainter extends CustomPainter {
  final List<Offset> pts;
  final double t;
  _NetPainter(this.pts, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const Color(0x55FFE27A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = const LinearGradient(
        colors: [Color(0xFF7CF4FF), Color(0xFFFFE27A)],
      ).createShader(Offset.zero & size);
    for (var i = 0; i < pts.length; i++) {
      for (var j = i + 1; j < pts.length; j++) {
        if ((pts[i] - pts[j]).distance > size.width * 0.46) continue;
        final mid = Offset(
          (pts[i].dx + pts[j].dx) / 2,
          min(pts[i].dy, pts[j].dy) - 18 - sin(t * 2 + i) * 4,
        );
        final path = Path()
          ..moveTo(pts[i].dx, pts[i].dy)
          ..quadraticBezierTo(mid.dx, mid.dy, pts[j].dx, pts[j].dy);
        canvas.drawPath(path, glow);
        canvas.drawPath(path, core);
      }
    }
    final node = Paint()..color = const Color(0xCCFFF3A8);
    for (final p in pts) {
      canvas.drawCircle(p, 3.5 + sin(t * 4) * 0.6, node);
    }
  }

  @override
  bool shouldRepaint(covariant _NetPainter old) => true;
}

class _SparkPainter extends CustomPainter {
  final LumenGame g;
  final double w, h;
  _SparkPainter(this.g, this.w, this.h);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in g.sparks) {
      final p = Paint()
        ..color = Color(s.argb).withValues(alpha: (s.life / 0.5).clamp(0, 1));
      canvas.drawCircle(Offset(s.p.x * w, s.p.y * h), 2.4, p);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => true;
}
