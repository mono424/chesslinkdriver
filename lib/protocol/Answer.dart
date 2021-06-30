abstract class Answer<T> {
  String code;
  T process(String msg);
}