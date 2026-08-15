class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  void emit(String event, [dynamic data]) {
    print('📢 Event: $event ${data != null ? '- $data' : ''}');
  }
}
