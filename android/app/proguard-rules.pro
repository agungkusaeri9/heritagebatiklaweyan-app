# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SharedPreferences ProGuard keep rules
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep interface io.flutter.plugins.sharedpreferences.** { *; }
-keepclasseswithmembers class io.flutter.plugins.sharedpreferences.** {
    native <methods>;
    *;
}

# Flutter Secure Storage
-keep class androidx.security.crypto.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
