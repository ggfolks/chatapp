## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Temporarily ignore issues with embedding, remove when below issue is resolved:
## https://github.com/flutter/flutter/issues/37441
-dontwarn io.flutter.embedding.**

## This is apparently needed... permanently?
-dontwarn android.**
