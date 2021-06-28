abstract class Answer<T> {
  String code;
  T process(List<String> msg);
}