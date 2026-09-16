# R8 / ProGuard rules for Al Maqraa
# Fixes "Missing classes detected while running R8" for javax.lang.model

-dontwarn javax.lang.model.**
-keep class javax.lang.model.** { *; }

-dontwarn autovalue.shaded.**
-dontwarn com.google.auto.value.**
-dontwarn com.squareup.javapoet.**

# Flutter and standard Android rules are usually handled by the plugin,
# but these specific library warnings need manual suppression.
