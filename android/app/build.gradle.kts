import org.gradle.api.JavaVersion
plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.nemurasa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
kotlinOptions {
        jvmTarget = "1.8"
    }

defaultConfig {
        applicationId = "com.example.nemurasa" // (atau sesuai yang ada di kodemu)
        minSdk = flutter.minSdkVersion // <-- Ubah dari minSdk menjadi minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.credentials:credentials:1.3.0")
implementation("androidx.credentials:credentials-play-services-auth:1.3.0")
implementation("com.google.android.libraries.identity.googleid:googleid:1.1.1")
    // ... dependensi bawaan flutter lainnya ...
coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
