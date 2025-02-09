// The Android Gradle Plugin builds the native code with the Android NDK.

group = "ai.konnekted.ai4all.unnu_ragl"
version = "1.0"

buildscript {
    repositories {
        google()
        mavenCentral()
		gradlePluginPortal()
    }

    dependencies {
        // The Android Gradle Plugin knows how to build native code with the NDK.
        classpath("com.android.tools.build:gradle:8.9.0")
    }
}

allprojects {
    repositories {
        google()
        jcenter()
    }
}

plugins {
    id("com.android.library")
	id("org.jetbrains.kotlin.android")
}

android {
    namespace = "ai.konnekted.ai4all.unnu_rag_lite"

    // Bumping the plugin compileSdk version requires all clients of this plugin
    // to bump the version in their app.
    compileSdk = 35

    // Use the NDK version
    // declared in /android/app/build.gradle file of the Flutter project.
    // Replace it with a version number if this plugin requires a specific NDK version.
    // (e.g. ndkVersion "23.1.7779620")
    ndkVersion = android.ndkVersion

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = false
            externalNativeBuild {
                cmake {
                    arguments += listOf("-DCMAKE_BUILD_TYPE=Release", "-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON")
                    targets += listOf("unnu_ragl")
                }
            }
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.findByName("debug")
        }

        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
            externalNativeBuild {
                cmake {
                    arguments += listOf("-DCMAKE_BUILD_TYPE=Debug", "-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON")
                    targets += listOf("unnu_ragl")
                }
            }
        }
    }

    // Invoke the shared CMake build with the Android Gradle Plugin.
    externalNativeBuild {
        cmake {
            path = file("./CMakeLists.txt")
            version = "3.31.6"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
	    ndk {
            abiFilters += listOf("arm64-v8a")
        }
        minSdk = 32
		targetSdk = 35
    }
}
