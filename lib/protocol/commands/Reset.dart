import 'package:chesslinkdriver/protocol/Answer.dart';
import 'package:chesslinkdriver/protocol/Command.dart';

class Reset extends Command<String> {
  final String code = "T";
  final Answer<String> answer = null;
}