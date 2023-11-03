import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class FadeAnimation extends StatelessWidget {
  final double delay;
  final Widget child;

  const FadeAnimation(this.delay, this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    // Define your custom animation properties
    final tween = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50.0,
      ),
    ]);

    return PlayAnimationBuilder<double>(
      delay: Duration(milliseconds: (500 * delay).round()),
      duration: const Duration(milliseconds: 500),
      tween: tween,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(
              0,
              (1 - value) *
                  -30), // Adjust the translation based on the animation value
          child: child,
        ),
      ),
    );
  }
}
