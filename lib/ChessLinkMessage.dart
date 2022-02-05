class ChessLinkMessage {
  String _code;
  int _length;
  String _message;

  ChessLinkMessage.parse(List<int> buffer) {
    int firstParityFail = buffer.indexWhere(((b) => !checkOddParityBit(b)));
    if (firstParityFail != -1)
      throw ChessLinkInvalidMessageException(firstParityFail + 1);

    List<String> asciiChars = buffer.map((n) => String.fromCharCode(n & 127)).toList();

    int nextChecksum = nextChecksumIndex(asciiChars);

    if (nextChecksum == null) {
      throw ChessLinkUncompleteMessage();
    }

    List<String> message = asciiChars.sublist(0, nextChecksum + 2);
    String messageString = message.join("");

    if (checkChecksum(messageString)) {
      _code = message[0];
      _length = message.length;
      _message = messageString;
      return;
    } else {
      throw ChessLinkInvalidMessageException(nextChecksum + 2);
    }
  }

  bool checkCode(String code) {
    return (_message.length >= code.length && _message.substring(0, code.length) == code);
  }

  static int genChecksumNum(String message) {
    int res = 0;
    for (var i = 0; i < message.length; i++) {
      res = res ^ (message[i].codeUnits.first & 127);
    }
    return res;
  }

  static int setOddParityBit(int byte) {
    int odd = 1;

    for (var i = 0; i < 7; i++) {
      int bit = (byte >> i) & 1;
      odd = bit ^ odd;
    }

    return odd == 1 ? (byte | 128) : (byte & 127);
  }

  static bool checkOddParityBit(int byte) {
    int pBit = byte >> 7;
    int odd = 1;

    for (var i = 0; i < 7; i++) {
      int bit = (byte >> i) & 1;
      odd = bit ^ odd;
    }

    return odd == pBit;
  }

  static bool checkChecksum(String message) {
    String checksumHex = message.substring(message.length - 2, message.length);
    int checksum = genChecksumNum(message.substring(0, message.length - 2));
    int checksumSum = int.parse(checksumHex, radix: 16);

    return checksum == checksumSum;
  }

  static String numToHex(int num) {
    return num.toRadixString(16).padLeft(2, "0").toUpperCase();
  }

  int nextChecksumIndex(List<String> chars, { int start = 0 }) {
    bool foundOneNum = false;
    for (var i = start; i < chars.length; i++) {
      int num = int.tryParse(chars[i], radix: 16);
      bool isNum = num != null;
      if (isNum && foundOneNum) return i - 1;
      if (isNum && num <= 7) foundOneNum = true;
      else foundOneNum = false;
    }
    return null;
  }

  String getCode() {
    return _code;
  }

  int getLength() {
    return _length;
  }

  String getMessage() {
    return _message;
  }
}

class ChessLinkUncompleteMessage implements Exception {}
class ChessLinkInvalidMessageException implements Exception {
  final int skipBytes;

  ChessLinkInvalidMessageException(this.skipBytes);
}
