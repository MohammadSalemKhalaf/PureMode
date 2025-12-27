import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSubscriptionService {
  final storage = FlutterSecureStorage();

  // Subscription types
  static const String free = 'free';
  static const String premium = 'premium';

  Future<String> getSubscriptionType() async {
    return await storage.read(key: 'subscription_type') ?? free;
  }

  Future<void> setSubscriptionType(String type) async {
    await storage.write(key: 'subscription_type', value: type);
  }

  Future<bool> isPremiumUser() async {
    final subscription = await getSubscriptionType();
    final trialActive = await isTrialActive();
    return subscription == premium || trialActive;
  }

  // Check if suggestion requires premium subscription
  bool isPremiumSuggestion(Map<String, dynamic> suggestion) {
    return suggestion['isPremium'] == true;
  }

  // Purchase premium subscription
  Future<void> purchasePremium() async {
    // Here we would integrate with payment system
    await setSubscriptionType(premium);
    // Remove trial expiry if exists
    await storage.delete(key: 'trial_expiry');
  }

  // Start free trial
  Future<void> startFreeTrial() async {
    await setSubscriptionType(premium);
    // Add trial expiry after 7 days
    final expiry = DateTime.now().add(Duration(days: 7));
    await storage.write(key: 'trial_expiry', value: expiry.toIso8601String());
  }

  Future<bool> isTrialActive() async {
    final expiryString = await storage.read(key: 'trial_expiry');
    if (expiryString == null) return false;
    final expiry = DateTime.parse(expiryString);
    return DateTime.now().isBefore(expiry);
  }

  Future<int> getTrialDaysLeft() async {
    final expiryString = await storage.read(key: 'trial_expiry');
    if (expiryString == null) return 0;
    final expiry = DateTime.parse(expiryString);
    final now = DateTime.now();
    if (now.isAfter(expiry)) return 0;
    return expiry.difference(now).inDays;
  }

  // Reset to free (for testing)
  Future<void> resetToFree() async {
    await setSubscriptionType(free);
    await storage.delete(key: 'trial_expiry');
  }
}
