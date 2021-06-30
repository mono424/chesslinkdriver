import 'package:millenniumdriver/MillenniumCommunicationClient.dart';
import 'package:millenniumdriver/MillenniumMessage.dart';
import 'package:millenniumdriver/protocol/Answer.dart';

abstract class Command<T> {
  String code;
  Answer<T> answer;

  Future<String> messageBuilder() async {
    return code;
  }

  Future<void> send(MillenniumCommunicationClient client) async {
    String messageString = await messageBuilder();
    String checksum = MillenniumMessage.numToHex(MillenniumMessage.genChecksumNum(messageString));
    List<int> message = [...messageString.split(''), checksum[0], checksum[1]]
      .map((c) => MillenniumMessage.setOddParityBit(c.codeUnits.first))
      .toList();
    
    await client.send(message);
  }

  Future<T> request(MillenniumCommunicationClient client, Stream<MillenniumMessage> inputStream) async {
    Future<T> result = getReponse(inputStream);
    await send(client);
    return result;
  }

  Future<T> getReponse(Stream<MillenniumMessage> inputStream) async {
    if (answer == null) return null;
    MillenniumMessage message = await inputStream
        .firstWhere((MillenniumMessage msg) => msg.checkCode(answer.code));
    return answer.process(message.getMessage());
  }
}