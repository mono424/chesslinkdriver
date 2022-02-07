import 'package:chesslinkdriver/protocol/Answer.dart';
import 'package:chesslinkdriver/protocol/Command.dart';
import 'package:chesslinkdriver/protocol/model/EONESettings.dart';

class SetEONESettings extends Command<void> {
  final String code = "W06";
  final Answer<void> answer = SetEONESettingsAck();
  
  EONESettings settings;

  SetEONESettings(this.settings);

  Future<String> messageBuilder() async {
    return code + settings.toString();
  }
}

class SetEONESettingsAck extends Answer<void> {
  final String code = "w06";

  @override
  void process(String msg) {}
}