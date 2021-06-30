import 'package:millenniumdriver/protocol/Answer.dart';
import 'package:millenniumdriver/protocol/Command.dart';

class GetVersion extends Command<String> {
  final String code = "V";
  final Answer<String> answer = GetVersionAnswer();
}

class GetVersionAnswer extends Answer<String> {
  final String code = "v";

  @override
  String process(String msg) {
    String versionHighHex = msg.substring(1, 3);
    String versionLowHex = msg.substring(3, 5);
    return int.parse(versionHighHex, radix: 16).toString() + "." + int.parse(versionLowHex, radix: 16).toString();
  }
}