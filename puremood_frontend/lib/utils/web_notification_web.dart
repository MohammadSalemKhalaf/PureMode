import 'dart:html' as html;

Future<void> requestWebNotificationPermission() async {
  if (html.Notification.permission == 'granted') {
    return;
  }
  await html.Notification.requestPermission();
}

Future<void> showWebNotification({
  required String title,
  String? body,
}) async {
  if (html.Notification.permission == 'default') {
    await html.Notification.requestPermission();
  }

  if (html.Notification.permission != 'granted') {
    return;
  }

  html.Notification(
    title,
    body: body ?? '',
    icon: '/icons/Icon-192.png',
    tag: DateTime.now().millisecondsSinceEpoch.toString(),
  );
}
