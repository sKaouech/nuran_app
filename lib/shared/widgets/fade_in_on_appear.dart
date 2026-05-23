import 'package:flutter/material.dart';

/// Fait apparaître son enfant avec un fondu + léger slide vers le haut quand
/// le widget est monté. Idéal pour des cartes en liste qui apparaissent en
/// cascade (utiliser [delay] croissant).
class FadeInOnAppear extends StatefulWidget {
  const FadeInOnAppear({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.slideOffset = 0.1,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;

  /// Décalage initial vertical (0.1 = 10% de la hauteur du widget vers le bas).
  final double slideOffset;

  @override
  State<FadeInOnAppear> createState() => _FadeInOnAppearState();
}

class _FadeInOnAppearState extends State<FadeInOnAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
