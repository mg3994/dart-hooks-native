# Modern Pure Dart Native Interop, Native Assets & Kotlin/Java Guide

This guide explains how to do **pure, modern native interop** in Dart using the latest ecosystem features:
1. **Native Assets & Package Hooks (`hook/build.dart` & `hook/link.dart`)** for C/C++/Rust.
2. **Pure FFI Interop via `@Native` annotations (`dart:ffi`)**.
3. **Kotlin & Java Interop using `package:jni` and `package:jnigen`**.

---

## Part 1: C / C++ / Native Code Interop (Hooks & `@Native`)

### What Has Changed? (Legacy FFI vs. Modern Native Assets)

#### Legacy FFI Approach (Old Way)
Historically, performing FFI in Dart required manually managing dynamic libraries:
- Manual compilation of C/C++/Rust libraries using external Makefiles or CMake scripts.
- Copying binary artifacts (`.so`, `.dylib`, `.dll`) manually into platform-specific asset folders.
- Writing boilerplate code with `DynamicLibrary.open(...)` or `DynamicLibrary.process()`.
- Complex, platform-conditional path resolution logic at runtime.

#### Modern Pure Native Interop (New Way)
With the modern **Hooks & Native Assets system**:
- **Zero dynamic library path boilerplate**: The Dart SDK automatically compiles, links, bundles, and loads native libraries.
- **Pure `@Native` annotations**: No `DynamicLibrary.open()`. Annotate external Dart functions with `@Native`, and Dart connects them directly to native symbols.
- **Hermetic build hooks**: `hook/build.dart` builds or downloads native libraries seamlessly when running `dart run`, `dart test`, or `dart build`.
- **Automatic Tree-Shaking**: `hook/link.dart` uses `recordedUses` to tree-shake unused C/native code symbols during app bundling.

---

### Core Components for C Interop

#### 1. The `@Native` Annotation (`dart:ffi`)
In modern Dart interop, native functions are declared as top-level `external` functions annotated with `@Native`:

```dart
import 'dart:ffi';

@Native<Int32 Function(Int32, Int32)>()
external int add_numbers(int a, int b);
```

By default, the `@Native` annotation uses the Dart library's URI as its `assetId` (e.g. `package:native_example/native_example.dart`). When the build hook generates a code asset matching this URI, Dart links them automatically.

#### 2. The Build Hook (`hook/build.dart`)
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

---

## Part 2: Kotlin & Java Interop (`package:jni` & `package:jnigen`)

To call **Kotlin** (or Java) directly from Dart desktop, server, mobile, or CLI apps without manually writing JNI C glue code or Flutter Channel boilerplate, Dart provides `package:jni` and `package:jnigen`.

### How Kotlin Interop Works
1. Kotlin source code is compiled to JVM Bytecode (or JAR/class files).
2. `jnigen` reads the compiled Java/Kotlin bytecode or Java sources.
3. `jnigen` automatically generates strongly-typed Dart bindings using `package:jni`.
4. Your Dart code calls Kotlin methods seamlessly as if they were regular Dart classes.

### Kotlin Example Workflow

#### 1. Add Dependencies (`pubspec.yaml`)
```yaml
dependencies:
  jni: ^0.14.0

dev_dependencies:
  jnigen: ^0.14.0
```

#### 2. Write Kotlin Source (`kotlin/dev/dart/KotlinExample.kt`)
```kotlin
package dev.dart

class KotlinExample {
    fun greet(name: String): String {
        return "Hello from Kotlin, $name!"
    }

    companion object {
        @JvmStatic
        fun add(a: Int, b: Int): Int {
            return a + b
        }
    }
}
```

#### 3. Configure `jnigen.yaml`
Create `jnigen.yaml` at the root of your project:
```yaml
output:
  dart:
    path: lib/src/kotlin_bindings.dart
    structure: single_file

# Specify class path to compiled Kotlin JAR or source path to Java files
source_path:
  - 'java/'
# Or class_path for compiled Kotlin jar/classes:
# class_path:
#   - 'build/kotlin/'

classes:
  - 'dev.dart.KotlinExample'
```

#### 4. Generate Dart Bindings
Run `jnigen` to automatically generate the Dart wrappers:
```bash
dart run jnigen --config jnigen.yaml
```

#### 5. Use Kotlin in Dart
```dart
import 'package:jni/jni.dart';
import 'src/kotlin_bindings.dart';

void main() {
  // Call static Kotlin method
  final sum = KotlinExample.add(10, 20);
  print('Sum from Kotlin: $sum');

  // Instantiate Kotlin class
  final instance = KotlinExample();
  final message = instance.greet('Dart Developer'.toJString());
  print(message.toDartString());
}
```

---

## Complete Project Setup Tutorial (C + Kotlin + Native Assets)

### Step 1: `pubspec.yaml`
```yaml
name: native_example
description: Pure Dart native interop example with Native Assets, C, and Kotlin/Java.
version: 1.0.0

environment:
  sdk: '^3.10.0'

dependencies:
  code_assets: ^2.1.0
  hooks: ^2.2.0
  native_toolchain_c: ^0.19.5
  jni: ^0.14.0

dev_dependencies:
  ffigen: ^22.0.0
  jnigen: ^0.14.0
  test: ^1.32.0
```

### Step 2: C Source (`src/native_example.c`)
```c
#include <stdint.h>

int32_t add_numbers(int32_t a, int32_t b) {
    return a + b;
}

int32_t multiply_numbers(int32_t a, int32_t b) {
    return a * b;
}
```

### Step 3: Build Hook (`hook/build.dart`)
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

### Step 4: Dart `@Native` Bindings (`lib/native_example.dart`)
```dart
import 'dart:ffi';

@Native<Int32 Function(Int32, Int32)>()
external int add_numbers(int a, int b);

@Native<Int32 Function(Int32, Int32)>()
external int multiply_numbers(int a, int b);
```

---

## Summary of Best Practices
1. **For C/C++/Rust**: Use `package:hooks` + `hook/build.dart` + `@Native` annotations. This eliminates dynamic library loading boilerplate completely.
2. **For Kotlin/Java**: Use `package:jni` + `package:jnigen` + `jnigen.yaml`. Compile Kotlin to JVM bytecode / JARs and let `jnigen` generate strongly-typed Dart classes.
3. **Implicit Linking**: Name code asset outputs matching library URIs (e.g. `$packageName.dart`) so Dart links `@Native` bindings automatically.
