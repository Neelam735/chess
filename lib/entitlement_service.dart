import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'billing_service.dart';

/// Combines premium ownership with non-purchase entitlements like the
/// free daily-puzzle quota. Persists counters across launches.
class EntitlementService {
  EntitlementService._();
  static final EntitlementService instance = EntitlementService._();

  static const int freeDailyPuzzleLimit = 3;
  static const String _kPuzzlesSolvedDate = 'puzzles_solved_date';
  static const String _kPuzzlesSolvedCount = 'puzzles_solved_count';

  final ValueNotifier<int> puzzlesSolvedToday = ValueNotifier<int>(0);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    if (prefs.getString(_kPuzzlesSolvedDate) != today) {
      await prefs.setString(_kPuzzlesSolvedDate, today);
      await prefs.setInt(_kPuzzlesSolvedCount, 0);
    }
    puzzlesSolvedToday.value = prefs.getInt(_kPuzzlesSolvedCount) ?? 0;
  }

  bool get isPremium => BillingService.instance.isPremium.value;

  /// Whether the user can open the next puzzle right now.
  bool get canSolveAnotherPuzzle =>
      isPremium || puzzlesSolvedToday.value < freeDailyPuzzleLimit;

  /// How many free puzzles remain today (always [freeDailyPuzzleLimit] for premium).
  int get remainingFreePuzzles => isPremium
      ? freeDailyPuzzleLimit
      : (freeDailyPuzzleLimit - puzzlesSolvedToday.value).clamp(0, freeDailyPuzzleLimit);

  Future<void> recordPuzzleSolved() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDate = prefs.getString(_kPuzzlesSolvedDate);
    final current = storedDate == today ? (prefs.getInt(_kPuzzlesSolvedCount) ?? 0) : 0;
    final next = current + 1;
    await prefs.setString(_kPuzzlesSolvedDate, today);
    await prefs.setInt(_kPuzzlesSolvedCount, next);
    puzzlesSolvedToday.value = next;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
