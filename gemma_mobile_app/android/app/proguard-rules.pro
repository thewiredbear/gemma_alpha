# Flutter's default rules.
-dontwarn io.flutter.embedding.**

# --- MediaPipe, Protobuf, and Gemma Dependencies ---
# These are called via JNI/reflection. Keep all their members and don't warn about them.
# This is a more aggressive version of the previous rule.
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# --- Annotation Processor & Code Generation Libraries ---
# These are COMPILE-TIME tools (like AutoValue) that should not be in the final APK.
# Some dependencies incorrectly leak them. The `-dontwarn` directive tells R8 to
# ignore the fact that these classes are missing from the Android runtime. THIS IS THE KEY FIX.
-dontwarn javax.lang.model.**
-dontwarn com.google.auto.value.**
-dontwarn autovalue.shaded.**

# --- Common Networking Libraries ---
# Often used by Google SDKs. Better to keep them safe.
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# --- Other potential dependencies from previous error logs ---
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**
-keep class org.conscrypt.** { *; }
-dontwarn org.conscrypt.**