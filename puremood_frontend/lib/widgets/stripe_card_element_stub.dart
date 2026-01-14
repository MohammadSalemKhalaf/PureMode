import 'package:flutter/material.dart';

class StripeCardElement extends StatelessWidget {
  final double height;
  final bool enabled;

  const StripeCardElement({
    super.key,
    this.height = 48,
    this.enabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
