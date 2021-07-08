import 'package:chesslinkdriver/ChessLinkMessage.dart';
import 'package:chesslinkdriver/protocol/Answer.dart';
import 'package:chesslinkdriver/protocol/Command.dart';
import 'package:chesslinkdriver/protocol/model/LEDPattern.dart';

class SetLeds extends Command<void> {
  final String code = "L";
  final Answer<void> answer = SetLedsAck();
  
  final Duration slotTime;
  final LEDPattern pattern;

  // two-hex chart slot-time in 4.096ms steps, two-char hex per led in pattern
  SetLeds(this.slotTime, this.pattern);

  String slotTimeHex() {
    int mul = slotTime.inMilliseconds ~/ 4.096;
    return ChessLinkMessage.numToHex(mul);
  }

  Future<String> messageBuilder() async {
    return code + slotTimeHex() + pattern.toString();
  }
}

class SetLedsAck extends Answer<void> {
  final String code = "l";

  @override
  void process(String msg) {}
}