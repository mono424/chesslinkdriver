import 'package:chesslinkdriver/protocol/Answer.dart';
import 'package:chesslinkdriver/protocol/Command.dart';
import 'package:chesslinkdriver/protocol/model/EONESettings.dart';

class GetEONESettings extends Command<EONESettings> {
  final String code = "R06";
  final Answer<EONESettings> answer = GetEONESettingsAnswer();

  GetEONESettings();

  Future<String> messageBuilder() async {
    return code;
  }
}

class GetEONESettingsAnswer extends Answer<EONESettings> {
  final String code = "r06";

  @override
  EONESettings process(String msg) {
    return EONESettings.parseHex(msg.substring(1));
  }
}