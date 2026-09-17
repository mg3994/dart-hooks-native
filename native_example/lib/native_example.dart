import 'dart:ffi';

@Native<Int32 Function(Int32, Int32)>()
external int add_numbers(int a, int b);

@Native<Int32 Function(Int32, Int32)>()
external int multiply_numbers(int a, int b);
