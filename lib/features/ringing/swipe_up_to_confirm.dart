import 'package:flutter/material.dart';

/// A handle that has to be swiped upwards to fire [onConfirmed]. A tap does
/// nothing, so a half-asleep tap cannot trigger it by accident.
class SwipeUpToConfirm extends StatefulWidget {
  const SwipeUpToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.color,
    this.enabled = true,
    this.threshold = 100,
  });

  final String label;
  final VoidCallback onConfirmed;

  /// Arrow and label color; defaults to the theme's text color.
  final Color? color;
  final bool enabled;

  /// How far, in logical pixels, the handle must travel upwards.
  final double threshold;

  @override
  State<SwipeUpToConfirm> createState() => _SwipeUpToConfirmState();
}

class _SwipeUpToConfirmState extends State<SwipeUpToConfirm>
    with TickerProviderStateMixin {
  static const _flingVelocity = 900.0;

  late final AnimationController _offset = AnimationController(
    vsync: this,
    lowerBound: 0,
    upperBound: 1,
    duration: const Duration(milliseconds: 220),
  );
  late final AnimationController _hint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _offset.dispose();
    _hint.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    final delta = -details.primaryDelta! / widget.threshold;
    _offset.value = (_offset.value + delta).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    final flungUp = (details.primaryVelocity ?? 0) < -_flingVelocity;
    if (_offset.value >= 1 || flungUp) {
      widget.onConfirmed();
    }
    _offset.animateTo(0, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = widget.color ?? Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      onVerticalDragCancel: () => _offset.animateTo(0),
      child: SizedBox(
        width: double.infinity,
        height: widget.threshold + 64,
        child: AnimatedBuilder(
          animation: Listenable.merge([_offset, _hint]),
          builder: (context, _) {
            final lift = _offset.value * widget.threshold;
            final bob = _offset.value == 0 ? _hint.value * 8 : 0.0;
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  bottom: lift + bob,
                  child: Opacity(
                    opacity: widget.enabled ? 1 : 0.4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_double_arrow_up,
                            color: color, size: 32),
                        Text(
                          widget.label,
                          style: textTheme.titleMedium?.copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
