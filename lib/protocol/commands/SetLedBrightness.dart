import 'package:chesslinkdriver/ChessLinkMessage.dart';
import 'package:chesslinkdriver/protocol/Answer.dart';
import 'package:chesslinkdriver/protocol/Command.dart';

class SetLedBrightness extends Command<void> {
  final String code = "W04";
  final Answer<void> answer = SetLedBrightnessAck();
  
  double level;

  // between 1 and 0
  SetLedBrightness(this.level);

  Future<String> messageBuilder() async {
    return code + ChessLinkMessage.numToHex((level * 14).round());
  }
}

class SetLedBrightnessAck extends Answer<void> {
  final String code = "w04";

  @override
  void process(String msg) {}
}