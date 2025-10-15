import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _lastReadIndexKey = 'lastReadIndex';

  Future<void> saveLastReadIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadIndexKey, index);
  }

  Future<int?> getLastReadIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastReadIndexKey);
  }
}
