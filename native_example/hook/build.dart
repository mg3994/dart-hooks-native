import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    final cLibrary = CLibrary(
      name: packageName,
      assetName: '$packageName.dart',
      sources: ['src/native_example.c'],
    );
    await cLibrary.build(
      input: input,
      output: output,
    );
  });
}
