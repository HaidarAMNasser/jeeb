# Keep networking and connectivity so release build can use the internet.
# Flutter/Dart HTTP uses the engine; these keep plugin and platform code from being stripped.

# OkHttp (used by some plugins or the engine)
-dontwarn okhttp3.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.**

# Connectivity / network state
-keep class io.flutter.plugins.** { *; }

# Keep native methods used by Dart
-keepclassmembers class * {
    native <methods>;
}

# Prevent R8 from stripping classes that might be used via reflection
-keepattributes Signature
-keepattributes *Annotation*
