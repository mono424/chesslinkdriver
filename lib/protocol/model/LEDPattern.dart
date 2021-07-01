import 'package:millenniumdriver/MillenniumBoard.dart';
import 'package:millenniumdriver/MillenniumMessage.dart';

class LEDPattern {

  String pattern;

  LEDPattern() {
    pattern = initializeNewPattern();
  }

  void set(String square, String squarePattern) {
    pattern = _setSquareInFullPattern(pattern, square, squarePattern);
  }

  void setRank(int rank, String squarePattern) {
    for (var file in MillenniumBoard.RANKS) {
      pattern = _setSquareInFullPattern(pattern, file + rank.toString(), squarePattern);
    }
  }

  void setFile(String file, String squarePattern) {
    for (var rank in MillenniumBoard.ROWS) {
      pattern = _setSquareInFullPattern(pattern, file + rank, squarePattern);
    }
  }

  LEDPattern.singleSquare(String square, { String hex = "FF" }) {
    pattern = _setSquareInFullPattern(initializeNewPattern(), square, hex);
  }

  LEDPattern.manySquares(List<String> squares, { String hex = "FF" }) {
    pattern = initializeNewPattern();

    for (String square in squares) {
      pattern = _setSquareInFullPattern(pattern, square, hex);
    }
  }

  LEDPattern.allLeds({ String hex = "FF" }) {
    pattern = initializeNewPattern(hex: hex);
  }

  @override
  String toString() {
    return pattern;
  }

  static String generateSquarePattern(bool s8, bool s7, bool s6, bool s5, bool s4, bool s3, bool s2, bool s1) {
    int num = 0;
    if (s1) num ^= 1;
    if (s2) num ^= 2;
    if (s3) num ^= 4;
    if (s4) num ^= 8;
    if (s5) num ^= 16;
    if (s6) num ^= 32;
    if (s7) num ^= 64;
    if (s8) num ^= 128;
    return MillenniumMessage.numToHex(num);
  }

  static String generateSquarePatternN(int s8, int s7, int s6, int s5, int s4, int s3, int s2, int s1) {
    return generateSquarePattern(
      (s1 > 0),
      (s2 > 0),
      (s3 > 0),
      (s4 > 0),
      (s5 > 0),
      (s6 > 0),
      (s7 > 0),
      (s8 > 0),
    );
  }

  static String initializeNewPattern({ String hex = "00" }) {
    String res = "";

    for (var i = 0; i < 81; i++) {
      res += hex;
    }

    return res;
  }

  static String _setSquareInFullPattern(String fullPattern, String square, String squarePattern) {
    for (int ledIndex in getSquareIndices(square)) {
      ledIndex = ledIndex * 2;
      fullPattern = fullPattern.replaceRange(ledIndex, ledIndex+2, squarePattern.toUpperCase());
    }
    return fullPattern;
  }

  // Example: LED1 LED2 LED10 LED11 = A8
  static List<int> getSquareIndices(String square) {
    int rank = MillenniumBoard.RANKS.reversed.toList().indexOf(square.substring(0, 1).toLowerCase());
    int row = MillenniumBoard.ROWS.indexOf(square.substring(1, 2));

    return [
      rank * 9 + row,
      rank * 9 + row + 1,
      (rank + 1) * 9 + row,
      (rank + 1) * 9 + row + 1
    ];
  }
}