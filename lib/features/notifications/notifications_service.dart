import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../shared/providers/locale_provider.dart';

const _kEnabledKey = 'notif_enabled';
const _kHourKey = 'notif_hour';
const _kMinuteKey = 'notif_minute';

const _channelId = 'nuran_daily_reminder';
const _channelName = 'Rappels quotidiens';
const _notificationId = 1001;

/// Service de notifications locales pour le rappel quotidien.
class NotificationsService {
  NotificationsService._();
  static final instance = NotificationsService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const init = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(init);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final ios = await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    final android = await androidImpl?.requestNotificationsPermission();
    return ios ?? android ?? true;
  }

  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _plugin.cancel(_notificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        _notificationId,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // En cas d'échec (permissions exact alarm sur Android 12+), on retombe
      // en mode inexact qui n'a pas besoin de permission spéciale.
      if (kDebugMode) {
        debugPrint('Notification schedule fallback: $e');
      }
      await _plugin.zonedSchedule(
        _notificationId,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancel() => _plugin.cancel(_notificationId);
}

/// État des préférences notifications.
@immutable
class NotificationPrefs {
  const NotificationPrefs({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  NotificationPrefs copyWith({bool? enabled, int? hour, int? minute}) {
    return NotificationPrefs(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  NotificationPrefsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static NotificationPrefs _load(SharedPreferences prefs) {
    return NotificationPrefs(
      enabled: prefs.getBool(_kEnabledKey) ?? false,
      hour: prefs.getInt(_kHourKey) ?? 8,
      minute: prefs.getInt(_kMinuteKey) ?? 0,
    );
  }

  Future<void> _persist() async {
    await _prefs.setBool(_kEnabledKey, state.enabled);
    await _prefs.setInt(_kHourKey, state.hour);
    await _prefs.setInt(_kMinuteKey, state.minute);
  }

  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      await NotificationsService.instance.init();
      final granted =
          await NotificationsService.instance.requestPermissions();
      if (!granted) return false;
      await _schedule();
    } else {
      await NotificationsService.instance.cancel();
    }
    state = state.copyWith(enabled: enabled);
    await _persist();
    return true;
  }

  Future<void> setTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _persist();
    if (state.enabled) {
      await _schedule();
    }
  }

  Future<void> _schedule() async {
    await NotificationsService.instance.scheduleDaily(
      hour: state.hour,
      minute: state.minute,
      title: 'Nuran — Rappel quotidien',
      body: 'C\'est le moment d\'avancer dans votre mémorisation du Coran.',
    );
  }
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
        (ref) {
  return NotificationPrefsNotifier(ref.watch(sharedPreferencesProvider));
});
