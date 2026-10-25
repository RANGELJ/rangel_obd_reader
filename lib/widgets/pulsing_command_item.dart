import 'package:flutter/material.dart';

class PulsingCommandItem extends StatefulWidget {
  const PulsingCommandItem({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<PulsingCommandItem> createState() => _PulsingCommandItemState();
}

class _PulsingCommandItemState extends State<PulsingCommandItem>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  void _updateAnimation() {
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      _animation.repeat(reverse: true);
    } else {
      _animation.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(PulsingCommandItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) _updateAnimation();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final intensity = MediaQuery.disableAnimationsOf(context)
            ? 0.12
            : 0.06 + Curves.easeInOut.transform(_animation.value) * 0.1;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: widget.active
                ? Colors.blue.withValues(alpha: intensity)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.active ? Colors.blue.shade300 : Colors.transparent,
            ),
          ),
          child: child,
        );
      },
    );
  }
}