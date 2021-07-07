import 'package:millenniumdriver/MillenniumMessage.dart';
import 'package:millenniumdriver/protocol/Answer.dart';
import 'package:millenniumdriver/protocol/Command.dart';
import 'package:millenniumdriver/protocol/model/StatusReportSendInterval.dart';

class SetAutomaticReports extends Command<void> {
  final String code = "W02";
  final Answer<void> answer = SetAutomaticReportsAck();
  
  StatusReportSendInterval interval;

  SetAutomaticReports(this.interval);

  Future<String> messageBuilder() async {
    return code + MillenniumMessage.numToHex(interval.index);
  }
}

class SetAutomaticReportsAck extends Answer<void> {
  final String code = "w02";

  @override
  void process(String msg) {}
}