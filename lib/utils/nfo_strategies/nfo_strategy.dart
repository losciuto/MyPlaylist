abstract class NfoStrategy {
  Future<Map<String, dynamic>?> parse(String content, String nfoPath);
  bool canParse(String content);
}
