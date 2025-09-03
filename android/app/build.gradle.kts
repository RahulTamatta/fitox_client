plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.gym.fitness.fit.talk"
    compileSdk = flutter.compileSdkVersion
    // Pin NDK to a Flutter/AGP-compatible version (NDK r26) to avoid CMake configure failures with r27
    ndkVersion = "26.1.10909125"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Keep and package native libraries
    // NOTE: Removed pickFirst for libaosl/libc++ to avoid masking duplicate/conflicting versions during investigation
    packagingOptions {
        pickFirst("**/libagora-rtc-sdk.so")
    }
    packaging {
        jniLibs {
            // Keep debug symbols to prevent symbol stripping issues
            keepDebugSymbols += setOf(
                "**/libagora-rtc-sdk.so",
                "**/libaosl.so",
                "**/libc++_shared.so"
            )
            // Ensure .so files are placed correctly for older loaders
            useLegacyPackaging = true
            // Debug investigation: when RTM and RTC both ship libaosl.so, resolve duplicate by
            // picking one. Versions are aligned via resolutionStrategy; this prevents MergeNativeLibs failure.
            pickFirsts += setOf("**/libaosl.so")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.gym.fitness.fit.talk"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // NOTE: Removed global abiFilters to allow per-buildType control
    }

    // Conditional release signing: use provided keystore if present, else fall back to debug signing
    val releaseKeystoreFile = file("/Users/pankajgupta/fit_talk_key.jks")
    val hasReleaseKeystore = releaseKeystoreFile.exists()

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = "fit_talk"
                keyPassword = "fittalk"
                storeFile = releaseKeystoreFile
                storePassword = "fittalk"
            }
        }
    }


    buildTypes {
        debug {
            // Ensure resource shrinking is disabled in debug builds
            isMinifyEnabled = false
            isShrinkResources = false
            // Enable x86_64 for emulator symbol diagnostics while keeping ARM ABIs
            ndk {
                abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
            }
        }
        release {
            // Use release keystore if available, otherwise use debug signing so local runs work
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Keep release ARM-only as before for compatibility with Agora native libs
            ndk {
                abiFilters += listOf("arm64-v8a", "armeabi-v7a")
            }
        }
    }
}

// Do not globally exclude AOSL; RTC requires it. We align AOSL version and use pickFirst to avoid duplicates.

// Ensure a single authoritative version of Agora native dependencies (RTM & AOSL)
configurations.all {
    resolutionStrategy {
        // Force RTM to a published artifact on Maven Central
        force("io.agora:agora-rtm:2.2.5")
        // RTM depends on iris-rtm; 2.2.2-build.1 is not published on Maven Central. Use the closest published version.
        force("io.agora.rtm:iris-rtm:2.2.4-build.1")
        // Force AOSL to one version so only one libaosl.so ships. If RTC pulls a different AOSL, this ensures alignment.
        // NOTE: Coordinates confirmed via dependencyInsight: io.agora.infra:aosl:1.2.13.1
        force("io.agora.infra:aosl:1.2.13.1")

        // Optional: If some transitive brings an older libc++_shared, prefer the one from NDK; usually not needed.
        // preferProjectModules()
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Align AOSL with RTC 4.5.x line: AOSL 1.2.13.x
    constraints {
        add("implementation", "io.agora.infra:aosl:1.2.13.1") {
            because("RTC 4.5.x needs AOSL 1.2.13.x; prevents runtime symbol errors")
        }
    }

    // Use RTM but exclude its embedded AOSL to avoid duplicate native libs
    add("implementation", "io.agora:agora-rtm:2.2.5") {
        exclude(group = "io.agora.infra", module = "aosl")
    }
}
