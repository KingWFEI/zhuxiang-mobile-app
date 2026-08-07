import 'dart:convert';

import 'sse_event.dart';

class SseParser {
  const SseParser._();

  static Stream<SseEvent> parse(Stream<List<int>> bytes) async* {
    final lines = bytes.transform(utf8.decoder).transform(const LineSplitter());
    String? id;
    String? event;
    Duration? retry;
    final dataLines = <String>[];
    var firstLine = true;

    SseEvent? buildEvent() {
      if (id == null && event == null && retry == null && dataLines.isEmpty) {
        return null;
      }
      final parsed = SseEvent(
        id: id,
        event: event,
        data: dataLines.join('\n'),
        retry: retry,
      );
      id = null;
      event = null;
      retry = null;
      dataLines.clear();
      return parsed;
    }

    await for (var line in lines) {
      if (firstLine) {
        firstLine = false;
        if (line.startsWith('\uFEFF')) line = line.substring(1);
      }
      if (line.isEmpty) {
        final parsed = buildEvent();
        if (parsed != null) yield parsed;
        continue;
      }
      if (line.startsWith(':')) continue;

      final separator = line.indexOf(':');
      final field = separator < 0 ? line : line.substring(0, separator);
      var value = separator < 0 ? '' : line.substring(separator + 1);
      if (value.startsWith(' ')) value = value.substring(1);

      switch (field) {
        case 'id':
          if (!value.contains('\u0000')) id = value;
        case 'event':
          event = value;
        case 'data':
          dataLines.add(value);
        case 'retry':
          final milliseconds = int.tryParse(value);
          if (milliseconds != null && milliseconds >= 0) {
            retry = Duration(milliseconds: milliseconds);
          }
      }
    }

    final parsed = buildEvent();
    if (parsed != null) yield parsed;
  }
}
