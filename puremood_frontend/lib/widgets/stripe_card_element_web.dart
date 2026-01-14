import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:puremood_frontend/utils/stripe_web_helper.dart';

class StripeCardElement extends StatefulWidget {
  final double height;
  final bool enabled;

  const StripeCardElement({
    super.key,
    this.height = 56,
    this.enabled = false,
  });

  @override
  State<StripeCardElement> createState() => _StripeCardElementState();
}

class _StripeCardElementState extends State<StripeCardElement> {
  late final String _viewType;
  late final String _elementId;
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'stripe-card-${DateTime.now().microsecondsSinceEpoch}';
    _elementId = 'stripe-card-element-${DateTime.now().microsecondsSinceEpoch}';

    ui.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final element = html.DivElement()
          ..id = _elementId
          ..style.width = '100%'
          ..style.display = 'block'
          ..style.height = '${widget.height}px'
          ..style.padding = '8px 4px'
          ..style.backgroundColor = '#ffffff'
          ..style.border = '1px solid #d5dbe2'
          ..style.borderRadius = '10px';
        return element;
      },
    );

    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mountStripeCard();
      });
    }
  }

  @override
  void didUpdateWidget(covariant StripeCardElement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mountStripeCard();
      });
    }
  }

  @override
  void dispose() {
    StripeWebHelper.destroyCard();
    super.dispose();
  }

  Future<void> _mountStripeCard() async {
    try {
      await StripeWebHelper.mountCard('#$_elementId');
      if (mounted) {
        _mounted = true;
      }
    } catch (_) {
      // Retry once after a short delay if the element isn't ready yet.
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      try {
        await StripeWebHelper.mountCard('#$_elementId');
        if (mounted) {
          _mounted = true;
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
