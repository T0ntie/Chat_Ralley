import 'package:storytrail/gui/game_screen.dart';

abstract class UIIntent {
  Future<void> call(GameScreenState state);
}

void dispatchUIIntent(UIIntent intent) {
  UiIntentQueue().enqueue(intent);
}

class UiIntentQueue {

  static final UiIntentQueue _instance = UiIntentQueue._internal();

  final List<UIIntent> _queue = [];

  factory UiIntentQueue() => _instance;
  UiIntentQueue._internal();

  void enqueue(UIIntent intent) {
    print("📥 UIIntent queued: ${intent.runtimeType}");
    _queue.add(intent);
  }

  Future<void> flush(GameScreenState state) async {
    if (_queue.isEmpty) return;

    final toExecute = List<UIIntent>.from(_queue);
    _queue.clear();

    for (final intent in toExecute) {
      await intent.call(state);
    }
    print("🚀 Flushed ${toExecute.length} UIIntents");
  }

  bool get hasPending => _queue.isNotEmpty;
}
