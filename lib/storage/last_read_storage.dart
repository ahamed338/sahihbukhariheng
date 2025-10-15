import 'package:shared_preferences/shared_preferences.dart';

class LastReadStorage {
  static const String key = 'last_read_index';

  Future<void> saveLastReadIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, index);
  }

  Future<int> getLastReadIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? -1;
  }
}
