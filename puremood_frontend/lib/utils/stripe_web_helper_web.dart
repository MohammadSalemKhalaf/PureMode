import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

class StripeWebHelper {
  static dynamic _stripe;
  static dynamic _elements;
  static dynamic _card;
  static bool _initialized = false;

  static const String _defaultPublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_test_51SRirbC1OpYfJThc7bOb4XiHVTIsYxaOmEwlUFpcXYnBhfRWxR0Iy8UMiiMYQfWrlxyDUbZiEKMNPplwStSgBUGb00fEYrFql7',
  );

  static Future<void> initialize({String? publishableKey}) async {
    if (_initialized && _stripe != null) {
      return;
    }
    var key = (publishableKey ?? _defaultPublishableKey).trim();
    if (key.isEmpty || key == 'YOUR_STRIPE_PUBLISHABLE_KEY') {
      key = _defaultPublishableKey.trim();
    }
    if (!key.startsWith('pk_')) {
      key = _defaultPublishableKey.trim();
    }
    if (key.isEmpty) {
      throw StateError('Stripe publishable key is missing.');
    }
    dynamic stripeCtor = js_util.getProperty(html.window, 'Stripe');
    if (stripeCtor == null) {
      await _ensureStripeScriptLoaded();
      for (var attempt = 0; attempt < 3 && stripeCtor == null; attempt++) {
        await Future.delayed(const Duration(milliseconds: 300));
        stripeCtor = js_util.getProperty(html.window, 'Stripe');
      }
    }
    if (stripeCtor == null) {
      throw StateError('Stripe.js is not loaded. Make sure it is in web/index.html.');
    }
    _stripe = js_util.callConstructor(stripeCtor, [key]);
    _elements = js_util.callMethod(_stripe!, 'elements', []);
    _initialized = true;
  }

  static Future<void> mountCard(String selector) async {
    if (_elements == null) {
      throw StateError('Stripe elements not initialized.');
    }
    if (_card != null) {
      destroyCard();
    }
    html.Element? mountTarget = html.document.querySelector(selector);
    if (mountTarget == null) {
      for (var attempt = 0; attempt < 8; attempt++) {
        await Future.delayed(const Duration(milliseconds: 120));
        mountTarget = html.document.querySelector(selector);
        if (mountTarget != null) {
          break;
        }
      }
    }
    if (mountTarget == null) {
      throw StateError('Stripe card container not found.');
    }
    final style = js_util.jsify({
      'style': {
        'base': {
          'fontSize': '16px',
          'color': '#2c3e50',
          '::placeholder': {'color': '#9aa3ad'},
        },
      },
    });
    final card = js_util.callMethod(_elements!, 'create', ['card', style]);
    try {
      js_util.callMethod(card, 'mount', [selector]);
      _card = card;
    } catch (e) {
      try {
        js_util.callMethod(card, 'destroy', []);
      } catch (_) {}
      rethrow;
    }
  }

  static Future<String?> confirmPayment(String clientSecret) async {
    if (_stripe == null || _card == null) {
      throw StateError('Stripe card element is not ready.');
    }
    final params = js_util.jsify({
      'payment_method': {
        'card': _card,
      },
    });
    final promise = js_util.callMethod(
      _stripe!,
      'confirmCardPayment',
      [clientSecret, params],
    );
    final result = await js_util.promiseToFuture(promise);
    final error = js_util.getProperty(result, 'error');
    if (error != null) {
      final message = js_util.getProperty(error, 'message');
      return message?.toString() ?? 'Payment failed.';
    }
    return null;
  }

  static void destroyCard() {
    if (_card != null) {
      js_util.callMethod(_card!, 'destroy', []);
      _card = null;
    }
  }

  static Future<void> _ensureStripeScriptLoaded() async {
    final existing =
        html.document.querySelector('script[src*="js.stripe.com/v3"]');
    if (existing is html.ScriptElement) {
      if (js_util.getProperty(html.window, 'Stripe') != null) {
        return;
      }
      final completer = Completer<void>();
      existing.onLoad.listen((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      existing.onError.listen((_) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('Failed to load Stripe.js.'));
        }
      });
      // Fallback polling in case the onLoad event already fired.
      for (var attempt = 0; attempt < 5; attempt++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (js_util.getProperty(html.window, 'Stripe') != null) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          break;
        }
      }
      if (!completer.isCompleted) {
        completer.completeError(StateError('Stripe.js did not initialize.'));
      }
      await completer.future;
      return;
    }

    final script = html.ScriptElement()
      ..src = 'https://js.stripe.com/v3/'
      ..async = true;
    final completer = Completer<void>();
    script.onLoad.listen((_) {
      completer.complete();
    });
    script.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Failed to load Stripe.js.'));
      }
    });
    html.document.head?.append(script);
    await completer.future;
  }
}
