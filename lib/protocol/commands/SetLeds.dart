import 'package:millenniumdriver/protocol/Answer.dart';
import 'package:millenniumdriver/protocol/Command.dart';

class SetLeds extends Command<void> {
  final String code = "L";
  final Answer<void> answer = SetLedsAck();
  
  final Duration slotTime;
  final List<String> pattern;

  // two-hex chart slot-time in 4.096ms steps, two-char hex per led in pattern
  SetLeds(this.slotTime, this.pattern);

  String slotTimeHex() {
    int mul = slotTime.inMilliseconds ~/ 4.096;
    return mul.toRadixString(16).padLeft(2, "0").toUpperCase();
  }

  Future<List<String>> messageBuilder() async {
    List<String> result = [];
    result.add(slotTimeHex());
    for (var i = 0; i < 81; i++) {
      result.add(pattern.length > i ? pattern[i].toUpperCase() : "00");
    }
    return result;
  }
}

class SetLedsAck extends Answer<void> {
  final String code = "l";

  @override
  void process(List<String> msg) {}
}