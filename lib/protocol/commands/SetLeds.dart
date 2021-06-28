import 'package:millenniumdriver/protocol/Answer.dart';
import 'package:millenniumdriver/protocol/Command.dart';

class SetLeds extends Command<void> {
  final String code = "L";
  final Answer<void> answer = SetLedsAck();
  
  final List<String> pattern;

  // two-char hex per led
  SetLeds(this.pattern);

  Future<List<String>> messageBuilder() async {
    List<String> result = [];
    for (var i = 0; i < 81; i++) {
      result.add(pattern.length > i ? pattern[i] : "00");
    }
    return result;
  }
}

class SetLedsAck extends Answer<void> {
  final String code = "l";

  @override
  void process(List<String> msg) {}
}