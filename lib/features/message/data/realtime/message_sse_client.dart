import 'package:dio/dio.dart';

import 'sse_event.dart';
import 'sse_parser.dart';

class MessageSseClient {
  const MessageSseClient(this._dio);

  final Dio _dio;

  Stream<SseEvent> connect(CancelToken cancelToken) async* {
    final response = await _dio.get<ResponseBody>(
      '/messages/stream',
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: Duration.zero,
        headers: const {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ),
    );
    final body = response.data;
    if (body == null) {
      throw const FormatException('实时消息响应为空');
    }
    yield* SseParser.parse(body.stream.cast<List<int>>());
  }
}
