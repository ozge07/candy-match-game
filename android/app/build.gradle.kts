import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// AdMob uygulama kimliği. Gerçek değer android/admob.properties dosyasında
// tutuluyor ve depoya girmiyor (bkz. admob.properties.example). Dosya yoksa
// Google'ın test kimliğine düşüyoruz; böylece temiz bir klon da derlenebiliyor
// ve yanlışlıkla gerçek reklam gösterilmiyor.
val admobTestAppId = "ca-app-pub-3940256099942544~3347511713"
val admobProperties = Properties().apply {
    val file = rootProject.file("admob.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}
val resolvedAdmobAppId: String =
    admobProperties.getProperty("admobAppId") ?: admobTestAppId

// Yayın imzası. Gerçek anahtar bilgileri android/key.properties içinde ve
// depoya girmiyor. Dosya yoksa release yine derlenebilsin diye debug
// anahtarlarına düşüyoruz — ama o paket Play Store'a yüklenemez.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}
val hasReleaseKey = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.bluelabsgames.candymatch"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bluelabsgames.candymatch"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // AndroidManifest.xml içindeki ${'$'}{admobAppId} bununla doluyor.
        manifestPlaceholders["admobAppId"] = resolvedAdmobAppId
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
