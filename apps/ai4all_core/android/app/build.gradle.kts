import com.android.build.api.artifact.MultipleArtifact
import com.android.build.gradle.internal.cxx.configure.gradleLocalProperties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ai.konnekted.ai4all.core.mobile"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ai.konnekted.ai4all.core"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 32
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Invoke the shared CMake build with the Android Gradle Plugin.
        externalNativeBuild {
            cmake {
                arguments += listOf("-DCMAKE_BUILD_TYPE=Release", "-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON", "-DCMAKE_POSITION_INDEPENDENT_CODE=ON")
                version = "3.31.6"
            }
        }
    }
    
    bundle {
        language {
            enableSplit = false
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }

    var keystorepsswd : String = gradleLocalProperties(rootDir, providers).getProperty("keystore.password")

    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = keystorepsswd
            storeFile = file("../../private/appsigning.jks")
            storePassword = keystorepsswd
        }
    }

    buildTypes {
        release {
            ndk {
                abiFilters += listOf("arm64-v8a")

                debugSymbolLevel = "SYMBOL_TABLE"
            }
            isMinifyEnabled = true
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }    
}

flutter {
    source = "../.."
}
