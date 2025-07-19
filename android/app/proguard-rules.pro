# Razorpay keep rules
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keepattributes *Annotation*

# Keep annotations
-keep class proguard.annotation.Keep
-keep class proguard.annotation.KeepClassMembers