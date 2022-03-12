import 'package:chesslinkdriver/ChessLinkMessage.dart';

class EONESettings {

  final bool boardIsReversed;
  final bool ledsAreShowingErrors;
  final bool boardAutoReverseEnabled;
  final bool errorLedsEnabledOnStartup;
  final bool errorLedsTurnedOffOnLCommand;
  final bool chessRulesEnabled;


  EONESettings(this.boardIsReversed, this.ledsAreShowingErrors, this.boardAutoReverseEnabled, this.errorLedsEnabledOnStartup, this.errorLedsTurnedOffOnLCommand, this.chessRulesEnabled);

  static EONESettings parseHex(String hexData) {
    int num = ChessLinkMessage.hexToNum(hexData);
    final bool boardIsReversed = (num & 1) > 0;
    final bool ledsAreShowingErrors = (num & 2) > 0;
    final bool boardAutoReverseEnabled = (num & 4) > 0;
    final bool errorLedsEnabledOnStartup = (num & 8) > 0;
    final bool errorLedsTurnedOffOnLCommand = (num & 16) > 0;
    final bool chessRulesEnabled = (num & 32) > 0;
    return EONESettings(boardIsReversed, ledsAreShowingErrors, boardAutoReverseEnabled, errorLedsEnabledOnStartup, errorLedsTurnedOffOnLCommand, chessRulesEnabled);
  }

  String toString() {
    int num = 0;
    if (boardIsReversed) num ^= 1;
    if (ledsAreShowingErrors) num ^= 2;
    if (boardAutoReverseEnabled) num ^= 4;
    if (errorLedsEnabledOnStartup) num ^= 8;
    if (errorLedsTurnedOffOnLCommand) num ^= 16;
    if (chessRulesEnabled) num ^= 32;
    return ChessLinkMessage.numToHex(num);
  }
}