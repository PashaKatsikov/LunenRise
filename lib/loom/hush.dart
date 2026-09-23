import 'package:flutter/material.dart';

/// Offline plate. No artwork — a dusk gradient, a headline, one retry.
class HushView extends StatefulWidget {
  const HushView({super.key, required this.onRetryBuild});

  final WidgetBuilder onRetryBuild;

  @override
  State<HushView> createState() => _HushViewState();
}

class _HushViewState extends State<HushView> {
  bool _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: widget.onRetryBuild),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final Size size = MediaQuery.of(context).size;
    final double width = landscape
        ? size.width * 0.34
        : (size.width * 0.66).clamp(220.0, 360.0);

    return Scaffold(
      backgroundColor: const Color(0xFF14082E),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF2A1458),
              Color(0xFF14082E),
              Color(0xFF0A0618),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: landscape ? 40 : 28,
            vertical: 24,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 54,
                  color: Color(0xFFF6C445),
                ),
                SizedBox(height: landscape ? 18 : 26),
                Text(
                  'NO INTERNET CONNECTION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFF7F3FF),
                    fontSize: landscape ? 20 : 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Check your connection and try again',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFC9B7E8),
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: landscape ? 26 : 38),
                LoomButton(
                  label: 'Try again',
                  width: width,
                  busy: _busy,
                  compact: landscape,
                  onTap: _retry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoomButton extends StatelessWidget {
  const LoomButton({
    super.key,
    required this.label,
    required this.width,
    required this.onTap,
    this.busy = false,
    this.compact = false,
    this.quiet = false,
  });

  final String label;
  final double width;
  final VoidCallback onTap;
  final bool busy;
  final bool compact;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final Color fill = quiet ? const Color(0xFF241447) : const Color(0xFFF6C445);
    final Color ink = quiet ? const Color(0xFFF7F3FF) : const Color(0xFF2A1608);
    return SizedBox(
      width: width,
      height: compact ? 44 : 52,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: busy ? null : onTap,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(ink),
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
