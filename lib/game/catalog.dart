class ItemDef {
  final String id;
  final String name;
  final String category;
  final String sprite;
  final int minFloor;
  final int coins;
  final int fruits;
  final int stars;
  final double coinRate;
  final double fruitRate;
  final double starRate;
  final double lightRate;
  final bool bell;
  final String blurb;

  const ItemDef({
    required this.id,
    required this.name,
    required this.category,
    required this.sprite,
    required this.minFloor,
    this.coins = 0,
    this.fruits = 0,
    this.stars = 0,
    this.coinRate = 0,
    this.fruitRate = 0,
    this.starRate = 0,
    this.lightRate = 0,
    this.bell = true,
    required this.blurb,
  });
}

class SkinDef {
  final String id;
  final String name;
  final String sprite;
  final int stars;
  final int cores;
  const SkinDef(this.id, this.name, this.sprite, this.stars, this.cores);
}

class UpgradeDef {
  final String id;
  final String name;
  final String hint;
  const UpgradeDef(this.id, this.name, this.hint);
}

class Catalog {
  Catalog._();

  static const skins = [
    SkinDef('r_main', 'Default R', 'r_main', 0, 0),
    SkinDef('solar', 'Solar R', 'r_skins_0', 6, 0),
    SkinDef('crystal', 'Crystal R', 'r_skins_1', 14, 0),
    SkinDef('royal', 'Royal R', 'r_skins_2', 0, 4),
    SkinDef('ember', 'Ember R', 'r_skins_3', 0, 9),
  ];

  static const upgrades = [
    UpgradeDef('speed', 'Swift Step', 'R crosses the floor faster'),
    UpgradeDef('magnet', 'Coin Magnet', 'Pulls pickups in from farther away'),
    UpgradeDef(
      'charge',
      'Energy Charge',
      'Bells feed the light network harder',
    ),
    UpgradeDef('capacity', 'Capacity', 'More pickups can sit on a floor'),
  ];

  static const items = <ItemDef>[
    ItemDef(
      id: 'gb0',
      name: 'Auric Chime',
      category: 'production',
      sprite: 'golden_bells_0',
      minFloor: 1,
      coins: 40,
      coinRate: 1.4,
      lightRate: 0.9,
      blurb: 'A humble gold bell. Steady coins for a young tower.',
    ),
    ItemDef(
      id: 'gb1',
      name: 'Vault Lantern',
      category: 'production',
      sprite: 'golden_bells_1',
      minFloor: 2,
      coins: 85,
      coinRate: 2.2,
      lightRate: 1.1,
      blurb: 'Clockwork gold. Pays for the next platform.',
    ),
    ItemDef(
      id: 'gb2',
      name: 'Crest Bell',
      category: 'production',
      sprite: 'golden_bells_2',
      minFloor: 4,
      coins: 160,
      coinRate: 3.4,
      lightRate: 1.4,
      blurb: 'Ceremonial bronze. The economy starts to hum.',
    ),
    ItemDef(
      id: 'gb3',
      name: 'Sunforge Bell',
      category: 'production',
      sprite: 'golden_bells_3',
      minFloor: 7,
      coins: 320,
      coinRate: 5.2,
      lightRate: 1.8,
      blurb: 'Forge-heat and coinlight, loud enough for upper halls.',
    ),
    ItemDef(
      id: 'fb0',
      name: 'Orchard Bell',
      category: 'production',
      sprite: 'fruit_bells_0',
      minFloor: 3,
      coins: 70,
      fruits: 6,
      fruitRate: 0.55,
      lightRate: 0.7,
      blurb: 'Apple-sweet chime. Fruit feeds short bursts of work.',
    ),
    ItemDef(
      id: 'fb1',
      name: 'Citrus Bell',
      category: 'production',
      sprite: 'fruit_bells_1',
      minFloor: 5,
      coins: 120,
      fruits: 12,
      fruitRate: 0.85,
      lightRate: 0.9,
      blurb: 'Orange-oil and sunlight. A faster harvest.',
    ),
    ItemDef(
      id: 'fb2',
      name: 'Berry Bell',
      category: 'production',
      sprite: 'fruit_bells_2',
      minFloor: 8,
      coins: 210,
      fruits: 20,
      fruitRate: 1.2,
      lightRate: 1.1,
      blurb: 'Wild-berry overtone. Good for long boosts.',
    ),
    ItemDef(
      id: 'fb3',
      name: 'Vine Bell',
      category: 'production',
      sprite: 'fruit_bells_3',
      minFloor: 11,
      coins: 380,
      fruits: 28,
      fruitRate: 1.7,
      lightRate: 1.3,
      blurb: 'Grape-dark resonance. The orchard at full climb.',
    ),
    ItemDef(
      id: 'sb0',
      name: 'Nightstar',
      category: 'production',
      sprite: 'star_bells_0',
      minFloor: 6,
      coins: 140,
      stars: 2,
      starRate: 0.12,
      lightRate: 1.2,
      blurb: 'A pocket of night. Stars open the rarer rooms.',
    ),
    ItemDef(
      id: 'sb1',
      name: 'Moonsteel',
      category: 'production',
      sprite: 'star_bells_1',
      minFloor: 9,
      coins: 260,
      stars: 4,
      starRate: 0.18,
      lightRate: 1.5,
      blurb: 'Cold silver sky. Slow, then suddenly enough.',
    ),
    ItemDef(
      id: 'sb2',
      name: 'Violet Nova',
      category: 'production',
      sprite: 'star_bells_2',
      minFloor: 12,
      coins: 420,
      stars: 6,
      starRate: 0.26,
      lightRate: 1.8,
      blurb: 'Purple midnight. The climb starts to glitter.',
    ),
    ItemDef(
      id: 'sb3',
      name: 'Pearlstar',
      category: 'production',
      sprite: 'star_bells_3',
      minFloor: 14,
      coins: 640,
      stars: 8,
      starRate: 0.34,
      lightRate: 2.1,
      blurb: 'White-gold starfall. Peak-floor fuel.',
    ),
    ItemDef(
      id: 'ab0',
      name: 'Azure Conduit',
      category: 'production',
      sprite: 'advanced_bells_0',
      minFloor: 10,
      coins: 500,
      stars: 5,
      coinRate: 3.0,
      lightRate: 3.2,
      blurb: 'Blue storm-bell. Coins and a hard light push.',
    ),
    ItemDef(
      id: 'ab1',
      name: 'Void Pulse',
      category: 'production',
      sprite: 'advanced_bells_1',
      minFloor: 12,
      coins: 620,
      stars: 8,
      fruitRate: 0.8,
      starRate: 0.2,
      lightRate: 3.6,
      blurb: 'Violet lattice. Mixes fruit, stars, and glare.',
    ),
    ItemDef(
      id: 'ab2',
      name: 'Emerald Coil',
      category: 'production',
      sprite: 'advanced_bells_2',
      minFloor: 13,
      coins: 740,
      fruits: 24,
      coinRate: 2.4,
      fruitRate: 1.1,
      lightRate: 3.8,
      blurb: 'Green current. The network starts to braid.',
    ),
    ItemDef(
      id: 'ab3',
      name: 'Ember Heart',
      category: 'production',
      sprite: 'advanced_bells_3',
      minFloor: 15,
      coins: 980,
      stars: 12,
      coinRate: 4.4,
      starRate: 0.22,
      lightRate: 4.4,
      blurb: 'Ember-core bell. Late-run engine.',
    ),
    ItemDef(
      id: 'st0',
      name: 'Prism Spire',
      category: 'structure',
      sprite: 'structures_0',
      minFloor: 4,
      coins: 110,
      lightRate: 1.6,
      bell: false,
      blurb: 'A crystal mast. Light hops farther from here.',
    ),
    ItemDef(
      id: 'st1',
      name: 'Gold Orbit',
      category: 'structure',
      sprite: 'structures_1',
      minFloor: 6,
      coins: 180,
      coinRate: 1.0,
      lightRate: 1.4,
      bell: false,
      blurb: 'A slow gold gyro. Coins ride the ring.',
    ),
    ItemDef(
      id: 'st2',
      name: 'Amethyst Pylon',
      category: 'structure',
      sprite: 'structures_2',
      minFloor: 9,
      coins: 260,
      stars: 3,
      starRate: 0.08,
      lightRate: 2.2,
      bell: false,
      blurb: 'Purple spine. Stars drip when the network is hot.',
    ),
    ItemDef(
      id: 'st3',
      name: 'Astrolabe',
      category: 'structure',
      sprite: 'structures_3',
      minFloor: 11,
      coins: 340,
      stars: 4,
      lightRate: 2.8,
      bell: false,
      blurb: 'Orbiting glass. The floor thinks in star-paths.',
    ),
    ItemDef(
      id: 'arch',
      name: 'Moon Gate',
      category: 'special',
      sprite: 'arch',
      minFloor: 5,
      coins: 200,
      lightRate: 1.5,
      bell: false,
      blurb: 'An arch that stitches two beams together.',
    ),
    ItemDef(
      id: 'obs',
      name: 'Star Observatory',
      category: 'special',
      sprite: 'observatory',
      minFloor: 8,
      coins: 360,
      stars: 5,
      starRate: 0.22,
      lightRate: 2.0,
      bell: false,
      blurb: 'Reads the sky. Stars arrive already counted.',
    ),
    ItemDef(
      id: 'engine',
      name: 'Lumen Engine',
      category: 'special',
      sprite: 'energy_core',
      minFloor: 12,
      coins: 700,
      stars: 8,
      lightRate: 5.5,
      bell: false,
      blurb: 'The floor\'s heartbeat. Light, and a lot of it.',
    ),
    ItemDef(
      id: 'grand',
      name: 'Grand Aegis',
      category: 'special',
      sprite: 'grand_bell',
      minFloor: 16,
      coins: 1600,
      stars: 16,
      coinRate: 6,
      fruitRate: 1.4,
      starRate: 0.4,
      lightRate: 8,
      blurb: 'The peak bell. Ring it, then rise again.',
    ),
  ];

  static final Map<String, ItemDef> byId = {for (final i in items) i.id: i};

  static ItemDef? tryItem(String id) => byId[id];

  static ItemDef item(String id) => byId[id]!;

  static SkinDef skin(String id) =>
      skins.firstWhere((s) => s.id == id, orElse: () => skins.first);

  static List<ItemDef> inCategory(String c) =>
      items.where((e) => e.category == c).toList();
}
