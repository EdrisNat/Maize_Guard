# TensorFlow Lite rules
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
