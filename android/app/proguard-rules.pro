-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.play.core.**

-keep class com.appsflyer.** { *; }
-dontwarn com.appsflyer.**

-keep class androidx.security.crypto.** { *; }

-keepclasseswithmembernames class * {
    native <methods>;
}

-assumenosideeffects class android.util.Log {
    public static int d(...);
    public static int v(...);
}
