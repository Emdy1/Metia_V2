import 'package:flutter/material.dart';

class CustomTab extends StatefulWidget {
  const CustomTab({
    super.key,
    required this.controller,
    required this.scheme,
    required this.label,
    required this.index,
  });

  final TabController controller;
  final ColorScheme scheme;
  final String label;
  final int index;

  @override
  State<CustomTab> createState() => _CustomTabState();
}

class _CustomTabState extends State<CustomTab> {
  VoidCallback? _listener;

  void _attach() {
    int counter = 0; // counts listener calls

    _listener = () {
      if (!mounted) return;

      counter++;
      if (counter % 2 == 0) {
        setState(() {}); // only update every second call
      }
    };

    widget.controller.animation?.addListener(_listener!);
  }

  void _detach(TabController controller) {
    controller.animation?.removeListener(_listener!);
  }

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(covariant CustomTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔥 THIS IS THE FIX
    if (oldWidget.controller != widget.controller) {
      _detach(oldWidget.controller);
      _attach();
    }
  }

  @override
  void dispose() {
    _detach(widget.controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double value =
        widget.controller.animation?.value ??
        widget.controller.index.toDouble();

    final double distance = (value - widget.index).abs();
    final double t = (1.0 - distance).clamp(0.0, 1.0);

    final Color background = Color.lerp(
      Colors.transparent,
      widget.scheme.primary,
      t,
    )!;

    final Color textColor = Color.lerp(
      widget.scheme.onSurfaceVariant,
      widget.scheme.onPrimary,
      t,
    )!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.scheme.primaryContainer),
      ),
      child: Text(
        widget.label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
