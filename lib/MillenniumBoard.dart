import 'dart:async';
import 'package:millenniumdriver/MillenniumCommunicationClient.dart';
import 'package:millenniumdriver/MillenniumMessage.dart';
import 'package:millenniumdriver/protocol/commands/ExtinguishAllLeds.dart';
import 'package:millenniumdriver/protocol/commands/GetStatus.dart';
import 'package:millenniumdriver/protocol/commands/GetVersion.dart';
import 'package:millenniumdriver/protocol/commands/Reset.dart';
import 'package:millenniumdriver/protocol/commands/SetLeds.dart';

class MillenniumBoard {
  
  MillenniumCommunicationClient _client;

  StreamController _inputStreamController;
  Stream<MillenniumMessage> _inputStream;
  List<int> _buffer;

  static const List<String> SQUARES = [
    "a8",
    "b8",
    "c8",
    "d8",
    "e8",
    "f8",
    "g8",
    "h8",
    "a7",
    "b7",
    "c7",
    "d7",
    "e7",
    "f7",
    "g7",
    "h7",
    "a6",
    "b6",
    "c6",
    "d6",
    "e6",
    "f6",
    "g6",
    "h6",
    "a5",
    "b5",
    "c5",
    "d5",
    "e5",
    "f5",
    "g5",
    "h5",
    "a4",
    "b4",
    "c4",
    "d4",
    "e4",
    "f4",
    "g4",
    "h4",
    "a3",
    "b3",
    "c3",
    "d3",
    "e3",
    "f3",
    "g3",
    "h3",
    "a2",
    "b2",
    "c2",
    "d2",
    "e2",
    "f2",
    "g2",
    "h2",
    "a1",
    "b1",
    "c1",
    "d1",
    "e1",
    "f1",
    "g1",
    "h1"
  ];

  MillenniumBoard();

  Future<void> init(MillenniumCommunicationClient client, { Duration initialDelay = const Duration(milliseconds: 300) }) async {
    _client = client;

    _client.receiveStream.listen(_handleInputStream);
    _inputStreamController = new StreamController<MillenniumMessage>();
    _inputStream = _inputStreamController.stream.asBroadcastStream();

    await Future.delayed(initialDelay);
  }


  void _handleInputStream(List<int> chunk) {
    //print("> " + chunk.map((n) => String.fromCharCode(n & 127)).toString());
    if (_buffer == null)
      _buffer = chunk.toList();
    else
      _buffer.addAll(chunk);

    if (_buffer.length > 200) {
      _buffer.removeRange(0, _buffer.length - 200);
    }

    try {
      MillenniumMessage message = MillenniumMessage.parse(_buffer);
      _inputStreamController.add(message);
      _buffer.removeRange(0, message.getLength());
      print("[IMessage] valid (" + message.getCode() + ")");
    } on MillenniumInvalidMessageException catch (e) {
      _buffer = skipBadBytes(e.skipBytes, _buffer);
      print("[IMessage] invalid");
    } on MillenniumUncompleteMessage {
      // wait longer
    } catch (err) {
      //print("Unknown parse-error: " + err.toString());
    }
  }

  Stream<MillenniumMessage> getInputStream() {
    return _inputStream;
  }

  List<int> skipBadBytes(int start, List<int> buffer) {
    int startOfGoodBytes = start;
    for (; startOfGoodBytes < buffer.length; startOfGoodBytes++) {
      if ((buffer[startOfGoodBytes] & 0x80) != 0) break;
    }
    if (startOfGoodBytes == buffer.length) return [];
    return buffer.sublist(startOfGoodBytes, buffer.length - startOfGoodBytes);
  }

  Stream<Map<String, String>> getBoardUpdateStream() {
    return getInputStream()
        .where(
            (MillenniumMessage msg) => msg.getCode() == GetStatusAnswer().code)
        .map((MillenniumMessage msg) => GetStatusAnswer().process(msg.getMessage()));
  }

  Future<void> extinguishAllLeds() {
    return ExtinguishAllLeds().send(_client);
  }

  Future<void> turnOnSingleLed(String square, {Duration slotTime = const Duration(milliseconds: 500)}) {
    List<String> pattern = [];
    for (var i = 0; i < SQUARES.indexOf(square.toLowerCase()); i++) {
      pattern.add("00");
    }
    pattern.add("FF");

    return SetLeds(slotTime, pattern).send(_client);
  }

  Future<void> turnOnAllLeds({Duration slotTime = const Duration(milliseconds: 500)}) {
    List<String> pattern = [];
    for (var i = 0; i < 81; i++) {
      pattern.add("FF");
    }
    return SetLeds(slotTime, pattern).send(_client);
  }

  Future<void> turnOnLeds(List<String> squares, {Duration slotTime = const Duration(milliseconds: 500)}) {
    List<String> pattern = [];

    for (var i = 0; i < SQUARES.length; i++) {
      pattern.add(squares.map((s) => s.toLowerCase()).toList().contains(SQUARES[i]) ? "FF" : "00");
    }

    return SetLeds(slotTime, pattern).send(_client);
  }

  Future<String> getVersion() {
    return GetVersion().request(_client, _inputStream);
  }

  Future<String> reset() {
    return Reset().send(_client);
  }

}
