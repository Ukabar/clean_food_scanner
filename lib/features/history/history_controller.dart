import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';
import '../../data/models/scan_history_item.dart';

class HistoryController extends Notifier<List<ScanHistoryItem>> {
  final _storage = LocalStorage.instance;

  @override
  List<ScanHistoryItem> build() => _storage.getHistory();

  Future<void> remove(String barcode) async {
    state = state.where((item) => item.barcode != barcode).toList();
    await _storage.saveHistory(state);
  }

  Future<void> clear() async {
    state = const [];
    await _storage.clearHistory();
  }

  void refresh() {
    state = _storage.getHistory();
  }
}

final historyControllerProvider =
    NotifierProvider<HistoryController, List<ScanHistoryItem>>(
      HistoryController.new,
    );
