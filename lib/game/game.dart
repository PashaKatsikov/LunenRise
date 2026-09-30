import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart';
import 'paths.dart';
import 'sfx.dart';
import '../post/native.dart';

enum UiView { boot, menu, tower, settings, web }

enum SheetKind {
  none,
  floors,
  build,
  upgrades,
  collection,
  resources,
  event,
  shop,
  missions,
  ascension,
  result,
}

enum PickupKind { coin, fruit, star }

class Pickup {
  PickupKind kind;
  OffsetN pos;
  int amount;
  int frame;
  double phase;
  Pickup(this.kind, this.pos, this.amount, this.frame, this.phase);
}

class Spark {
  OffsetN p;
  OffsetN v;
  double life;
  int argb;
  Spark(this.p, this.v, this.life, this.argb);
}

class OffsetN {
  double x;
  double y;
  OffsetN(this.x, this.y);
  OffsetN copy() => OffsetN(x, y);
  double dist(OffsetN o) {
    final dx = x - o.x;
    final dy = y - o.y;
    return sqrt(dx * dx + dy * dy);
  }
}

class Placed {
  String defId;
  bool active;
  int level;
  double accC = 0;
  double accF = 0;
  double accS = 0;
  double pulse = 0;
  Placed(this.defId, {this.active = false, this.level = 1});

  Map<String, dynamic> toJ() => {'id': defId, 'a': active ? 1 : 0, 'lv': level};

  static Placed fromJ(Map j) => Placed(
    j['id'] as String,
    active: j['a'] == 1,
    level: (j['lv'] as num?)?.toInt() ?? 1,
  );
}

class Slot {
  OffsetN pos;
  int plat;
  bool lightPlat;
  bool open;
  Placed? building;
  Slot({
    required this.pos,
    required this.plat,
    this.lightPlat = false,
    this.open = true,
    this.building,
  });

  Map<String, dynamic> toJ() => {
    'x': pos.x,
    'y': pos.y,
    'p': plat,
    'lp': lightPlat ? 1 : 0,
    'o': open ? 1 : 0,
    if (building != null) 'b': building!.toJ(),
  };

  static Slot fromJ(Map j) => Slot(
    pos: OffsetN((j['x'] as num).toDouble(), (j['y'] as num).toDouble()),
    plat: (j['p'] as num).toInt(),
    lightPlat: j['lp'] == 1,
    open: j['o'] == 1,
    building: j['b'] == null
        ? null
        : Placed.fromJ(Map<String, dynamic>.from(j['b'] as Map)),
  );
}

class Decor {
  OffsetN pos;
  String sprite;
  double h;
  Decor(this.pos, this.sprite, this.h);
}

class Floor {
  int index;
  bool unlocked;
  bool risky;
  List<Slot> slots;
  List<Decor> deco;
  Floor(
    this.index, {
    this.unlocked = false,
    this.risky = false,
    List<Slot>? slots,
    List<Decor>? deco,
  }) : slots = slots ?? [],
       deco = deco ?? [];

  Map<String, dynamic> toJ() => {
    'i': index,
    'u': unlocked ? 1 : 0,
    'r': risky ? 1 : 0,
    's': slots.map((e) => e.toJ()).toList(),
  };

  static Floor fromJ(Map j, List<Decor> deco) => Floor(
    (j['i'] as num).toInt(),
    unlocked: j['u'] == 1,
    risky: j['r'] == 1,
    slots: (j['s'] as List)
        .map((e) => Slot.fromJ(Map<String, dynamic>.from(e as Map)))
        .toList(),
    deco: deco,
  );
}

class Mission {
  String id;
  String title;
  String hint;
  String stat;
  int target;
  int progress;
  int rc;
  int rf;
  int rs;
  bool claimed;
  Mission({
    required this.id,
    required this.title,
    required this.hint,
    required this.stat,
    required this.target,
    this.progress = 0,
    this.rc = 0,
    this.rf = 0,
    this.rs = 0,
    this.claimed = false,
  });

  Map<String, dynamic> toJ() => {
    'id': id,
    't': title,
    'h': hint,
    'st': stat,
    'tg': target,
    'p': progress,
    'rc': rc,
    'rf': rf,
    'rs': rs,
    'c': claimed ? 1 : 0,
  };

  static Mission fromJ(Map j) => Mission(
    id: j['id'] as String,
    title: j['t'] as String,
    hint: j['h'] as String,
    stat: j['st'] as String,
    target: (j['tg'] as num).toInt(),
    progress: (j['p'] as num?)?.toInt() ?? 0,
    rc: (j['rc'] as num?)?.toInt() ?? 0,
    rf: (j['rf'] as num?)?.toInt() ?? 0,
    rs: (j['rs'] as num?)?.toInt() ?? 0,
    claimed: j['c'] == 1,
  );
}

class GameEvent {
  String id;
  String title;
  String body;
  String kind;
  String art;
  double left;
  int rc;
  int rf;
  int rs;
  bool claimed;
  GameEvent({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.art,
    required this.left,
    this.rc = 0,
    this.rf = 0,
    this.rs = 0,
    this.claimed = false,
  });
}

class LastRun {
  int floor = 1;
  int coins = 0;
  int fruits = 0;
  int stars = 0;
  int cores = 0;
  int starsEarned = 3;
}

class LumenGame extends ChangeNotifier {
  LumenGame();

  final rng = Random();
  final sfx = Sfx();

  UiView view = UiView.boot;
  UiView returnTo = UiView.menu;
  SheetKind sheet = SheetKind.none;
  String webUrl = Paths.privacy;
  String webTitle = 'Privacy Policy';
  bool webWhiten = true;

  double load = 0;

  int coins = 80;
  int fruits = 0;
  int stars = 0;
  double light = 0;
  int lumenCore = 0;

  int floor = 1;
  int highest = 1;
  int ascension = 0;

  int speedLv = 0;
  int magnetLv = 0;
  int chargeLv = 0;
  int capLv = 0;

  double music = 0.7;
  double sound = 1;
  bool haptics = true;
  bool powerSave = false;

  String skin = 'r_main';
  final unlockedSkins = <String>{'r_main'};
  final found = <String>{'gb0'};

  final floors = <Floor>[];
  final pickups = <Pickup>[];
  final sparks = <Spark>[];
  final missions = <Mission>[];

  OffsetN r = OffsetN(0.50, 0.68);
  OffsetN? walkTo;
  Slot? pendingSlot;
  Slot? pendingTune;
  Pickup? pendingPick;
  bool placing = false;
  String? placeId;

  String? toast;
  int toastGen = 0;
  GameEvent? event;
  double eventIn = 90;
  LastRun last = LastRun();

  double harvestMul = 1;
  double goldMul = 1;
  double starMul = 1;
  double lightMul = 1;
  double rushLeft = 0;
  double goldLeft = 0;
  int outageSlot = -1;

  double time = 0;
  double saveAcc = 0;
  double uiAcc = 0;
  bool dirtyUi = false;

  int coinsTaken = 0;
  int fruitsTaken = 0;
  int starsTaken = 0;
  int bellsOn = 0;
  int floorsOpened = 0;

  bool _seedLoot = true;
  String? tabBuild = 'production';
  String? tabCol = 'skins';

  static const maxFloor = 16;

  // Sealed (tamper-evident) save slot, plus the legacy plaintext slot kept for
  // one-way migration of existing installs.
  static const String _saveSealed = 'lr_save_v2';
  static const String _saveLegacy = 'lr_save_v1';

  Floor get here => floors[floor - 1];

  double get coreMul => 1 + lumenCore * 0.08;
  int get pickupCap => 8 + capLv * 4;
  double get rSpeed => 0.38 * (1 + speedLv * 0.16);
  double get magnetR => 0.022 + magnetLv * 0.014;
  double get rushMul => rushLeft > 0 ? 1.55 : 1;
  double get goldShopMul => goldLeft > 0 ? 2 : 1;

  SharedPreferences? _prefs;

  Future<void> boot() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
    sfx.volume = sound;
    sfx.haptics = haptics;
    if (floors.isEmpty) {
      _freshTower();
    } else {
      _seedLoot = false;
      for (var i = 0; i < floors.length; i++) {
        if (i < highest) floors[i].unlocked = true;
      }
      if (!floors[floor - 1].unlocked) {
        floor = 1;
      }
    }
    _recountLit();
    if (missions.isEmpty) _rollMissions();
  }

  void finishBoot() {
    view = UiView.menu;
    sheet = SheetKind.none;
    _note();
  }

  void go(UiView v) {
    sheet = SheetKind.none;
    view = v;
    if (v == UiView.tower) {
      _enterFloor(floor);
      if (bellsOn == 0) {
        say('Tap the gold bell. R walks over and lights the net.');
      }
    }
    persist();
    _note();
  }

  void openSheet(SheetKind k) {
    sheet = k;
    sfx.play(k == SheetKind.none ? SfxFile.close : SfxFile.open, bump: true);
    _note();
  }

  void closeSheet() {
    if (sheet == SheetKind.none) return;
    sheet = SheetKind.none;
    sfx.play(SfxFile.close, bump: true);
    _note();
  }

  void back() {
    if (sheet != SheetKind.none) {
      closeSheet();
      return;
    }
    if (placing) {
      placing = false;
      placeId = null;
      _note();
      return;
    }
    if (view == UiView.web) {
      view = returnTo == UiView.web ? UiView.menu : returnTo;
      _note();
      return;
    }
    if (view == UiView.tower || view == UiView.settings) {
      view = UiView.menu;
      _note();
    }
  }

  void openWeb(String url, String title, {bool whiten = false}) {
    returnTo = view == UiView.web ? UiView.menu : view;
    webUrl = url;
    webTitle = title;
    webWhiten = whiten;
    view = UiView.web;
    sfx.play(SfxFile.open, bump: true);
    _note();
  }

  void say(String m) {
    toast = m;
    toastGen++;
    final g = toastGen;
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (toastGen == g) {
        toast = null;
        _note();
      }
    });
    _note();
  }

  void step(double dt) {
    if (view != UiView.tower) {
      saveAcc += dt;
      if (saveAcc > 4) {
        saveAcc = 0;
        persist();
      }
      return;
    }
    time += dt;
    if (rushLeft > 0) rushLeft = max(0, rushLeft - dt);
    if (goldLeft > 0) goldLeft = max(0, goldLeft - dt);
    _moveR(dt);
    _magnet();
    _produce(dt);
    _sparks(dt);

    if (event != null) {
      event!.left -= dt;
      if (event!.left <= 0) _endEvent();
    } else {
      eventIn -= dt;
      if (eventIn <= 0) _rollEvent();
    }

    saveAcc += dt;
    if (saveAcc > 4) {
      saveAcc = 0;
      persist();
    }
    uiAcc += dt;
    if (dirtyUi || uiAcc > 0.25) {
      uiAcc = 0;
      dirtyUi = false;
      notifyListeners();
    }
  }

  void tapWorld(OffsetN n) {
    if (placing && placeId != null) {
      final s = _nearSlot(n, 0.16, empty: true, open: true);
      if (s == null) {
        say('Choose an open platform.');
        sfx.play(SfxFile.fail, bump: true);
        return;
      }
      walkTo = s.pos.copy();
      pendingSlot = s;
      pendingPick = null;
      return;
    }
    Pickup? bestP;
    var bestPd = 0.09;
    for (final p in pickups) {
      final d = p.pos.dist(n);
      if (d < bestPd) {
        bestPd = d;
        bestP = p;
      }
    }
    if (bestP != null) {
      walkTo = bestP.pos.copy();
      pendingPick = bestP;
      pendingSlot = null;
      pendingTune = null;
      return;
    }
    final s = _nearSlot(n, 0.13);
    if (s != null) {
      walkTo = s.pos.copy();
      pendingSlot = s;
      pendingPick = null;
      return;
    }
    walkTo = n;
    pendingSlot = null;
    pendingPick = null;
    pendingTune = null;
  }

  bool canPay(ItemDef d) {
    final p = price(d);
    return coins >= p.$1 && fruits >= p.$2 && stars >= p.$3;
  }

  (int, int, int) price(ItemDef d) {
    final m = pow(1.28, max(0, floor - d.minFloor)).toDouble();
    final a = pow(1.12, ascension).toDouble();
    return (
      (d.coins * m * a).round(),
      (d.fruits * m * a).round(),
      (d.stars * (1 + ascension * 0.15)).round(),
    );
  }

  void chooseBuild(ItemDef d) {
    if (floor < d.minFloor) {
      say('Opens on floor ${d.minFloor}.');
      sfx.play(SfxFile.fail, bump: true);
      return;
    }
    if (d.id == 'grand') {
      final has = here.slots.any((s) => s.building?.defId == 'grand');
      if (has) {
        say('The Grand Aegis already stands here.');
        sfx.play(SfxFile.fail, bump: true);
        return;
      }
    }
    if (!canPay(d)) {
      say('Not enough resources.');
      sfx.play(SfxFile.fail, bump: true);
      return;
    }
    placeId = d.id;
    placing = true;
    pendingTune = null;
    sheet = SheetKind.none;
    say('Tap an open platform to raise the ${d.name}.');
    sfx.play(SfxFile.click, bump: true);
    _note();
  }

  void cancelPlace() {
    placing = false;
    placeId = null;
    pendingTune = null;
    _note();
  }

  int lightNeed(int f) {
    const t = [
      0,
      0,
      26,
      55,
      95,
      150,
      230,
      340,
      480,
      680,
      940,
      1280,
      1750,
      2380,
      3200,
      4300,
      5800,
    ];
    final raw = t[f.clamp(0, 16)];
    return max(8, (raw * pow(0.93, min(lumenCore, 10))).round());
  }

  int slotCost() {
    final closed = here.slots.where((s) => !s.open).length;
    return (55 *
            pow(1.4, here.slots.length - closed - 2) *
            (here.risky ? 1.3 : 1))
        .round();
  }

  void unveilSlot() {
    final s = here.slots.firstWhere(
      (e) => !e.open,
      orElse: () => here.slots.first,
    );
    if (s.open) {
      say('This floor is fully opened.');
      return;
    }
    final c = slotCost();
    if (coins < c) {
      say('Need $c coins to unveil a platform.');
      sfx.play(SfxFile.fail, bump: true);
      return;
    }
    coins -= c;
    s.open = true;
    sfx.play(SfxFile.floor, bump: true);
    say('A new platform rises.');
    persist();
    _note();
  }

  void unlockFloor(int f, {required bool risky}) {
    if (f != highest + 1 || f > maxFloor) return;
    var need = lightNeed(f);
    if (risky) need = (need * 1.6).round();
    if (light < need) {
      say('Need ${need.round()} light.');
      sfx.play(SfxFile.fail, bump: true);
      return;
    }
    light -= need;
    floors[f - 1].unlocked = true;
    floors[f - 1].risky = risky;
    highest = f;
    floorsOpened++;
    _stat('floorsOpened');
    sfx.play(SfxFile.floor, bump: true);
    sfx.play(SfxFile.energy);
    say(
      risky
          ? 'A radiant floor — louder, hungrier.'
          : 'A stable floor takes the light.',
    );
    persist();
    _note();
  }

  void enterFloor(int f) {
    if (f < 1 || f > maxFloor) return;
    if (!floors[f - 1].unlocked) {
      say('That floor is still dark.');
      sfx.play(SfxFile.fail, bump: true);
      return;
    }
    floor = f;
    _enterFloor(f);
    sheet = SheetKind.none;
    view = UiView.tower;
    sfx.play(SfxFile.click, bump: true);
    persist();
    _note();
  }

  void buyUpgrade(String id) {
    final lv = _lv(id);
    if (lv >= 8) {
      say('Already at the peak.');
      return;
    }
    final c = upgradeCost(id);
    if (coins < c) {
      say('Need $c coins.');
      sfx.play(SfxFile.fail, bump: true);
      return;
    }
    coins -= c;
    _setLv(id, lv + 1);
    sfx.play(SfxFile.reward, bump: true);
    persist();
    _note();
  }

  int upgradeCost(String id) {
    final lv = _lv(id);
    return (70 * pow(1.55, lv)).round();
  }

  int _lv(String id) {
    switch (id) {
      case 'speed':
        return speedLv;
      case 'magnet':
        return magnetLv;
      case 'charge':
        return chargeLv;
      default:
        return capLv;
    }
  }

  void _setLv(String id, int v) {
    switch (id) {
      case 'speed':
        speedLv = v;
        break;
      case 'magnet':
        magnetLv = v;
        break;
      case 'charge':
        chargeLv = v;
        break;
      default:
        capLv = v;
    }
  }

  void pickSkin(String id) {
    final d = Catalog.skin(id);
    if (!unlockedSkins.contains(id)) {
      if (stars < d.stars || lumenCore < d.cores) {
        say('Not yet. Keep climbing.');
        sfx.play(SfxFile.fail, bump: true);
        return;
      }
      stars -= d.stars;
      lumenCore -= d.cores;
      unlockedSkins.add(id);
      sfx.play(SfxFile.reward, bump: true);
    }
    skin = id;
    sfx.play(SfxFile.click, bump: true);
    persist();
    _note();
  }

  void shopBoost(String id) {
    switch (id) {
      case 'rush':
        if (fruits < 18) {
          say('Need 18 fruit.');
          sfx.play(SfxFile.fail, bump: true);
          return;
        }
        fruits -= 18;
        rushLeft = 45;
        say('Lumen Rush — the whole floor leans in.');
        break;
      case 'gold':
        if (coins < 90) {
          say('Need 90 coins.');
          sfx.play(SfxFile.fail, bump: true);
          return;
        }
        coins -= 90;
        goldLeft = 30;
        say('Gold surge bottled and popped.');
        break;
      case 'cut':
        if (stars < 3) {
          say('Need 3 stars.');
          sfx.play(SfxFile.fail, bump: true);
          return;
        }
        stars -= 3;
        light += lightNeed(min(highest + 1, maxFloor)) * 0.35;
        say('Star lens — a slice of the next climb, prepaid.');
        break;
      default:
        return;
    }
    sfx.play(SfxFile.reward, bump: true);
    persist();
    _note();
  }

  void claimMission(Mission m) {
    if (m.claimed || m.progress < m.target) return;
    m.claimed = true;
    coins += m.rc;
    fruits += m.rf;
    stars += m.rs;
    sfx.play(SfxFile.reward, bump: true);
    persist();
    _note();
  }

  void takeEvent() {
    final e = event;
    if (e == null) return;
    if (!e.claimed) {
      e.claimed = true;
      coins += e.rc;
      fruits += e.rf;
      stars += e.rs;
      sfx.play(SfxFile.reward, bump: true);
      persist();
    }
    sheet = SheetKind.none;
    _note();
  }

  bool get canAscend {
    if (highest < maxFloor) return false;
    final g = floors.last.slots.any(
      (s) => s.building?.defId == 'grand' && s.building!.active,
    );
    return g || light >= lightNeed(maxFloor) * 1.2;
  }

  void offerAscend() {
    if (!canAscend) {
      say('Ring the Grand Aegis on floor $maxFloor first.');
      return;
    }
    sheet = SheetKind.ascension;
    sfx.play(SfxFile.core, bump: true);
    _note();
  }

  void ascend() {
    final cores =
        1 + (highest ~/ 8) + (floors.where((f) => f.risky).length >= 4 ? 1 : 0);
    last = LastRun()
      ..floor = highest
      ..coins = coinsTaken
      ..fruits = fruitsTaken
      ..stars = starsTaken
      ..cores = cores
      ..starsEarned = highest >= 16 ? 3 : (highest >= 10 ? 2 : 1);
    lumenCore += cores;
    coins = 70 + lumenCore * 8;
    fruits = 4 + lumenCore;
    stars = 1;
    light = 0;
    floor = 1;
    highest = 1;
    ascension += 1;
    placing = false;
    placeId = null;
    pickups.clear();
    sparks.clear();
    event = null;
    harvestMul = goldMul = starMul = lightMul = 1;
    rushLeft = 0;
    goldLeft = 0;
    outageSlot = -1;
    coinsTaken = fruitsTaken = starsTaken = bellsOn = floorsOpened = 0;
    _freshTower();
    _rollMissions();
    sheet = SheetKind.result;
    view = UiView.tower;
    sfx.play(SfxFile.win, bump: true);
    persist();
    _note();
  }

  void setSound(double v, {bool save = true}) {
    sound = v.clamp(0, 1);
    sfx.volume = sound;
    if (save) persist();
    notifyListeners();
  }

  void setMusic(double v, {bool save = true}) {
    music = v.clamp(0, 1);
    if (save) persist();
    notifyListeners();
  }

  void setHaptics(bool v) {
    haptics = v;
    sfx.haptics = v;
    persist();
    notifyListeners();
  }

  void setPower(bool v) {
    powerSave = v;
    persist();
    notifyListeners();
  }

  Future<void> persist() async {
    final p = _prefs;
    if (p == null) return;
    final j = {
      'coins': coins,
      'fruits': fruits,
      'stars': stars,
      'light': light,
      'core': lumenCore,
      'floor': floor,
      'highest': highest,
      'asc': ascension,
      'spd': speedLv,
      'mag': magnetLv,
      'chg': chargeLv,
      'cap': capLv,
      'music': music,
      'sound': sound,
      'hap': haptics ? 1 : 0,
      'ps': powerSave ? 1 : 0,
      'skin': skin,
      'skins': unlockedSkins.toList(),
      'found': found.toList(),
      'floors': floors.map((e) => e.toJ()).toList(),
      'missions': missions.map((e) => e.toJ()).toList(),
    };
    final String payload = jsonEncode(j);
    final String? sealed = sealSave(payload);
    if (sealed != null) {
      // Tamper-evident blob from the native vault; drop the legacy plaintext.
      await p.setString(_saveSealed, sealed);
      await p.remove(_saveLegacy);
    } else {
      // Native vault unavailable (e.g. non-Android/dev): plaintext fallback.
      await p.setString(_saveLegacy, payload);
    }
  }

  void _load() {
    final p = _prefs;
    final String? sealed = p?.getString(_saveSealed);
    String? raw;
    if (sealed != null) {
      raw = openSave(sealed);
      // Missing/tampered blob (MAC mismatch) -> refuse it and start fresh.
      if (raw == null) return;
    } else {
      // Legacy plaintext save; migrated to the sealed slot on next persist().
      raw = p?.getString(_saveLegacy);
    }
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      int n(String k, int d) => (j[k] as num?)?.toInt() ?? d;
      coins = n('coins', coins);
      fruits = n('fruits', 0);
      stars = n('stars', 0);
      light = (j['light'] as num?)?.toDouble() ?? 0;
      lumenCore = n('core', 0);
      floor = n('floor', 1).clamp(1, maxFloor);
      highest = n('highest', 1).clamp(1, maxFloor);
      if (floor > highest) floor = highest;
      ascension = n('asc', 0);
      speedLv = n('spd', 0);
      magnetLv = n('mag', 0);
      chargeLv = n('chg', 0);
      capLv = n('cap', 0);
      music = (j['music'] as num?)?.toDouble() ?? music;
      sound = (j['sound'] as num?)?.toDouble() ?? sound;
      haptics = j['hap'] != 0;
      powerSave = j['ps'] == 1;
      skin = j['skin'] as String? ?? 'r_main';
      unlockedSkins
        ..clear()
        ..addAll(((j['skins'] as List?) ?? ['r_main']).cast<String>());
      found
        ..clear()
        ..addAll(((j['found'] as List?) ?? ['gb0']).cast<String>());
      final fl = j['floors'] as List?;
      if (fl != null) {
        floors
          ..clear()
          ..addAll(
            List.generate(maxFloor, (i) {
              final deco = _decoFor(i + 1);
              final match = fl.cast<Map>().where((e) => e['i'] == i + 1);
              if (match.isEmpty) return _makeFloor(i + 1, unlocked: i == 0);
              final loaded = Floor.fromJ(match.first, deco);
              if (i == 0) loaded.unlocked = true;
              return loaded;
            }),
          );
      }
      final ms = j['missions'] as List?;
      if (ms != null) {
        missions
          ..clear()
          ..addAll(ms.map((e) => Mission.fromJ(e as Map)));
      }
    } catch (_) {}
  }

  void _freshTower() {
    floors
      ..clear()
      ..addAll(
        List.generate(maxFloor, (i) => _makeFloor(i + 1, unlocked: i == 0)),
      );
    final s0 = floors[0].slots.first;
    s0.open = true;
    s0.building = Placed('gb0', active: false);
    r = OffsetN(0.50, 0.72);
    _seedLoot = true;
    pickups.clear();
  }

  Floor _makeFloor(int i, {required bool unlocked}) {
    final layout = _layout(i);
    final openN = i == 1 ? 2 : (i < 6 ? 3 : 4);
    final slots = <Slot>[];
    for (var n = 0; n < layout.length; n++) {
      slots.add(
        Slot(
          pos: layout[n],
          plat: (i + n) % 4,
          lightPlat: i >= 7 && n.isOdd,
          open: n < openN,
        ),
      );
    }
    return Floor(i, unlocked: unlocked, slots: slots, deco: _decoFor(i));
  }

  List<OffsetN> _layout(int i) {
    final base = <List<OffsetN>>[
      [
        OffsetN(0.24, 0.66),
        OffsetN(0.46, 0.74),
        OffsetN(0.68, 0.62),
        OffsetN(0.82, 0.52),
        OffsetN(0.34, 0.50),
        OffsetN(0.58, 0.46),
      ],
      [
        OffsetN(0.22, 0.60),
        OffsetN(0.40, 0.72),
        OffsetN(0.62, 0.68),
        OffsetN(0.80, 0.56),
        OffsetN(0.50, 0.50),
        OffsetN(0.70, 0.44),
      ],
      [
        OffsetN(0.28, 0.70),
        OffsetN(0.50, 0.64),
        OffsetN(0.72, 0.72),
        OffsetN(0.84, 0.50),
        OffsetN(0.38, 0.48),
        OffsetN(0.60, 0.42),
      ],
    ];
    final pick = base[(i - 1) % base.length];
    final n = i >= 14 ? 6 : (i >= 8 ? 5 : 4);
    return pick.take(n).map((e) => OffsetN(e.x, e.y)).toList();
  }

  List<Decor> _decoFor(int i) {
    final a = (i * 3) % 4;
    final b = (i * 5 + 1) % 4;
    return [
      Decor(OffsetN(0.10, 0.58), 'decor_$a', 92),
      Decor(OffsetN(0.90, 0.50), 'decor_$b', 86),
      if (i >= 5) Decor(OffsetN(0.14, 0.42), 'decor_${(a + 2) % 4}', 78),
    ];
  }

  void _recountLit() {
    var n = 0;
    for (final f in floors) {
      for (final s in f.slots) {
        if (s.building?.active == true) n++;
      }
    }
    bellsOn = n;
  }

  void _enterFloor(int f) {
    walkTo = null;
    pendingSlot = null;
    pendingTune = null;
    pendingPick = null;
    placing = false;
    placeId = null;
    _bankPickups();
    r = OffsetN(0.50, 0.78);
    if (_seedLoot && f == 1) {
      _seedLoot = false;
      pickups
        ..add(Pickup(PickupKind.coin, OffsetN(0.46, 0.74), 8, 0, 0.2))
        ..add(Pickup(PickupKind.coin, OffsetN(0.58, 0.70), 6, 1, 1.1));
    }
  }

  void _bankPickups() {
    for (final p in pickups) {
      switch (p.kind) {
        case PickupKind.coin:
          coins += p.amount;
          coinsTaken += p.amount;
          _stat('coinsTaken', p.amount);
          break;
        case PickupKind.fruit:
          fruits += p.amount;
          fruitsTaken += p.amount;
          _stat('fruitsTaken', p.amount);
          break;
        case PickupKind.star:
          stars += p.amount;
          starsTaken += p.amount;
          _stat('starsTaken', p.amount);
          break;
      }
    }
    pickups.clear();
  }

  void _moveR(double dt) {
    final t = walkTo;
    if (t == null) return;
    final d = r.dist(t);
    final step = rSpeed * dt;
    if (d <= step || d < 0.012) {
      r.x = t.x;
      r.y = t.y;
      walkTo = null;
      _arrive();
      return;
    }
    r.x += (t.x - r.x) / d * step;
    r.y += (t.y - r.y) / d * step;
  }

  void _arrive() {
    if (pendingPick != null) {
      _grab(pendingPick!);
      pendingPick = null;
    }
    final s = pendingSlot;
    pendingSlot = null;
    if (s == null) return;
    if (placing && placeId != null && s.open && s.building == null) {
      _dropOn(s);
      if (s.building != null && !s.building!.active) _ring(s);
      return;
    }
    if (s.building != null && !s.building!.active) {
      pendingTune = null;
      _ring(s);
    } else if (s.building != null && s.building!.active) {
      if (identical(pendingTune, s)) {
        pendingTune = null;
        _tune(s);
      } else {
        pendingTune = s;
        final b = s.building!;
        final name = Catalog.tryItem(b.defId)?.name ?? 'bell';
        if (b.level >= 8) {
          say('This $name is fully tuned.');
        } else {
          say(
            '$name Lv.${b.level}. Tap again to tune for ${tuneCost(b)} coins.',
          );
        }
      }
    }
  }

  int tuneCost(Placed b) => (55 * pow(1.48, max(0, b.level - 1))).round();

  void _tune(Slot s) {
    final b = s.building;
    if (b == null) return;
    final def = Catalog.tryItem(b.defId);
    final name = def?.name ?? 'bell';
    if (b.level >= 8) {
      say('This $name is fully tuned.');
      return;
    }
    final c = tuneCost(b);
    if (coins < c) {
      say('Need $c coins to tune this $name.');
      sfx.play(SfxFile.fail, bump: true);
      return;
    }
    coins -= c;
    b.level++;
    sfx.play(SfxFile.reward, bump: true);
    say('$name tuned to level ${b.level}.');
    persist();
    dirtyUi = true;
  }

  void _dropOn(Slot s) {
    final id = placeId!;
    final d = Catalog.item(id);
    final p = price(d);
    if (!canPay(d)) {
      say('The cost slipped away.');
      placing = false;
      placeId = null;
      return;
    }
    coins -= p.$1;
    fruits -= p.$2;
    stars -= p.$3;
    s.building = Placed(id);
    found.add(id);
    placing = false;
    placeId = null;
    sfx.play(SfxFile.energy, bump: true);
    say('${d.name} joins the net.');
    persist();
    dirtyUi = true;
  }

  void _ring(Slot s) {
    final b = s.building!;
    if (outageSlot == here.slots.indexOf(s)) {
      say('This bell is overloaded. Wait it out.');
      sfx.play(SfxFile.fail, bump: true);
      return;
    }
    b.active = true;
    bellsOn++;
    _stat('bellsOn');
    sfx.play(SfxFile.bell, bump: true);
    sfx.play(SfxFile.arc);
    if (here.slots.where((e) => e.building?.active == true).length >= 2) {
      sfx.play(SfxFile.chain);
    }
    if (!powerSave) _burst(s.pos, 0xFFF6C445);
    dirtyUi = true;
    persist();
  }

  void _grab(Pickup p) {
    if (!pickups.contains(p)) return;
    pickups.remove(p);
    switch (p.kind) {
      case PickupKind.coin:
        coins += p.amount;
        coinsTaken += p.amount;
        _stat('coinsTaken', p.amount);
        sfx.play(SfxFile.coin);
        break;
      case PickupKind.fruit:
        fruits += p.amount;
        fruitsTaken += p.amount;
        _stat('fruitsTaken', p.amount);
        sfx.play(SfxFile.fruit);
        break;
      case PickupKind.star:
        stars += p.amount;
        starsTaken += p.amount;
        _stat('starsTaken', p.amount);
        sfx.play(SfxFile.star);
        break;
    }
    if (!powerSave) _burst(p.pos, 0xFFFFFFFF);
    dirtyUi = true;
  }

  void _magnet() {
    final reach = magnetR;
    final hit = pickups
        .where((p) => p.pos.dist(r) <= reach)
        .toList(growable: false);
    for (final p in hit) {
      _grab(p);
    }
  }

  void _produce(double dt) {
    final charge = 1 + chargeLv * 0.11;
    for (final fl in floors) {
      if (!fl.unlocked) continue;
      final onThis = fl.index == floor;
      final mul = coreMul * (fl.risky ? 1.45 : 1) * rushMul * charge;
      for (var i = 0; i < fl.slots.length; i++) {
        final s = fl.slots[i];
        final b = s.building;
        if (b == null || !b.active) continue;
        if (onThis && i == outageSlot) continue;
        b.pulse += dt;
        final d = Catalog.tryItem(b.defId);
        if (d == null) continue;
        final lv = 1 + (b.level - 1) * 0.18;
        b.accC += d.coinRate * mul * goldMul * goldShopMul * lv * dt;
        b.accF += d.fruitRate * mul * harvestMul * lv * dt;
        b.accS += d.starRate * mul * starMul * lv * dt;
        light += d.lightRate * mul * lightMul * lv * dt;
        if (onThis) {
          _maybeSpawn(s, b);
        } else {
          if (b.accC >= 8) {
            coins += b.accC.floor();
            b.accC -= b.accC.floor();
          }
          if (b.accF >= 3) {
            fruits += b.accF.floor();
            b.accF -= b.accF.floor();
          }
          if (b.accS >= 1) {
            stars += b.accS.floor();
            b.accS -= b.accS.floor();
          }
        }
      }
    }
    while (pickups.length > pickupCap) {
      final p = pickups.removeAt(0);
      switch (p.kind) {
        case PickupKind.coin:
          coins += p.amount;
          break;
        case PickupKind.fruit:
          fruits += p.amount;
          break;
        case PickupKind.star:
          stars += p.amount;
          break;
      }
    }
  }

  void _maybeSpawn(Slot s, Placed b) {
    void drop(
      PickupKind k,
      double acc,
      void Function(double) set,
      int frameN,
      int amt,
    ) {
      if (acc < amt) return;
      set(acc - amt);
      if (pickups.length >= pickupCap) {
        switch (k) {
          case PickupKind.coin:
            coins += amt;
            break;
          case PickupKind.fruit:
            fruits += amt;
            break;
          case PickupKind.star:
            stars += amt;
            break;
        }
        return;
      }
      final jx = (rng.nextDouble() - 0.5) * 0.10;
      final jy = (rng.nextDouble() - 0.5) * 0.06;
      pickups.add(
        Pickup(
          k,
          OffsetN(s.pos.x + jx, s.pos.y + 0.08 + jy.abs()),
          amt,
          rng.nextInt(frameN),
          rng.nextDouble() * 6,
        ),
      );
    }

    if (b.accC >= 6) {
      final amt = min(14, b.accC.floor());
      drop(PickupKind.coin, b.accC, (v) => b.accC = v, 4, amt);
    }
    if (b.accF >= 3) {
      final amt = min(6, b.accF.floor());
      drop(PickupKind.fruit, b.accF, (v) => b.accF = v, 4, amt);
    }
    if (b.accS >= 1) {
      drop(PickupKind.star, b.accS, (v) => b.accS = v, 4, 1);
    }
  }

  void _sparks(double dt) {
    for (final s in sparks) {
      s.p.x += s.v.x * dt;
      s.p.y += s.v.y * dt;
      s.life -= dt;
    }
    sparks.removeWhere((s) => s.life <= 0);
  }

  void _burst(OffsetN at, int argb) {
    for (var i = 0; i < 8; i++) {
      final a = rng.nextDouble() * pi * 2;
      sparks.add(
        Spark(
          at.copy(),
          OffsetN(cos(a) * 0.18, sin(a) * 0.14),
          0.35 + rng.nextDouble() * 0.25,
          argb,
        ),
      );
    }
  }

  Slot? _nearSlot(
    OffsetN n,
    double maxD, {
    bool empty = false,
    bool open = false,
  }) {
    Slot? best;
    var bd = maxD;
    for (final s in here.slots) {
      if (open && !s.open) continue;
      if (empty && s.building != null) continue;
      final d = s.pos.dist(n);
      if (d < bd) {
        bd = d;
        best = s;
      }
    }
    return best;
  }

  void _stat(String k, [int n = 1]) {
    for (final m in missions) {
      if (m.stat == k && !m.claimed) {
        m.progress = min(m.target, m.progress + n);
      }
    }
  }

  void _rollMissions() {
    missions
      ..clear()
      ..addAll([
        Mission(
          id: 'coin_run',
          title: 'Coin Run',
          hint: 'Collect coins from the floor.',
          stat: 'coinsTaken',
          target: 180,
          rc: 40,
        ),
        Mission(
          id: 'ringer',
          title: 'Ringer',
          hint: 'Ignite bells and structures.',
          stat: 'bellsOn',
          target: 4,
          rf: 8,
        ),
        Mission(
          id: 'rise',
          title: 'Rise Higher',
          hint: 'Unlock a new floor.',
          stat: 'floorsOpened',
          target: 1,
          rs: 2,
        ),
      ]);
  }

  void _rollEvent() {
    eventIn = 90 + rng.nextDouble() * 50;
    if (bellsOn == 0) {
      eventIn = 40;
      return;
    }
    var roll = rng.nextInt(5);
    if (roll == 2 && !here.slots.any((s) => s.building?.active == true)) {
      roll = 0;
    }
    switch (roll) {
      case 0:
        harvestMul = 2.2;
        event = GameEvent(
          id: 'harvest',
          title: 'Fruit Harvest',
          body:
              'Orchards along the tower swell. Fruit production is doubled while the season lasts.',
          kind: 'harvest',
          art: 'fruits_a_2',
          left: 28,
          rf: 6,
        );
        break;
      case 1:
        goldMul = 2.0;
        event = GameEvent(
          id: 'surge',
          title: 'Golden Surge',
          body: 'A gold pulse runs the network. Coin bells ring fat and fast.',
          kind: 'surge',
          art: 'coins_0',
          left: 24,
          rc: 30,
        );
        break;
      case 2:
        final live = <int>[];
        for (var i = 0; i < here.slots.length; i++) {
          if (here.slots[i].building?.active == true) live.add(i);
        }
        if (live.isNotEmpty) outageSlot = live[rng.nextInt(live.length)];
        event = GameEvent(
          id: 'outage',
          title: 'Bell Outage',
          body:
              'One chime seizes up. Reroute the net — or wait for it to cool.',
          kind: 'outage',
          art: 'golden_bells_2',
          left: 22,
        );
        break;
      case 3:
        starMul = 2.4;
        event = GameEvent(
          id: 'starfall',
          title: 'Star Fall',
          body:
              'A rare star shears across the terrace. Star bells drink it in.',
          kind: 'starfall',
          art: 'stars_0',
          left: 20,
          rs: 2,
        );
        pickups.add(Pickup(PickupKind.star, OffsetN(0.5, 0.55), 2, 0, 0));
        break;
      default:
        lightMul = 1.8;
        event = GameEvent(
          id: 'overload',
          title: 'Network Overload',
          body: 'The lattice runs hot. Light pours, but the net is brittle.',
          kind: 'overload',
          art: 'advanced_bells_0',
          left: 18,
        );
        break;
    }
    sheet = SheetKind.event;
    sfx.play(SfxFile.open, bump: true);
    dirtyUi = true;
  }

  void _endEvent() {
    harvestMul = 1;
    goldMul = 1;
    starMul = 1;
    lightMul = 1;
    outageSlot = -1;
    event = null;
    if (sheet == SheetKind.event) sheet = SheetKind.none;
    dirtyUi = true;
  }

  void refresh() => notifyListeners();

  void _note() => notifyListeners();

  String bgFor(int f) {
    if (f <= 5) return Paths.bgLow;
    if (f <= 11) return Paths.bgMid;
    return Paths.bgHigh;
  }

  String pickupSprite(Pickup p) {
    switch (p.kind) {
      case PickupKind.coin:
        return 'coins_${p.frame % 4}';
      case PickupKind.fruit:
        return p.frame.isEven
            ? 'fruits_a_${p.frame % 4}'
            : 'fruits_b_${p.frame % 4}';
      case PickupKind.star:
        return 'stars_${p.frame % 4}';
    }
  }

  String get rSprite => Catalog.skin(skin).sprite;
}
