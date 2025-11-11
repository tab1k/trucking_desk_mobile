import 'package:flutter/material.dart';

class BottomSheetPageRoute<T> extends PageRoute<T> {
  BottomSheetPageRoute({
    required this.builder,
    this.barrierColor = Colors.black54,
    this.barrierLabel,
    this.maintainState = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 250),
  });

  final WidgetBuilder builder;

  @override
  final Color barrierColor;

  @override
  final String? barrierLabel;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }
}