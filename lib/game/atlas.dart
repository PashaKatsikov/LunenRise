import 'dart:ui';

class SpriteFrame {
  final String sheet;
  final double x;
  final double y;
  final double w;
  final double h;
  const SpriteFrame(this.sheet, this.x, this.y, this.w, this.h);
  Rect get src => Rect.fromLTWH(x, y, w, h);
}

class Atlas {
  Atlas._();

  static const Map<String, String> sheets = {
    'golden_bells':
        'assets/Lumen_Rise_gameplay_assets/Golden_Bells_Set_01_asset.webp',
    'fruit_bells':
        'assets/Lumen_Rise_gameplay_assets/Fruit_Bells_Set_asset.webp',
    'star_bells': 'assets/Lumen_Rise_gameplay_assets/Star_Bells_Set_asset.webp',
    'advanced_bells':
        'assets/Lumen_Rise_gameplay_assets/Advanced_Bells_Set_asset.webp',
    'platforms':
        'assets/Lumen_Rise_gameplay_assets/Basic_Platforms_Set_asset.webp',
    'structures':
        'assets/Lumen_Rise_gameplay_assets/Light_Structures_Set_asset.webp',
    'fruits_a': 'assets/Lumen_Rise_gameplay_assets/Fruits_Set_01_asset.webp',
    'fruits_b': 'assets/Lumen_Rise_gameplay_assets/Fruits_Set_02_asset.webp',
    'coins': 'assets/Lumen_Rise_gameplay_assets/Golden_Coins_Set_asset.webp',
    'stars': 'assets/Lumen_Rise_gameplay_assets/Stars_Set_asset.webp',
    'r_skins': 'assets/Lumen_Rise_gameplay_assets/R_Variants_Set_asset.webp',
    'decor':
        'assets/Lumen_Rise_gameplay_assets/Tower_Decorations_Set_asset.webp',
    'light_platforms':
        'assets/Lumen_Rise_gameplay_assets/Light_Platforms_Set_asset.webp',
    'r_main': 'assets/Lumen_Rise_gameplay_assets/R_Main_Character_asset.webp',
    'grand_bell':
        'assets/Lumen_Rise_gameplay_assets/Grand_Main_Bell_asset.webp',
    'lumen_core': 'assets/Lumen_Rise_gameplay_assets/Lumen_Core_asset.webp',
    'energy_core':
        'assets/Lumen_Rise_gameplay_assets/Lumen_Energy_Core_asset.webp',
    'observatory':
        'assets/Lumen_Rise_gameplay_assets/Star_Observatory_asset.webp',
    'arch': 'assets/Lumen_Rise_gameplay_assets/Tower_Arch_asset.webp',
  };

  static const Map<String, SpriteFrame> frames = {
    'golden_bells_0': SpriteFrame('golden_bells', 28.0, 61.0, 323.0, 537.0),
    'golden_bells_1': SpriteFrame('golden_bells', 422.0, 54.0, 331.0, 541.0),
    'golden_bells_2': SpriteFrame('golden_bells', 821.0, 54.0, 325.0, 539.0),
    'golden_bells_3': SpriteFrame('golden_bells', 1209.0, 51.0, 311.0, 552.0),
    'fruit_bells_0': SpriteFrame('fruit_bells', 21.0, 52.0, 345.0, 510.0),
    'fruit_bells_1': SpriteFrame('fruit_bells', 401.0, 63.0, 391.0, 510.0),
    'fruit_bells_2': SpriteFrame('fruit_bells', 792.0, 68.0, 396.0, 507.0),
    'fruit_bells_3': SpriteFrame('fruit_bells', 1188.0, 61.0, 341.0, 514.0),
    'star_bells_0': SpriteFrame('star_bells', 98.0, 78.0, 298.0, 491.0),
    'star_bells_1': SpriteFrame('star_bells', 396.0, 72.0, 377.0, 494.0),
    'star_bells_2': SpriteFrame('star_bells', 815.0, 78.0, 334.0, 488.0),
    'star_bells_3': SpriteFrame('star_bells', 1207.0, 78.0, 318.0, 488.0),
    'advanced_bells_0': SpriteFrame('advanced_bells', 41.0, 38.0, 355.0, 582.0),
    'advanced_bells_1': SpriteFrame(
      'advanced_bells',
      396.0,
      32.0,
      380.0,
      599.0,
    ),
    'advanced_bells_2': SpriteFrame(
      'advanced_bells',
      807.0,
      29.0,
      354.0,
      591.0,
    ),
    'advanced_bells_3': SpriteFrame(
      'advanced_bells',
      1195.0,
      35.0,
      364.0,
      589.0,
    ),
    'platforms_0': SpriteFrame('platforms', 23.0, 139.0, 370.0, 394.0),
    'platforms_1': SpriteFrame('platforms', 446.0, 175.0, 328.0, 370.0),
    'platforms_2': SpriteFrame('platforms', 802.0, 163.0, 386.0, 354.0),
    'platforms_3': SpriteFrame('platforms', 1188.0, 185.0, 351.0, 356.0),
    'structures_0': SpriteFrame('structures', 61.0, 63.0, 298.0, 523.0),
    'structures_1': SpriteFrame('structures', 464.0, 87.0, 296.0, 496.0),
    'structures_2': SpriteFrame('structures', 839.0, 63.0, 284.0, 526.0),
    'structures_3': SpriteFrame('structures', 1204.0, 95.0, 320.0, 476.0),
    'fruits_a_0': SpriteFrame('fruits_a', 43.0, 126.0, 335.0, 380.0),
    'fruits_a_1': SpriteFrame('fruits_a', 432.0, 168.0, 332.0, 335.0),
    'fruits_a_2': SpriteFrame('fruits_a', 833.0, 152.0, 306.0, 361.0),
    'fruits_a_3': SpriteFrame('fruits_a', 1195.0, 112.0, 351.0, 431.0),
    'fruits_b_0': SpriteFrame('fruits_b', 65.0, 93.0, 311.0, 467.0),
    'fruits_b_1': SpriteFrame('fruits_b', 430.0, 141.0, 343.0, 395.0),
    'fruits_b_2': SpriteFrame('fruits_b', 806.0, 156.0, 382.0, 392.0),
    'fruits_b_3': SpriteFrame('fruits_b', 1188.0, 177.0, 339.0, 375.0),
    'coins_0': SpriteFrame('coins', 42.0, 132.0, 323.0, 388.0),
    'coins_1': SpriteFrame('coins', 447.0, 130.0, 325.0, 390.0),
    'coins_2': SpriteFrame('coins', 825.0, 132.0, 330.0, 389.0),
    'coins_3': SpriteFrame('coins', 1219.0, 138.0, 318.0, 384.0),
    'stars_0': SpriteFrame('stars', 33.0, 120.0, 363.0, 427.0),
    'stars_1': SpriteFrame('stars', 396.0, 163.0, 380.0, 357.0),
    'stars_2': SpriteFrame('stars', 838.0, 145.0, 345.0, 374.0),
    'stars_3': SpriteFrame('stars', 1233.0, 178.0, 314.0, 343.0),
    'r_skins_0': SpriteFrame('r_skins', 44.0, 107.0, 347.0, 454.0),
    'r_skins_1': SpriteFrame('r_skins', 441.0, 109.0, 340.0, 452.0),
    'r_skins_2': SpriteFrame('r_skins', 834.0, 107.0, 328.0, 449.0),
    'r_skins_3': SpriteFrame('r_skins', 1228.0, 111.0, 317.0, 446.0),
    'decor_0': SpriteFrame('decor', 70.0, 23.0, 271.0, 600.0),
    'decor_1': SpriteFrame('decor', 411.0, 115.0, 343.0, 492.0),
    'decor_2': SpriteFrame('decor', 867.0, 25.0, 261.0, 605.0),
    'decor_3': SpriteFrame('decor', 1239.0, 107.0, 264.0, 518.0),
    'light_platforms_0': SpriteFrame(
      'light_platforms',
      255.0,
      47.0,
      449.0,
      289.0,
    ),
    'light_platforms_1': SpriteFrame(
      'light_platforms',
      832.0,
      48.0,
      505.0,
      288.0,
    ),
    'light_platforms_2': SpriteFrame(
      'light_platforms',
      230.0,
      358.0,
      472.0,
      277.0,
    ),
    'light_platforms_3': SpriteFrame(
      'light_platforms',
      819.0,
      336.0,
      481.0,
      300.0,
    ),
    'r_main': SpriteFrame('r_main', 537.0, 30.0, 486.0, 602.0),
    'grand_bell': SpriteFrame('grand_bell', 474.0, 0.0, 619.0, 670.0),
    'lumen_core': SpriteFrame('lumen_core', 516.0, 36.0, 591.0, 596.0),
    'energy_core': SpriteFrame('energy_core', 514.0, 7.0, 554.0, 654.0),
    'observatory': SpriteFrame('observatory', 475.0, 24.0, 631.0, 612.0),
    'arch': SpriteFrame('arch', 474.0, 18.0, 630.0, 652.0),
  };

  static SpriteFrame frame(String id) => frames[id]!;
}
