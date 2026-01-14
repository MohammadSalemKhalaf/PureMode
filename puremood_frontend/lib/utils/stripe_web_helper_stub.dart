class StripeWebHelper {
  static Future<void> initialize({String? publishableKey}) async {
    throw UnsupportedError('Stripe web helper is only available on web.');
  }

  static Future<void> mountCard(String selector) async {
    throw UnsupportedError('Stripe web helper is only available on web.');
  }

  static Future<String?> confirmPayment(String clientSecret) async {
    throw UnsupportedError('Stripe web helper is only available on web.');
  }

  static void destroyCard() {}
}
