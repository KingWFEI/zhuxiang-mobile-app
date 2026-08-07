class SseEvent {
  const SseEvent({this.id, this.event, this.data = '', this.retry});

  final String? id;
  final String? event;
  final String data;
  final Duration? retry;
}
