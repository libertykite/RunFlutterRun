import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/user_repository_impl.dart';
import '../../../main.dart';
import 'settings_state.dart';

final settingsViewModelProvider =
    StateNotifierProvider.autoDispose<SettingsViewModel, SettingsState>(
  (ref) => SettingsViewModel(ref),
);

class SettingsViewModel extends StateNotifier<SettingsState> {
  Ref ref;

  SettingsViewModel(this.ref) : super(SettingsState.initial());

  void logoutUser() async {
    try {
      await ref.read(userRepositoryProvider).logout();
      navigatorKey.currentState?.pushReplacementNamed("/login");
    } catch (error) {}
  }

  void deleteUserAccount() async {
    try {
      await ref.read(userRepositoryProvider).delete();
      await clearStorage();
      navigatorKey.currentState?.pushReplacementNamed("/login");
    } catch (error) {}
  }

  Future<void> clearStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}