import 'package:chesslinkdriver/ChessLinkCommunicationClient.dart';
import 'package:chesslinkdriver/ChessLinkMessage.dart';
import 'package:chesslinkdriver/protocol/Answer.dart';
import 'package:chesslinkdriver/protocol/model/RequestConfig.dart';

abstract class Command<T> {
  String code;
  Answer<T> answer;

  Future<String> messageBuilder() async {
    return code;
  }

  Future<void> send(ChessLinkCommunicationClient client) async {
    String messageString = await messageBuilder();
    String checksum = ChessLinkMessage.numToHex(ChessLinkMessage.genChecksumNum(messageString));
    List<int> message = [...messageString.split(''), checksum[0], checksum[1]]
      .map((c) => ChessLinkMessage.setOddParityBit(c.codeUnits.first))
      .toList();
    // print("S > " + message.map((n) => String.fromCharCode(n & 127)).toString());
    await client.send(message);
  }

  Future<T> request(
    ChessLinkCommunicationClient client,
    Stream<ChessLinkMessage> inputStream,
    [RequestConfig config = const RequestConfig()]
  ) async {
    Future<T> result = getReponse(inputStream);
    try {
      await send(client);
      T resultValue = await result.timeout(config.timeout);
      return resultValue;
    } catch (e) {
      if (config.retries <= 0) {
        throw e;
      }
      await Future.delayed(config.retryDelay);
      return request(client, inputStream, config.withDecreasedRetry());
    }
  }

  Future<T> getReponse(Stream<ChessLinkMessage> inputStream) async {
    if (answer == null) return null;
    ChessLinkMessage message = await inputStream
        .firstWhere((ChessLinkMessage msg) => msg.checkCode(answer.code));
    return answer.process(message.getMessage());
  }
}