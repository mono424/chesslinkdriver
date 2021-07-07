import 'package:millenniumdriver/MillenniumMessage.dart';
import 'package:millenniumdriver/protocol/Answer.dart';
import 'package:millenniumdriver/protocol/Command.dart';

class SetScanTime extends Command<void> {
  final String code = "W01";
  final Answer<void> answer = SetScanTimeAck();
  
  Duration time;

  SetScanTime(this.time);

  Future<String> messageBuilder() async {
    int mul = time.inMilliseconds ~/ 2.048;
    if (mul > 255) mul = 255;
    else if (mul < 15) mul = 15;
    return code + MillenniumMessage.numToHex(mul);
  }
}

class SetScanTimeAck extends Answer<void> {
  final String code = "w01";

  @override
  void process(String msg) {}
}