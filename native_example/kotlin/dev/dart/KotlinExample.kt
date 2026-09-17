package dev.dart

class KotlinExample {
    fun greet(name: String): String {
        return "Hello $name from Kotlin!"
    }

    companion object {
        @JvmStatic
        fun add(a: Int, b: Int): Int {
            return a + b
        }
    }
}
