import 'package:millenniumdriver/MillenniumMessage.dart';
import 'package:millenniumdriver/protocol/Answer.dart';
import 'package:millenniumdriver/protocol/Command.dart';

class SetLedBrightness extends Command<void> {
  final String code = "W04";
  final Answer<void> answer = SetLedBrightnessAck();
  
  double level;

  // between 1 and 0
  SetLedBrightness(this.level);

  Future<String> messageBuilder() async {
    return code + MillenniumMessage.numToHex((level * 15).round());
  }
}

class SetLedBrightnessAck extends Answer<void> {
  final String code = "w04";

  @override
  void process(String msg) {}
}