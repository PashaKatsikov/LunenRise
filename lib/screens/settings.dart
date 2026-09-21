import 'package:flutter/material.dart';

import '../game/game.dart';
import '../game/paths.dart';
import '../ui/c.dart';
import '../ui/chrome.dart';

class SettingsScreen extends StatelessWidget {
  final LumenGame game;
  const SettingsScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    return Scaffold(
      backgroundColor: C.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FilePic(Paths.bgHigh),
          const DecoratedBox(
            decoration: BoxDecoration(color: Color(0x99070A1C)),
          ),
          Center(
            child: Panel(
              title: 'Settings',
              onClose: g.back,
              maxWidth: 560,
              maxHeight: 400,
              child: ListView(
                children: [
                  _slide('Music', g.music, g.setMusic),
                  _slide('Sound Effects', g.sound, g.setSound),
                  _tog('Vibration', g.haptics, g.setHaptics),
                  _tog('Power Saving Mode', g.powerSave, g.setPower),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: PillBtn(
                          'PRIVACY POLICY',
                          height: 40,
                          size: 12,
                          onTap: () => g.openWeb(
                            Paths.privacy,
                            'Privacy Policy',
                            whiten: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PillBtn(
                          'SUPPORT',
                          height: 40,
                          size: 12,
                          colors: const [Color(0xFF5B7CFF), Color(0xFF2A3E9A)],
                          onTap: () => g.openWeb(Paths.support, 'Support'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slide(
    String name,
    double v,
    void Function(double v, {bool save}) on,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(name, style: T.body, overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 6,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: v,
              onChanged: (n) => on(n, save: false),
              onChangeEnd: (n) => on(n, save: true),
              activeColor: C.gold,
              inactiveColor: const Color(0xFF2A3560),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tog(String name, bool v, ValueChanged<bool> on) {
    return Row(
      children: [
        Expanded(child: Text(name, style: T.body)),
        Switch(value: v, onChanged: on, activeThumbColor: C.gold),
      ],
    );
  }
}
