# ✅ Google Maps Proguard Rules
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# ✅ Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ✅ Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ✅ OpenGL and Graphics
-keep class android.opengl.** { *; }
-keep class javax.microedition.khronos.** { *; }
-dontwarn android.opengl.**
-dontwarn javax.microedition.khronos.**

# ✅ EGL Graphics Context
-keep class android.opengl.EGL** { *; }
-keep class com.google.android.gms.maps.internal.** { *; }

# ✅ OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# ✅ Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# ✅ Geolocator
-keep class com.baseflow.geolocator.** { *; }

# ✅ Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }
