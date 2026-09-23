enum PathMark {
  open('open'),
  sheet('sheet'),
  table('table');

  const PathMark(this.wire);

  final String wire;

  bool get settled => this != PathMark.open;

  static PathMark parse(String? raw) {
    switch (raw) {
      case 'sheet':
        return PathMark.sheet;
      case 'table':
        return PathMark.table;
      default:
        return PathMark.open;
    }
  }
}

sealed class Arrival {
  const Arrival();

  bool get opensSheet => false;
}

final class TableArrival extends Arrival {
  const TableArrival();
}

final class SheetArrival extends Arrival {
  const SheetArrival(this.url, {this.fromCold = false});

  final String url;
  final bool fromCold;

  @override
  bool get opensSheet => true;
}

final class HushArrival extends Arrival {
  const HushArrival({required this.backToTable});

  final bool backToTable;
}

/// Body the upstream answers with. Field names are ours.
class Verdict {
  const Verdict({
    required this.pass,
    this.dest,
    this.until,
    this.note,
  });

  factory Verdict.fromJson(Map<String, dynamic> json) {
    return Verdict(
      pass: json['pass'] == true,
      dest: _text(json['dest']),
      until: _epoch(json['until']),
      note: json['note']?.toString(),
    );
  }

  factory Verdict.no(String note) => Verdict(pass: false, note: note);

  final bool pass;
  final String? dest;
  final int? until;
  final String? note;

  bool get hasDest {
    final String? url = dest;
    return pass && url != null && url.isNotEmpty;
  }
}

String? _text(Object? raw) {
  if (raw is! String) return null;
  final String trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _epoch(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return null;
}
