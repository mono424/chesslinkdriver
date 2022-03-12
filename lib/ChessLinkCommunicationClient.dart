import 'dart:async';

class ChessLinkCommunicationClient {
  final Future<void> Function(List<int>) send;
  final StreamController<List<int>> _inputStreamController = StreamController<List<int>>();
  
  Stream<List<int>> _receiveStream;
  Stream<List<int>> get receiveStream {
    if (_receiveStream == null) {
      _receiveStream = _inputStreamController.stream.asBroadcastStream();
    }
    return _receiveStream;
  }

  ChessLinkCommunicationClient(this.send);

  void handleReceive(List<int> message) {
    _inputStreamController.add(message);
  }
}