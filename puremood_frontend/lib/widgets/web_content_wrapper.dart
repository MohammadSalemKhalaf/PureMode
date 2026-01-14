import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class WebContentWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const WebContentWrapper({
    super.key,
    required this.child,
    this.maxWidth = 640,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final effectiveMaxWidth =
            screenWidth < maxWidth ? screenWidth : maxWidth;
        final horizontalPadding = screenWidth >= 1600
            ? 96.0
            : screenWidth >= 1200
                ? 64.0
                : screenWidth >= 900
                    ? 40.0
                    : 24.0;
        final verticalPadding = screenWidth >= 1200 ? 32.0 : 20.0;
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        );
      },
    );
  }
}
