class RequestConfig {
  final int retries;
  final Duration timeout;
  final Duration retryDelay;

  const RequestConfig([
    this.retries = 3,
    this.timeout = const Duration(seconds: 200),
      this.retryDelay = const Duration(seconds: 200)
  ]);

  RequestConfig withDecreasedRetry() {
    return RequestConfig(
      retries - 1,
      timeout,
      retryDelay
    );
  }
}