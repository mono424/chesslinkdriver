import 'package:millenniumdriver/MillenniumMessage.dart';
import 'package:millenniumdriver/protocol/Answer.dart';
import 'package:millenniumdriver/protocol/Command.dart';

class SetAutomaticReportsTime extends Command<void> {
  final String code = "W03";
  final Answer<void> answer = SetAutomaticReportsTimeAck();
  
  Duration time;

  SetAutomaticReportsTime(this.time);

  Future<String> messageBuilder() async {
    int mul = time.inMilliseconds ~/ 4.096;
    if (mul > 255) mul = 255;
    return code + MillenniumMessage.numToHex(mul);
  }
}

class SetAutomaticReportsTimeAck extends Answer<void> {
  final String code = "w03";

  @override
  void process(String msg) {}
}