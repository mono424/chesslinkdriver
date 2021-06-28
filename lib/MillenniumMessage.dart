class MillenniumMessage {
  String _code;
  int _length;
  List<String> _message;

  MillenniumMessage.parse(List<int> buffer) {
    int firstParityFail = buffer.firstWhere(((b) => !checkOddParityBit(b)), orElse: () => null);
    if (firstParityFail != null) throw MillenniumInvalidMessageException(firstParityFail + 1);

    List<String> asciiChars = buffer.map((n) => String.fromCharCode(n & 127)).toList();
    int nextChecksum = nextChecksumIndex(asciiChars);

    if (nextChecksum == null) throw MillenniumUncompleteMessage();

    List<String> message = asciiChars.sublist(0, nextChecksum + 2);
    if (!checkChecksum(message)) throw MillenniumInvalidMessageException(message.length);

    _code = message[0];
    _length = message.length;
    _message = message;
  }

  static int genChecksumNum(List<String> message) {
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

  bool checkChecksum(List<String> message) {
    String checksumHex = message.sublist(message.length - 2, message.length).join("");
    int checksum = genChecksumNum(message.sublist(0, message.length - 2));
    int checksumSum = int.parse(checksumHex, radix: 16);

    return checksum == checksumSum;
  }

  int nextChecksumIndex(List<String> chars) {
    bool foundOneNum = false;
    for (var i = 0; i < chars.length; i++) {
      bool isNum = int.tryParse(chars[i]) != null;
      if (isNum && foundOneNum) return i - 1;
      if (isNum) foundOneNum = true;
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

  List<String> getMessage() {
    return _message;
  }
}

class MillenniumUncompleteMessage implements Exception {}
class MillenniumInvalidMessageException implements Exception {
  final int skipBytes;

  MillenniumInvalidMessageException(this.skipBytes);
}
