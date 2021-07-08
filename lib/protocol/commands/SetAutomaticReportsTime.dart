import 'package:chesslinkdriver/ChessLinkMessage.dart';
import 'package:chesslinkdriver/protocol/Answer.dart';
import 'package:chesslinkdriver/protocol/Command.dart';

class SetAutomaticReportsTime extends Command<void> {
  final String code = "W03";
  final Answer<void> answer = SetAutomaticReportsTimeAck();
  
  Duration time;

  SetAutomaticReportsTime(this.time);

  Future<String> messageBuilder() async {
    int mul = time.inMilliseconds ~/ 4.096;
    if (mul > 255) mul = 255;
    return code + ChessLinkMessage.numToHex(mul);
  }
}

class SetAutomaticReportsTimeAck extends Answer<void> {
  final String code = "w03";

  @override
  void process(String msg) {}
}