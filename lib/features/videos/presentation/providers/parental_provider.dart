import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:intl/intl.dart';

class ParentalState {
  final int dailyTimeLimitMinutes; // 0 means unlimited
  final double maxBrightness; // 1.0 means no dimming
  final double maxVolume; // 1.0 means max volume
  final int allowedSnoozes; // 3 default
  final int usedSnoozes; 
  final int consumedTimeSeconds;
  final String lastActiveDate; // Used to reset tracking daily

  ParentalState({
    required this.dailyTimeLimitMinutes,
    required this.maxBrightness,
    required this.maxVolume,
    required this.allowedSnoozes,
    required this.usedSnoozes,
    required this.consumedTimeSeconds,
    required this.lastActiveDate,
  });

  ParentalState copyWith({
    int? dailyTimeLimitMinutes,
    double? maxBrightness,
    double? maxVolume,
    int? allowedSnoozes,
    int? usedSnoozes,
    int? consumedTimeSeconds,
    String? lastActiveDate,
  }) {
    return ParentalState(
      dailyTimeLimitMinutes: dailyTimeLimitMinutes ?? this.dailyTimeLimitMinutes,
      maxBrightness: maxBrightness ?? this.maxBrightness,
      maxVolume: maxVolume ?? this.maxVolume,
      allowedSnoozes: allowedSnoozes ?? this.allowedSnoozes,
      usedSnoozes: usedSnoozes ?? this.usedSnoozes,
      consumedTimeSeconds: consumedTimeSeconds ?? this.consumedTimeSeconds,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }
}

class ParentalNotifier extends StateNotifier<ParentalState> {
  final SharedPreferences prefs;

  ParentalNotifier(this.prefs) : super(_loadInitialState(prefs));

  static ParentalState _loadInitialState(SharedPreferences prefs) {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String savedDate = prefs.getString('parental_lastActiveDate') ?? today;

    int consumed = prefs.getInt('parental_consumedTimeSeconds') ?? 0;
    int used = prefs.getInt('parental_usedSnoozes') ?? 0;

    // Reset daily counters if it's a new day
    if (savedDate != today) {
      consumed = 0;
      used = 0;
      prefs.setString('parental_lastActiveDate', today);
      prefs.setInt('parental_consumedTimeSeconds', 0);
      prefs.setInt('parental_usedSnoozes', 0);
    }

    return ParentalState(
      dailyTimeLimitMinutes: prefs.getInt('parental_dailyTimeLimitMinutes') ?? 0,
      maxBrightness: prefs.getDouble('parental_maxBrightness') ?? 1.0,
      maxVolume: prefs.getDouble('parental_maxVolume') ?? 1.0,
      allowedSnoozes: prefs.getInt('parental_allowedSnoozes') ?? 3,
      usedSnoozes: used,
      consumedTimeSeconds: consumed,
      lastActiveDate: today,
    );
  }

  void updateSettings({
    int? dailyTimeLimitMinutes,
    double? maxBrightness,
    double? maxVolume,
    int? allowedSnoozes,
  }) {
    if (dailyTimeLimitMinutes != null) {
      prefs.setInt('parental_dailyTimeLimitMinutes', dailyTimeLimitMinutes);
    }
    if (maxBrightness != null) {
      prefs.setDouble('parental_maxBrightness', maxBrightness);
    }
    if (maxVolume != null) {
      prefs.setDouble('parental_maxVolume', maxVolume);
    }
    if (allowedSnoozes != null) {
      prefs.setInt('parental_allowedSnoozes', allowedSnoozes);
    }

    state = state.copyWith(
      dailyTimeLimitMinutes: dailyTimeLimitMinutes,
      maxBrightness: maxBrightness,
      maxVolume: maxVolume,
      allowedSnoozes: allowedSnoozes,
    );
  }

  void incrementConsumedTime(int secondsToAdd) {
    final newTime = state.consumedTimeSeconds + secondsToAdd;
    prefs.setInt('parental_consumedTimeSeconds', newTime);
    state = state.copyWith(consumedTimeSeconds: newTime);
  }

  bool useSnooze(int snoozeMinutes) {
    if (state.usedSnoozes < state.allowedSnoozes) {
      final newUsed = state.usedSnoozes + 1;
      // Deduct time so they get 'snoozeMinutes' extra play time before hitting the limit again
      final deductedTime = state.consumedTimeSeconds - (snoozeMinutes * 60);
      final newTime = deductedTime < 0 ? 0 : deductedTime;

      prefs.setInt('parental_usedSnoozes', newUsed);
      prefs.setInt('parental_consumedTimeSeconds', newTime);

      state = state.copyWith(
        usedSnoozes: newUsed,
        consumedTimeSeconds: newTime,
      );
      return true;
    }
    return false;
  }
}

final parentalProvider = StateNotifierProvider<ParentalNotifier, ParentalState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ParentalNotifier(prefs);
});
