import 'package:chesslinkdriver/ChessLinkMessage.dart';
import 'package:chesslinkdriver/protocol/Answer.dart';
import 'package:chesslinkdriver/protocol/Command.dart';
import 'package:chesslinkdriver/protocol/model/StatusReportSendInterval.dart';

class SetAutomaticReports extends Command<void> {
  final String code = "W02";
  final Answer<void> answer = SetAutomaticReportsAck();
  
  StatusReportSendInterval interval;

  SetAutomaticReports(this.interval);

  Future<String> messageBuilder() async {
    return code + ChessLinkMessage.numToHex(interval.index);
  }
}

class SetAutomaticReportsAck extends Answer<void> {
  final String code = "w02";

  @override
  void process(String msg) {}
}