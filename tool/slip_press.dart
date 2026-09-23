// ignore_for_file: avoid_print
// Writes lib/drawer/slips.dart. Mixer lives in lib/drawer/veil.dart.
//   LR_RELAY_SECRET=... dart run tool/slip_press.dart

import 'dart:io';

import 'package:lumenrise/drawer/veil.dart';

const String _syncUrl = 'https://lumenrise.link/edge/sync';
const String _gcdRoot = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';

// Fill these, then re-run the tool with LR_RELAY_SECRET set to the same
// value that is in /opt/relay/.env on the VPS.
const String _campaignKey = 'Ywq56D4yAUSoA8PkzJ97xG';
const String _projectNumber = '808551333771';

const String _rimScript = r'''
(function(){
  if (window.__lrRim) { return; }
  window.__lrRim = 1;

  var TAG = 'lr-rim-sheet';
  var RULES = [
    ':root{',
    '--lr-cap:0px!important;',
    '--safe-area-inset-top:0px!important;--safe-area-inset-right:0px!important;',
    '--safe-area-inset-bottom:0px!important;--safe-area-inset-left:0px!important;',
    '--sat:0px!important;--sar:0px!important;--sab:0px!important;--sal:0px!important;',
    '--safe-top:0px!important;--safe-bottom:0px!important;',
    '--safe-left:0px!important;--safe-right:0px!important;',
    '}',
    '.lr-cap,.lr-band,.site-header,.top-bar,.app-bar,.js-safe-top',
    '{padding-top:0!important;margin-top:0!important;}'
  ].join('');

  function typing(){
    var vv = window.visualViewport;
    return vv ? (vv.height < window.innerHeight * 0.78) : false;
  }
  function patchMeta(){
    var meta = document.querySelector('meta[name="viewport"]');
    if (!meta) { return; }
    var content = meta.getAttribute('content') || '';
    if (/viewport-fit\s*=\s*contain/i.test(content)) { return; }
    var trimmed = content.replace(/,?\s*viewport-fit\s*=\s*\w+/ig, '').trim();
    meta.setAttribute('content', trimmed ? (trimmed + ', viewport-fit=contain') : 'viewport-fit=contain');
  }
  function pinSheet(){
    var host = document.head || document.documentElement;
    if (!host) { return; }
    var node = document.getElementById(TAG);
    if (!node){
      node = document.createElement('style');
      node.id = TAG;
      host.appendChild(node);
    }
    if (node.textContent !== RULES) { node.textContent = RULES; }
  }
  function apply(){
    if (typing()) { return; }
    patchMeta();
    pinSheet();
  }
  function applyLater(){
    window.setTimeout(apply, 120);
    window.setTimeout(apply, 520);
  }

  apply();

  var story = window.history;
  ['pushState', 'replaceState'].forEach(function(name){
    var original = story[name];
    if (typeof original !== 'function') { return; }
    story[name] = function(){
      var out = original.apply(this, arguments);
      applyLater();
      return out;
    };
  });
  window.addEventListener('popstate', function(){ window.setTimeout(apply, 120); });
  window.setInterval(apply, 3100);
})();
''';

const String _liftScript = r'''
(function () {
  var MARK = '__lrLift';
  if (window[MARK] && window[MARK].live) { return; }

  var LIMIT = 0.9;
  var SLACK = 4;
  var state = { part: 0, shell: null, base: '', lift: 0 };
  var frame = 0;

  function gapPx() {
    var v = (window.innerHeight * 0.015) | 0;
    if (v < 6) { return 6; }
    return v > 16 ? 16 : v;
  }
  function focusNode() {
    var node = document.activeElement;
    if (!node || !node.tagName) { return null; }
    if (node.isContentEditable === true) { return node; }
    var tag = node.tagName.toLowerCase();
    return (tag === 'input' || tag === 'textarea' || tag === 'select') ? node : null;
  }
  function fixedShell(node) {
    var up = node.parentElement;
    while (up && up !== document.body) {
      if (getComputedStyle(up).position === 'fixed') { return up; }
      up = up.parentElement;
    }
    return null;
  }
  function scroller(node) {
    var up = node.parentElement;
    while (up && up !== document.body && up !== document.documentElement) {
      var st = getComputedStyle(up);
      var oy = st.overflowY;
      if ((oy === 'auto' || oy === 'scroll') && up.scrollHeight > up.clientHeight + 1) {
        return up;
      }
      up = up.parentElement;
    }
    return null;
  }
  // Keyboard top edge in client px. visualViewport reflects the IME straight
  // away and never reports a taller keyboard than the real one, so the field
  // is placed at its final seat in one pass instead of chasing the animating
  // platform inset (which caused the over-shoot then settle).
  function keysTop() {
    var vv = window.visualViewport;
    if (vv) {
      var occ = window.innerHeight - (vv.height + vv.offsetTop);
      if (occ > 1) { return window.innerHeight - occ; }
    }
    var p = state.part > LIMIT ? LIMIT : state.part;
    if (p > 0) { return window.innerHeight * (1 - p); }
    return window.innerHeight;
  }
  function open() {
    var vv = window.visualViewport;
    if (vv && vv.height < window.innerHeight - 1) { return true; }
    return state.part > 0;
  }
  function clear() {
    if (state.shell) { state.shell.style.transform = state.base; }
    state.shell = null;
    state.base = '';
    state.lift = 0;
  }
  function move(px) {
    if (px === state.lift) { return; }
    state.lift = px;
    var shift = 'translate3d(0px,' + (-px) + 'px,0px)';
    state.shell.style.transform = state.base ? (state.base + ' ' + shift) : shift;
  }
  function settle() {
    var node = focusNode();
    if (!node || !open()) { clear(); return; }

    var top = keysTop();
    var shell = fixedShell(node);
    if (shell) {
      if (shell !== state.shell) {
        clear();
        state.shell = shell;
        state.base = shell.style.transform || '';
      }
      var rest = node.getBoundingClientRect().bottom + state.lift;
      var need = rest + gapPx() - top;
      move(need > SLACK ? need : 0);
      return;
    }

    // Non-fixed field: drop any held transform and move the owning scroller
    // (or the page) to the exact seat in one write. The delta is signed, so a
    // field the browser pushed too high is brought back down on the same pass.
    clear();
    var delta = node.getBoundingClientRect().bottom + gapPx() - top;
    if (delta < 0 && delta > -SLACK) { return; }
    if (delta > 0 && delta <= SLACK) { return; }
    var sc = scroller(node);
    if (sc) {
      sc.scrollTop += delta;
    } else {
      var doc = document.scrollingElement || document.documentElement;
      doc.scrollTop += delta;
    }
  }
  function plan() {
    if (frame) { return; }
    frame = requestAnimationFrame(function () { frame = 0; settle(); });
  }
  // On focus the browser runs its own scroll-into-view. Pin the scroll where
  // it was, restore it on the next frame, then seat the field ourselves — so
  // there is no jump-then-correct, whether the keyboard is opening or already
  // up and the user taps a different field.
  function onFocusIn() {
    var node = focusNode();
    if (!node) { return; }
    var pin = scroller(node) || document.scrollingElement || document.documentElement;
    var at = pin.scrollTop;
    requestAnimationFrame(function () {
      if (pin.scrollTop !== at) { pin.scrollTop = at; }
      settle();
    });
    setTimeout(plan, 120);
    setTimeout(plan, 320);
  }

  function nudge(value) {
    state.part = value > 0 ? value : 0;
    if (!open()) {
      if (frame) { cancelAnimationFrame(frame); frame = 0; }
      clear();
      return;
    }
    plan();
  }
  nudge.live = 1;
  window[MARK] = nudge;

  document.addEventListener('focusin', onFocusIn, true);
  document.addEventListener('focusout', function () { setTimeout(plan, 0); }, true);
  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', plan);
    window.visualViewport.addEventListener('scroll', plan);
  }
})();
''';

const String _clipScript =
    "(function(){if(window.__lrVid)return;window.__lrVid=1;"
    "function tag(node){if(!node||node.nodeName!=='VIDEO')return;"
    "node.setAttribute('playsinline','');node.setAttribute('webkit-playsinline','');"
    "try{node.playsInline=true;}catch(e){}}"
    "function sweep(){var nodes=document.querySelectorAll('video');"
    "for(var i=0;i<nodes.length;i++)tag(nodes[i]);}"
    "sweep();try{var obs=new MutationObserver(function(){sweep();});"
    "obs.observe(document.documentElement,{childList:true,subtree:true});}catch(e){}})();";

String _fmt(List<int> enc) {
  if (enc.isEmpty) return '<int>[]';
  final StringBuffer buf = StringBuffer('<int>[\n');
  for (int i = 0; i < enc.length; i++) {
    if (i % 12 == 0) buf.write('  ');
    buf.write('0x${enc[i].toRadixString(16).toUpperCase().padLeft(2, '0')}');
    buf.write(',');
    if (i % 12 == 11 || i == enc.length - 1) {
      buf.write('\n');
    } else {
      buf.write(' ');
    }
  }
  buf.write(']');
  return buf.toString();
}

void main() {
  final String secret = Platform.environment['LR_RELAY_SECRET'] ?? '';
  if (secret.isEmpty) {
    stderr.writeln('LR_RELAY_SECRET is empty');
    exitCode = 1;
    return;
  }

  final Map<String, String> values = <String, String>{
    '_syncUrl': _syncUrl,
    '_gcdRoot': _gcdRoot,
    '_campaignKey': _campaignKey,
    '_projectNumber': _projectNumber,
    '_relaySecret': secret,
    '_uaToken': 'Mozilla/5.0',
    '_uaPlatform': '(Linux; Android',
    '_uaBuild': ' Build/',
    '_uaClose': ')',
    '_uaEngine': ' AppleWebKit/',
    '_uaEngineTail': ' (KHTML, like Gecko)',
    '_uaBrowser': ' Chrome/',
    '_uaTrailer': ' Mobile Safari/',
    '_browserRev': '132.0.6834.79',
    '_engineRev': '537.36',
    '_rimScript': _rimScript,
    '_liftScript': _liftScript,
    '_clipScript': _clipScript,
  };

  final StringBuffer body = StringBuffer();
  values.forEach((String name, String plain) {
    final List<int> enc = sealText(plain);
    if (openText(enc) != plain) {
      stderr.writeln('round-trip failed for $name');
      exitCode = 1;
    }
    body.write('const List<int> $name = ${_fmt(enc)};\n\n');
  });

  final String source = '''
import 'veil.dart';

// Generated by tool/slip_press.dart. Do not edit the byte tables by hand.

$body
String pullSyncUrl() => openText(_syncUrl);
String pullGcdRoot() => openText(_gcdRoot);
String pullCampaignKey() => openText(_campaignKey);
String pullProjectNumber() => openText(_projectNumber);
String pullRelaySecret() => openText(_relaySecret);

String pullUaToken() => openText(_uaToken);
String pullUaPlatform() => openText(_uaPlatform);
String pullUaBuild() => openText(_uaBuild);
String pullUaClose() => openText(_uaClose);
String pullUaEngine() => openText(_uaEngine);
String pullUaEngineTail() => openText(_uaEngineTail);
String pullUaBrowser() => openText(_uaBrowser);
String pullUaTrailer() => openText(_uaTrailer);
String pullBrowserRev() => openText(_browserRev);
String pullEngineRev() => openText(_engineRev);

String pullRimScript() => openText(_rimScript);
String pullLiftScript() => openText(_liftScript);
String pullClipScript() => openText(_clipScript);

String pullGcdQuery(String applicationId, String deviceId) {
  final String base = pullGcdRoot();
  if (base.isEmpty) return '';
  return '\$base\$applicationId?device_id=\$deviceId&devkey=\${pullCampaignKey()}';
}
''';

  File('lib/drawer/slips.dart').writeAsStringSync(source);
  print('wrote lib/drawer/slips.dart');
}
