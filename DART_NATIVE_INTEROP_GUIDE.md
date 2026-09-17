# Modern Pure Dart Native Interop & Native Assets Guide

This guide explains how to do **pure, modern native interop** in Dart using the latest features available in Dart 3 (Dart 3.10+ and 3.13+):
1. **Package Hooks (`hook/build.dart` & `hook/link.dart`)**
2. **Native Assets / Code Assets (`package:hooks`, `package:code_assets`, `package:native_toolchain_c`)**
3. **Pure FFI Interop via `@Native` annotations (`dart:ffi`)**

---

## What Has Changed? (Legacy FFI vs. Modern Native Assets)

### Legacy FFI Approach (Old Way)
Historically, performing FFI in Dart required manually managing dynamic libraries:
- Manual compilation of C/C++/Rust libraries using external Makefiles or CMake scripts.
- Copying binary artifacts (`.so`, `.dylib`, `.dll`) manually into platform-specific asset folders.
- Writing boilerplate code with `DynamicLibrary.open(...)` or `DynamicLibrary.process()`.
- Complex, platform-conditional path resolution logic at runtime.

### Modern Pure Native Interop (New Way)
With the modern **Hooks & Native Assets system**:
- **Zero dynamic library path boilerplate**: The Dart SDK automatically compiles, links, bundles, and loads native libraries.
- **Pure `@Native` annotations**: No `DynamicLibrary.open()`. Annotate external Dart functions with `@Native`, and Dart connects them directly to native symbols.
- **Hermetic build hooks**: `hook/build.dart` builds or downloads native libraries seamlessly when running `dart run`, `dart test`, or `dart build`.
- **Automatic Tree-Shaking**: `hook/link.dart` uses `recordedUses` to tree-shake unused C/native code symbols during app bundling.

---

## Core Components

### 1. The `@Native` Annotation (`dart:ffi`)
In modern Dart interop, native functions are declared as top-level `external` functions annotated with `@Native`:

```dart
import 'dart:ffi';

@Native<Int32 Function(Int32, Int32)>()
external int add_numbers(int a, int b);
```

By default, the `@Native` annotation uses the Dart library's URI as its `assetId` (e.g. `package:native_example/native_example.dart`). When the build hook generates a code asset matching this URI, Dart links them automatically.

### 2. The Build Hook (`hook/build.dart`)
Placed inside the `hook/` directory of your package, `hook/build.dart` is automatically executed by `dart pub / dart run / dart test`.

Example `hook/build.dart`:
```dart
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    final cLibrary = CLibrary(
      name: packageName,
      assetName: '$packageName.dart', // Maps to package:<packageName>/<packageName>.dart
      sources: ['src/native_example.c'],
    );
    await cLibrary.build(
      input: input,
      output: output,
    );
  });
}
```

### 3. Tree-Shaking via Link Hooks (`hook/link.dart`)
For applications bundling native dependencies, link hooks allow tree-shaking unused native symbols:

```dart
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await link(args, (input, output) async {
    final packageName = input.packageName;
    final cLibrary = CLibrary(
      name: packageName,
      assetName: '$packageName.dart',
      sources: ['src/native_example.c'],
    );

    final linkerOptions = LinkerOptions.treeshake(
      symbolsToKeep: input.recordedUses?.calls.keys
          .cast<Method>()
          .map((e) => e.name),
    );

    await cLibrary.link(
      input: input,
      output: output,
      linkerOptions: linkerOptions,
    );
  });
}
```

---

## Step-by-Step Tutorial: Building a Pure Native Dart Package

### Step 1: `pubspec.yaml` Setup
Add `hooks`, `code_assets`, and `native_toolchain_c` under `dependencies`:

```yaml
name: native_example
description: Pure Dart native interop example using modern Hooks and Native Assets.
version: 1.0.0

environment:
  sdk: '^3.10.0'

dependencies:
  code_assets: ^2.1.0
  hooks: ^2.2.0
  native_toolchain_c: ^0.19.5

dev_dependencies:
  ffigen: ^22.0.0
  test: ^1.32.0
```

### Step 2: Write Native Code (`src/native_example.c`)
Create C source code under `src/`:

```c
#include <stdint.h>

int32_t add_numbers(int32_t a, int32_t b) {
    return a + b;
}

int32_t multiply_numbers(int32_t a, int32_t b) {
    return a * b;
}
```

### Step 3: Implement Build Hook (`hook/build.dart`)
Create `hook/build.dart` to trigger C compilation during build time:

```dart
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
```

### Step 4: Define `@Native` Bindings (`lib/native_example.dart`)
Define external Dart bindings matching C symbol signatures:

```dart
import 'dart:ffi';

@Native<Int32 Function(Int32, Int32)>()
external int add_numbers(int a, int b);

@Native<Int32 Function(Int32, Int32)>()
external int multiply_numbers(int a, int b);
```

### Step 5: Run Example & Tests

#### Running Example
```bash
dart run example/native_example_example.dart
```
Output:
```text
Running build hooks...
2 + 3 = 5
4 * 5 = 20
```

#### Running Tests
```bash
dart test
```
Output:
```text
Running build hooks...
00:00 +2: All tests passed!
```

---

## Summary of Best Practices
1. **Always use `@Native` annotations** instead of `DynamicLibrary.open()` for pure interop.
2. **Name asset identifiers after library URIs** (e.g. `assetName: '$packageName.dart'`) so Dart implicitly binds `@Native` calls without hardcoding asset ID strings.
3. **Use `package:hooks` and `package:native_toolchain_c`** in `hook/build.dart` for cross-platform C/C++ builds.
4. **Utilize User Defines** (`hooks.user_defines` in `pubspec.yaml`) if custom paths or build flags need to be configured by the end application consumer.
