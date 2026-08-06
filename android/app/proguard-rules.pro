# Flutter motoru "deferred components" (parça parça indirme) desteği için
# Play Core sınıflarına referans veriyor. Bu oyunda o özellik kullanılmıyor ve
# kütüphane bağımlılıklarda yok, o yüzden R8'in eksik sınıf uyarılarını
# susturuyoruz. O kod hiç çalışmıyor.
-dontwarn com.google.android.play.core.**

# Küçültme sırasında kaybolmaması gereken sınıflar.
-keep class io.flutter.** { *; }
-keep class com.google.android.gms.ads.** { *; }

# Room / WorkManager: veritabani uygulamasini (WorkDatabase_Impl) Room
# yansimayla, sinif adindan uretip cagiriyor. R8 o sinifi kullanilmiyor sanip
# atinca yayin derlemesi ACILISTA COKUYOR:
#   Unable to get provider androidx.startup.InitializationProvider:
#   Failed to create an instance of androidx.work.impl.WorkDatabase
#
# androidx.work reklam SDK'siyla (play-services-ads) birlikte geliyor.
# Hata ayiklama derlemesinde R8 calismadigi icin gorunmuyor; yalnizca
# release paketi cihazda calistirilinca ortaya cikiyor.
-keep class androidx.room.RoomDatabase { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.sqlite.db.** { *; }
-dontwarn androidx.work.**
