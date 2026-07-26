import 'package:flutter/material.dart';

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    required this.maxWidth,
    this.alignment = Alignment.topCenter,
    this.expandHeight = true,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;
  final bool expandHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth.clamp(0.0, maxWidth)
            : maxWidth;
        Widget content = SizedBox(width: width, child: child);
        if (expandHeight && constraints.hasBoundedHeight) {
          content = SizedBox(height: constraints.maxHeight, child: content);
        }
        return Align(
          alignment: alignment,
          widthFactor: expandHeight ? null : 1,
          heightFactor: expandHeight ? null : 1,
          child: content,
        );
      },
    );
  }
}

class ResponsiveInsets {
  const ResponsiveInsets._();

  static double horizontal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024) return 40;
    if (width >= 700) return 32;
    return 20;
  }

  static double compactHorizontal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024) return 32;
    if (width >= 700) return 24;
    return 16;
  }
}
