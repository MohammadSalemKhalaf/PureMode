USE puremood;

-- حذف جميع الإشعارات
DELETE FROM notifications;

-- عرض النتيجة
SELECT 'All notifications deleted!' as Status;
SELECT COUNT(*) as RemainingNotifications FROM notifications;
