import 'package:native_example/native_example.dart';
import 'package:test/test.dart';

void main() {
  test('add_numbers works via native hook asset', () {
    expect(add_numbers(10, 20), equals(30));
  });

  test('multiply_numbers works via native hook asset', () {
    expect(multiply_numbers(6, 7), equals(42));
  });
}
