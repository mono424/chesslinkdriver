import 'package:millenniumdriver/protocol/Answer.dart';
import 'package:millenniumdriver/protocol/Command.dart';

class Reset extends Command<String> {
  final String code = "T";
  final Answer<String> answer = null;
}