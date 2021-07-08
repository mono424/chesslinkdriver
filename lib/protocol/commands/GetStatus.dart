import 'package:chesslinkdriver/ChessLink.dart';
import 'package:chesslinkdriver/protocol/Answer.dart';
import 'package:chesslinkdriver/protocol/Command.dart';

class GetStatus extends Command<Map<String,String>> {
  final String code = "S";
  final Answer<Map<String,String>> answer = GetStatusAnswer();
}

class GetStatusAnswer extends Answer<Map<String,String>> {
  final String code = "s";

  @override
  Map<String,String> process(String msg) {
    Map<String,String> board = Map<String,String>();
    for (var i = 0; i < ChessLink.SQUARES.length; i++) {
      String piece = msg[i + 1];
      board[ChessLink.SQUARES[i]] = piece == "." ? null : piece;
    }
    return board;
  }
}