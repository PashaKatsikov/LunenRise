import 'package:flutter/material.dart';

import '../game/game.dart';
import '../game/paths.dart';
import '../ui/c.dart';
import '../ui/chrome.dart';
import 'sheets.dart';

class MenuScreen extends StatelessWidget {
  final LumenGame game;
  const MenuScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FilePic(Paths.bgMid),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0x00000000),
                  Color(0xAA07061A),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 4),
                const Flexible(child: FittedBox(child: Logo(height: 132))),
                const Spacer(),
                PillBtn.green(
                  'PLAY',
                  width: 220,
                  height: 52,
                  onTap: () {
                    game.sfx.play(SfxFile.click, bump: true);
                    game.go(UiView.tower);
                  },
                ),
                const SizedBox(height: 18),
                _Nav(game: game),
                const SizedBox(height: 10),
              ],
            ),
          ),
          if (game.sheet != SheetKind.none) SheetLayer(game: game),
        ],
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  final LumenGame game;
  const _Nav({required this.game});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData ic, String label, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4157A8), Color(0xFF1A275C)],
                      ),
                      border: Border.all(color: C.line, width: 1.2),
                    ),
                    child: Icon(ic, color: C.gold, size: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: T.num.copyWith(fontSize: 10, color: C.gold),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          item(Icons.apartment_rounded, 'TOWER', () => game.go(UiView.tower)),
          item(Icons.storefront_rounded, 'SHOP', () {
            game.go(UiView.tower);
            game.openSheet(SheetKind.shop);
          }),
          item(
            Icons.auto_awesome,
            'COLLECTION',
            () => game.openSheet(SheetKind.collection),
          ),
          item(
            Icons.flag_rounded,
            'MISSIONS',
            () => game.openSheet(SheetKind.missions),
          ),
          item(
            Icons.settings_rounded,
            'SETTINGS',
            () => game.go(UiView.settings),
          ),
        ],
      ),
    );
  }
}
