import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A horizontal row of chips that scrolls, with the cut edge faded out.
///
/// Four filter chips do not fit on a 390 pt phone, so the row scrolls — but a
/// chip sliced by the viewport edge reads as a layout bug, not as "there is
/// more". The fade is the affordance: it only appears on the side that
/// actually has content behind it, and disappears once you reach the end.
class FadeScrollRow extends StatefulWidget {
  const FadeScrollRow({super.key, required this.children, this.spacing = 8});

  final List<Widget> children;
  final double spacing;

  @override
  State<FadeScrollRow> createState() => _FadeScrollRowState();
}

class _FadeScrollRowState extends State<FadeScrollRow> {
  final ScrollController _controller = ScrollController();

  bool _overflows = false;
  bool _atStart = true;
  bool _atEnd = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_sync);
    // The overflow is only known once the row has been laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_sync)
      ..dispose();
    super.dispose();
  }

  void _sync() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    final overflows = position.maxScrollExtent > 0.5;
    final atStart = position.pixels <= 0.5;
    final atEnd = position.pixels >= position.maxScrollExtent - 0.5;
    if (overflows == _overflows && atStart == _atStart && atEnd == _atEnd) {
      return;
    }
    setState(() {
      _overflows = overflows;
      _atStart = atStart;
      _atEnd = atEnd;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      child: Row(spacing: widget.spacing, children: widget.children),
    );

    // Nothing to hint at when everything fits.
    if (!_overflows) return content;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fade = math.min(20.0, constraints.maxWidth * 0.25);
        final start = _atStart ? 0.0 : fade / constraints.maxWidth;
        final end = _atEnd ? 1.0 : 1 - fade / constraints.maxWidth;

        return ShaderMask(
          // dstIn keeps the child's own colors and only applies the alpha.
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0, start, math.max(start, end), 1],
          ).createShader(rect),
          child: content,
        );
      },
    );
  }
}
