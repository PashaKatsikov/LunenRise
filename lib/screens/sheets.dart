import 'package:flutter/material.dart';

import '../game/catalog.dart';
import '../game/game.dart';
import '../ui/c.dart';
import '../ui/chrome.dart';

class SheetLayer extends StatelessWidget {
  final LumenGame game;
  const SheetLayer({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    Widget? body;
    switch (game.sheet) {
      case SheetKind.floors:
        body = FloorSheet(game: game);
        break;
      case SheetKind.build:
        body = BuildSheet(game: game);
        break;
      case SheetKind.upgrades:
        body = UpgradeSheet(game: game);
        break;
      case SheetKind.collection:
        body = CollectionSheet(game: game);
        break;
      case SheetKind.resources:
        body = ResourceSheet(game: game);
        break;
      case SheetKind.event:
        body = EventSheet(game: game);
        break;
      case SheetKind.shop:
        body = ShopSheet(game: game);
        break;
      case SheetKind.missions:
        body = MissionSheet(game: game);
        break;
      case SheetKind.ascension:
        body = AscensionSheet(game: game);
        break;
      case SheetKind.result:
        body = ResultSheet(game: game);
        break;
      case SheetKind.none:
        return const SizedBox.shrink();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Dim(onTap: game.closeSheet),
        Center(child: body),
      ],
    );
  }
}

class FloorSheet extends StatelessWidget {
  final LumenGame game;
  const FloorSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    final next = g.highest + 1;
    return Panel(
      title: 'Choose Floor',
      onClose: g.closeSheet,
      maxWidth: 560,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: LumenGame.maxFloor,
              itemBuilder: (c, i) {
                final f = i + 1;
                final open = g.floors[i].unlocked;
                final risky = g.floors[i].risky;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: open ? () => g.enterFloor(f) : null,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: f == g.floor
                            ? const Color(0xFF2A3D86)
                            : const Color(0xFF151E46),
                        border: Border.all(
                          color: open ? C.gold : const Color(0x33FFFFFF),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            f == g.floor
                                ? Icons.my_location_rounded
                                : (open
                                      ? Icons.lock_open_rounded
                                      : Icons.lock_rounded),
                            size: 16,
                            color: open ? C.gold : C.mute,
                          ),
                          const SizedBox(width: 8),
                          Text('Floor $f', style: T.body),
                          const Spacer(),
                          if (risky)
                            Text(
                              'RISKY',
                              style: T.num.copyWith(
                                color: C.danger,
                                fontSize: 10,
                              ),
                            ),
                          if (f == g.floor)
                            Text(
                              '  HERE',
                              style: T.num.copyWith(
                                color: C.mint,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 210,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Sprite('grand_bell', height: 96),
                Text(
                  'Floor ${g.floor}',
                  style: T.title.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                Text(
                  g.here.risky ? 'Radiant path  +45% yield' : 'Stable path',
                  style: T.mute,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                if (next <= LumenGame.maxFloor) ...[
                  Text(
                    'Next floor needs ${compact(g.lightNeed(next))} light',
                    style: T.mute,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  PillBtn(
                    'STABLE RISE',
                    onTap: () => g.unlockFloor(next, risky: false),
                    height: 38,
                    size: 12,
                  ),
                  const SizedBox(height: 6),
                  PillBtn(
                    'RADIANT GAMBLE',
                    onTap: () => g.unlockFloor(next, risky: true),
                    height: 38,
                    size: 12,
                    colors: const [Color(0xFFFF8A4A), Color(0xFFC43A18)],
                  ),
                ] else
                  PillBtn(
                    'PEAK REACHED',
                    onTap: g.canAscend ? g.offerAscend : null,
                    height: 40,
                  ),
                const SizedBox(height: 8),
                PillBtn.green(
                  'ENTER',
                  onTap: () => g.enterFloor(g.floor),
                  height: 42,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BuildSheet extends StatelessWidget {
  final LumenGame game;
  const BuildSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    final tab = g.tabBuild ?? 'production';
    final items = Catalog.inCategory(tab);
    return Panel(
      title: 'Build Tower',
      onClose: g.closeSheet,
      maxWidth: 680,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Tab('PRODUCTION', tab == 'production', () {
                  g.tabBuild = 'production';
                  g.refresh();
                }),
                _Tab('STRUCTURES', tab == 'structure', () {
                  g.tabBuild = 'structure';
                  g.refresh();
                }),
                _Tab('SPECIAL', tab == 'special', () {
                  g.tabBuild = 'special';
                  g.refresh();
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: PillBtn(
              g.here.slots.every((s) => s.open)
                  ? 'FLOOR FULL'
                  : 'UNVEIL  ${compact(g.slotCost())}',
              onTap: g.here.slots.every((s) => s.open) ? null : g.unveilSlot,
              height: 32,
              size: 11,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.28,
              ),
              itemCount: items.length,
              itemBuilder: (c, i) {
                final d = items[i];
                final p = g.price(d);
                final locked = g.floor < d.minFloor;
                return GestureDetector(
                  onTap: () => g.chooseBuild(d),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151E46),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: locked
                            ? Colors.white12
                            : C.line.withValues(alpha: 0.6),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Sprite(
                            d.sprite,
                            height: 58,
                            glow: g.found.contains(d.id),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.name,
                            style: T.num.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            locked ? 'Floor ${d.minFloor}' : _costLine(p),
                            style: T.mute.copyWith(
                              fontSize: 10,
                              color: locked ? C.danger : C.mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _costLine((int, int, int) p) {
    final parts = <String>[];
    if (p.$1 > 0) parts.add('${compact(p.$1)}c');
    if (p.$2 > 0) parts.add('${p.$2}f');
    if (p.$3 > 0) parts.add('${p.$3}s');
    return parts.join('  ');
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback tap;
  const _Tab(this.label, this.on, this.tap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: tap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: on ? const Color(0xFF2A3D86) : Colors.transparent,
            border: Border.all(color: on ? C.gold : Colors.white24),
          ),
          child: Text(
            label,
            style: T.num.copyWith(fontSize: 10, color: on ? C.gold : C.mute),
          ),
        ),
      ),
    );
  }
}

class UpgradeSheet extends StatelessWidget {
  final LumenGame game;
  const UpgradeSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    int lv(String id) {
      switch (id) {
        case 'speed':
          return g.speedLv;
        case 'magnet':
          return g.magnetLv;
        case 'charge':
          return g.chargeLv;
        default:
          return g.capLv;
      }
    }

    return Panel(
      title: 'Upgrades',
      onClose: g.closeSheet,
      maxWidth: 600,
      child: Row(
        children: [
          Expanded(
            child: Center(child: Sprite(g.rSprite, height: 160, glow: true)),
          ),
          Expanded(
            flex: 2,
            child: ListView(
              children: Catalog.upgrades.map((u) {
                final l = lv(u.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151E46),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.line.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${u.name}  $l/8', style: T.body),
                              Text(u.hint, style: T.mute),
                            ],
                          ),
                        ),
                        PillBtn(
                          l >= 8 ? 'MAX' : compact(g.upgradeCost(u.id)),
                          onTap: l >= 8 ? null : () => g.buyUpgrade(u.id),
                          height: 34,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class CollectionSheet extends StatelessWidget {
  final LumenGame game;
  const CollectionSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    final skins = g.tabCol != 'bells';
    return Panel(
      title: 'Collection',
      onClose: g.closeSheet,
      maxWidth: 640,
      child: Column(
        children: [
          Row(
            children: [
              _Tab('R SKINS', skins, () {
                g.tabCol = 'skins';
                g.refresh();
              }),
              _Tab('BELLS', !skins, () {
                g.tabCol = 'bells';
                g.refresh();
              }),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: skins
                ? GridView.count(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.72,
                    children: Catalog.skins.map((s) {
                      final have = g.unlockedSkins.contains(s.id);
                      final on = g.skin == s.id;
                      return GestureDetector(
                        onTap: () => g.pickSkin(s.id),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF151E46),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: on ? C.gold : Colors.white24,
                              width: on ? 2 : 1,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Opacity(
                                  opacity: have || s.id == 'r_main' ? 1 : 0.35,
                                  child: Sprite(s.sprite, height: 64),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.name,
                                  style: T.num.copyWith(fontSize: 9),
                                  maxLines: 1,
                                ),
                                Text(
                                  have
                                      ? (on ? 'EQUIPPED' : 'OWNED')
                                      : (s.cores > 0
                                            ? '${s.cores} cores'
                                            : '${s.stars} stars'),
                                  style: T.mute.copyWith(fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.82,
                    children: Catalog.items.where((e) => e.bell).map((d) {
                      final have = g.found.contains(d.id);
                      return Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151E46),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: have ? C.line : Colors.white12,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: have ? 1 : 0.28,
                                child: Sprite(d.sprite, height: 54),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                have ? d.name : '???',
                                style: T.num.copyWith(fontSize: 9),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class ResourceSheet extends StatelessWidget {
  final LumenGame game;
  const ResourceSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    Widget cell(String sp, String name, String v, String hint) {
      return Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF151E46),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.gold.withValues(alpha: 0.35)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            children: [
              Sprite(sp, height: 56),
              const SizedBox(height: 4),
              Text(name, style: T.body),
              Text(v, style: T.title.copyWith(fontSize: 18)),
              Text(hint, style: T.mute, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Panel(
      title: 'Resources',
      onClose: g.closeSheet,
      maxWidth: 620,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: cell(
                    'coins_0',
                    'COINS',
                    compact(g.coins),
                    'Day-to-day building',
                  ),
                ),
                Expanded(
                  child: cell(
                    'fruits_a_3',
                    'FRUITS',
                    compact(g.fruits),
                    'Short, sharp boosts',
                  ),
                ),
                Expanded(
                  child: cell(
                    'stars_2',
                    'STARS',
                    compact(g.stars),
                    'Rare floors & skins',
                  ),
                ),
              ],
            ),
          ),
          cell(
            'lumen_core',
            'LUMEN CORE',
            compact(g.lumenCore),
            'Kept between ascensions  ·  +${(g.coreMul * 100 - 100).round()}% yield',
          ),
        ],
      ),
    );
  }
}

class EventSheet extends StatelessWidget {
  final LumenGame game;
  const EventSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final e = game.event;
    if (e == null) {
      return Panel(
        title: 'Event',
        onClose: game.closeSheet,
        maxWidth: 420,
        maxHeight: 240,
        child: const Center(child: Text('The sky is quiet.', style: T.body)),
      );
    }
    return Panel(
      title: 'Event',
      onClose: game.closeSheet,
      maxWidth: 460,
      maxHeight: 340,
      child: Column(
        children: [
          Sprite(e.art, height: 88),
          const SizedBox(height: 6),
          Text(e.title.toUpperCase(), style: T.title.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text(e.body, style: T.mute, textAlign: TextAlign.center),
          const Spacer(),
          Text(
            '${e.left.ceil()}s remaining',
            style: T.num.copyWith(color: C.gold),
          ),
          const SizedBox(height: 8),
          PillBtn.green(
            e.claimed ? 'CONTINUE' : 'GO!',
            onTap: game.takeEvent,
            width: 160,
          ),
        ],
      ),
    );
  }
}

class ShopSheet extends StatelessWidget {
  final LumenGame game;
  const ShopSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    Widget row(
      String sp,
      String name,
      String hint,
      String cost,
      VoidCallback tap,
    ) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF151E46),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.line.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Sprite(sp, height: 48),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: T.body),
                    Text(hint, style: T.mute),
                  ],
                ),
              ),
              PillBtn(cost, onTap: tap, height: 34, size: 12),
            ],
          ),
        ),
      );
    }

    return Panel(
      title: 'Shop',
      onClose: g.closeSheet,
      maxWidth: 520,
      child: ListView(
        children: [
          row(
            'fruits_b_0',
            'Lumen Rush',
            '+55% production for 45s',
            '18 fruit',
            () => g.shopBoost('rush'),
          ),
          row(
            'coins_3',
            'Gold Pop',
            'x2 coins for a short burst',
            '90 coins',
            () => g.shopBoost('gold'),
          ),
          row(
            'stars_1',
            'Star Lens',
            'Bank 35% of the next floor\'s light',
            '3 stars',
            () => g.shopBoost('cut'),
          ),
        ],
      ),
    );
  }
}

class MissionSheet extends StatelessWidget {
  final LumenGame game;
  const MissionSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    return Panel(
      title: 'Missions',
      onClose: g.closeSheet,
      maxWidth: 520,
      child: ListView(
        children: g.missions.map((m) {
          final done = m.progress >= m.target;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF151E46),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: done ? C.mint : Colors.white24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title, style: T.body),
                        Text(m.hint, style: T.mute),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (m.progress / m.target).clamp(0, 1),
                            minHeight: 7,
                            backgroundColor: const Color(0xFF0B1230),
                            color: C.gold,
                          ),
                        ),
                        Text(
                          '${m.progress}/${m.target}',
                          style: T.mute.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  PillBtn(
                    m.claimed
                        ? 'DONE'
                        : (done ? 'CLAIM' : '${m.progress}/${m.target}'),
                    onTap: done && !m.claimed ? () => g.claimMission(m) : null,
                    height: 34,
                    size: 11,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AscensionSheet extends StatelessWidget {
  final LumenGame game;
  const AscensionSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    return Panel(
      title: 'Ascension',
      onClose: g.closeSheet,
      maxWidth: 480,
      maxHeight: 360,
      child: Column(
        children: [
          const Sprite('energy_core', height: 110, glow: true),
          Text('TOWER PEAK REACHED', style: T.title.copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            'The Aegis is lit. Break the climb, keep the Core, and raise a hungrier tower.',
            style: T.mute,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Text(
            'Lumen Core  +${1 + (g.highest ~/ 8) + (g.floors.where((f) => f.risky).length >= 4 ? 1 : 0)}',
            style: T.body.copyWith(color: C.gold),
          ),
          Text('Permanent production stays with you.', style: T.mute),
          const SizedBox(height: 10),
          PillBtn.green('ASCEND', onTap: g.ascend, width: 180),
        ],
      ),
    );
  }
}

class ResultSheet extends StatelessWidget {
  final LumenGame game;
  const ResultSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final r = game.last;
    Widget line(String k, String v) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(k, style: T.mute),
            const Spacer(),
            Text(v, style: T.body),
          ],
        ),
      );
    }

    return Panel(
      title: 'Result',
      onClose: game.closeSheet,
      maxWidth: 460,
      maxHeight: 340,
      child: Column(
        children: [
          Text('GREAT RISE', style: T.title.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              r.starsEarned,
              (i) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Sprite('stars_0', height: 28),
              ),
            ),
          ),
          const SizedBox(height: 8),
          line('Peak floor', '${r.floor}'),
          line('Coins collected', compact(r.coins)),
          line('Fruits collected', compact(r.fruits)),
          line('Stars collected', compact(r.stars)),
          line('Lumen Core earned', '+${r.cores}'),
          const Spacer(),
          PillBtn.green('CONTINUE', onTap: game.closeSheet, width: 180),
        ],
      ),
    );
  }
}
