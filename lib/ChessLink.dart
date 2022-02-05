import 'dart:async';
import 'package:chesslinkdriver/ChessLinkCommunicationClient.dart';
import 'package:chesslinkdriver/ChessLinkMessage.dart';
import 'package:chesslinkdriver/protocol/commands/ExtinguishAllLeds.dart';
import 'package:chesslinkdriver/protocol/commands/GetStatus.dart';
import 'package:chesslinkdriver/protocol/commands/GetVersion.dart';
import 'package:chesslinkdriver/protocol/commands/Reset.dart';
import 'package:chesslinkdriver/protocol/commands/SetAutomaticReports.dart';
import 'package:chesslinkdriver/protocol/commands/SetAutomaticReportsTime.dart';
import 'package:chesslinkdriver/protocol/commands/SetLedBrightness.dart';
import 'package:chesslinkdriver/protocol/commands/SetLeds.dart';
import 'package:chesslinkdriver/protocol/commands/SetScanTime.dart';
import 'package:chesslinkdriver/protocol/model/ChessLinkBoardType.dart';
import 'package:chesslinkdriver/protocol/model/LEDPattern.dart';
import 'package:chesslinkdriver/protocol/model/RequestConfig.dart';
import 'package:chesslinkdriver/protocol/model/StatusReportSendInterval.dart';

class ChessLink {
  
  ChessLinkCommunicationClient _client;

  StreamController _inputStreamController;
  Stream<ChessLinkMessage> _inputStream;
  List<int> _buffer;
  String _version;
  ChessLinkBoardType _boardType = ChessLinkBoardType.unknown;

  static List<String> RANKS = ["a", "b", "c", "d", "e", "f", "g", "h"];
  static List<String> ROWS = ["1", "2", "3", "4", "5", "6", "7", "8"];
  static get SQUARES {
    List<String> squares = [];
    for (var row in ROWS) {
      for (var rank in RANKS.reversed.toList()) {
        squares.add(rank + row);
      }
    }
    return squares;
  }

  String get version => _version;
  ChessLinkBoardType get boardType => _boardType;

  ChessLink();

  Future<void> init(ChessLinkCommunicationClient client, { Duration initialDelay = const Duration(milliseconds: 300) }) async {
    _client = client;

    _client.receiveStream.listen(_handleInputStream);
    _inputStreamController = new StreamController<ChessLinkMessage>();
    _inputStream = _inputStreamController.stream.asBroadcastStream();

    await Future.delayed(initialDelay);

    _version = await getVersion();
    if (_version.startsWith("0.")) {
      _boardType = ChessLinkBoardType.exclusive;
    } else if (_version.startsWith("1.")) {
      _boardType = ChessLinkBoardType.performance;
    } else if (_version.startsWith("2.")) {
      _boardType = ChessLinkBoardType.eONE;
    } else {
      _boardType = ChessLinkBoardType.unknown;
    }
    
  }

  void _handleInputStream(List<int> chunk) {
    // print("R > " + chunk.map((n) => String.fromCharCode(n & 127)).toString());
    if (_buffer == null) {
      _buffer = chunk.toList();
    } else {
      _buffer.addAll(chunk);
    }

    if (_buffer.length > 1000) {
      _buffer.removeRange(0, _buffer.length - 1000);
    }

    do {
      try {
        ChessLinkMessage message = ChessLinkMessage.parse(
          _buffer,
          checkParity: boardType != ChessLinkBoardType.eONE && boardType != ChessLinkBoardType.unknown
        );
        _inputStreamController.add(message);
        _buffer.removeRange(0, message.getLength());
        // print("[IMessage] valid (" + message.getCode() + ")");
      } on ChessLinkInvalidMessageException catch (e) {
        skipBadBytes(e.skipBytes, _buffer);
        // print("[IMessage] invalid");
      } on ChessLinkUncompleteMessage {
        // wait longer
        break;
      } catch (err) {
        // print("Unknown parse-error: " + err.toString());
        break;
      }
    } while (_buffer.length > 0);
  }

  Stream<ChessLinkMessage> getInputStream() {
    return _inputStream;
  }

  void skipBadBytes(int start, List<int> buffer) {
    buffer.removeRange(0, start);
  }

  Stream<Map<String, String>> getBoardUpdateStream() {
    return getInputStream()
        .where(
            (ChessLinkMessage msg) => msg.getCode() == GetStatusAnswer().code)
        .map((ChessLinkMessage msg) => GetStatusAnswer().process(msg.getMessage()));
  }

  Future<void> extinguishAllLeds({ RequestConfig config = const RequestConfig() }) {
    if (_boardType == ChessLinkBoardType.performance) {
      return ExtinguishAllLeds().send(_client);
    }
    return ExtinguishAllLeds().request(_client, _inputStream, config);
  }

  Future<void> turnOnSingleLed(String square, {Duration slotTime = const Duration(milliseconds: 500), RequestConfig config = const RequestConfig()}) {
    if (_boardType == ChessLinkBoardType.performance) {
      return SetLeds(slotTime, LEDPattern.singleSquare(square)).send(_client);
    }
    return SetLeds(slotTime, LEDPattern.singleSquare(square)).request(_client, _inputStream, config);
  }

  Future<void> turnOnAllLeds({Duration slotTime = const Duration(milliseconds: 500), String pattern = "ff", RequestConfig config = const RequestConfig()}) {
    if (_boardType == ChessLinkBoardType.performance) {
      return SetLeds(slotTime, LEDPattern.allLeds(hex: pattern)).send(_client);
    }
    return SetLeds(slotTime, LEDPattern.allLeds(hex: pattern)).request(_client, _inputStream, config);
  }

  Future<void> turnOnLeds(List<String> squares, {Duration slotTime = const Duration(milliseconds: 500), RequestConfig config = const RequestConfig()}) {
    if (_boardType == ChessLinkBoardType.performance) {
      return SetLeds(slotTime, LEDPattern.manySquares(squares)).send(_client);
    }
    return SetLeds(slotTime, LEDPattern.manySquares(squares)).request(_client, _inputStream, config);
  }

  Future<void> setLeds(LEDPattern ledPattern, {Duration slotTime = const Duration(milliseconds: 500), RequestConfig config = const RequestConfig()}) {
    if (_boardType == ChessLinkBoardType.performance) {
      return SetLeds(slotTime, ledPattern).send(_client);
    }
    return SetLeds(slotTime, ledPattern).request(_client, _inputStream, config);
  }

  Future<void> setAutomaticReports(StatusReportSendInterval interval, {RequestConfig config = const RequestConfig()}) {
    if (_boardType == ChessLinkBoardType.performance) {
      return SetAutomaticReports(interval).send(_client);
    }
    return SetAutomaticReports(interval).request(_client, _inputStream, config);
  }

  Future<void> setAutomaticReportsTime(Duration time, {RequestConfig config = const RequestConfig()}) {
    if (_boardType == ChessLinkBoardType.performance) {
      return SetAutomaticReportsTime(time).send(_client);
    }
    return SetAutomaticReportsTime(time).request(_client, _inputStream, config);
  }

  Future<Map<String, String>> getStatus({ RequestConfig config = const RequestConfig() }) {
    return GetStatus().request(_client, _inputStream);
  }

  Future<void> setScanTime(Duration time, { RequestConfig config = const RequestConfig() }) {
    if (_boardType == ChessLinkBoardType.performance) {
      return SetScanTime(time).send(_client);
    }
    return SetScanTime(time).request(_client, _inputStream);
  }

  Future<String> getVersion({ RequestConfig config = const RequestConfig() }) {
    return GetVersion().request(_client, _inputStream, config);
  }

  Future<void> reset() {
    return Reset().send(_client);
  }

  Future<void> setLedBrightness(double level, { RequestConfig config = const RequestConfig() }) {
    if (_boardType == ChessLinkBoardType.performance) {
      return SetLedBrightness(level).send(_client);
    }
    return SetLedBrightness(level).request(_client, _inputStream, config);
  }

}
