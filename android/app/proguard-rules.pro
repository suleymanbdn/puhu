## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

## Hive - Kapsamlı kurallar
-keep class * extends hive.HiveObjectMixin { *; }
-keep @hive.HiveType class * { *; }
-keep @hive.HiveField class * { *; }
-keep class **$HiveFieldAdapter { *; }
-keep class * extends hive.TypeAdapter { *; }
-keepclassmembers class * extends hive.HiveObject {
    <fields>;
    <methods>;
}
-keepclassmembers class * {
    @hive.HiveField *;
}

## Gson / JSON
-keepattributes Signature
-dontwarn sun.misc.**
-keep class com.google.gson.examples.android.model.** { <fields>; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

## Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

## Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

## Riverpod / State Management
-keep class * extends com.riverpod.** { *; }
-keepclassmembers class * {
    @com.riverpod.* <methods>;
}

## Keep app models and MainActivity
-keep class com.baykus.app.** { *; }
-keep class com.baykus.app.MainActivity { *; }

## General Android
-keepattributes InnerClasses

## R8 optimizasyonlarına izin ver ancak bazı alanlarda dikkatli ol
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
