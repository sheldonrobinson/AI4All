// The Android Gradle Plugin builds the native code with the Android NDK.

group = "ai.konnekted.ai4all.unnu_ce"
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
    namespace = "ai.konnekted.ai4all.unnu_ce"

    // Bumping the plugin compileSdk version requires all clients of this plugin
    // to bump the version in their app.
    compileSdk = 35

    ndkVersion = android.ndkVersion


    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = false
            externalNativeBuild {
                cmake {
                    arguments += listOf("-DCMAKE_BUILD_TYPE=Release", "-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON")
                    targets += listOf("unnu_ce", "onnxruntime-genai-static", "ortbuild", "tokenizers_cpp")
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
                    targets += listOf("unnu_ce", "onnxruntime-genai-static", "ortbuild", "tokenizers_cpp")
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
