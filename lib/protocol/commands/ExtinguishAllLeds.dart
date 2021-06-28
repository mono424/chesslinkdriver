import 'package:millenniumdriver/protocol/Answer.dart';
import 'package:millenniumdriver/protocol/Command.dart';

class ExtinguishAllLeds extends Command<void> {
  final String code = "X";
  final Answer<void> answer = ExtinguishAllLedsAck();
}

class ExtinguishAllLedsAck extends Answer<void> {
  final String code = "x";

  @override
  void process(List<String> msg) {}
}