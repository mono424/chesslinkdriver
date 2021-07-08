import 'package:chesslinkdriver/protocol/Answer.dart';
import 'package:chesslinkdriver/protocol/Command.dart';

class ExtinguishAllLeds extends Command<void> {
  final String code = "X";
  final Answer<void> answer = ExtinguishAllLedsAck();
}

class ExtinguishAllLedsAck extends Answer<void> {
  final String code = "x";

  @override
  void process(String msg) {}
}