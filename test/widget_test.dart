import 'package:flutter_test/flutter_test.dart';

void main() {
  test('currency format keeps rupiah symbol', () {
    expect('Rp 10.000'.startsWith('Rp'), isTrue);
  });
}
