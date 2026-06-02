plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.my_timer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    defaultConfig {
        applicationId = "com.example.my_timer"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 1. signingConfigs 블록을 buildTypes보다 위에 명시적으로 선언해 두면 안전합니다.
    signingConfigs {
        getByName("debug") {
            // 기본 debug 키스토어 설정을 그대로 사용하겠다는 의미라면 비워두어도 됩니다.
        }
    }

    buildTypes {
        release {
            // 2. 위의 signingConfigs에서 안전하게 꺼내오도록 수정합니다.
            signingConfig = signingConfigs.getByName("debug")

            isMinifyEnabled = false
            isShrinkResources = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    flutter {
        source = "../.."
    }
}

// 3. dependencies 블록은 원래 android { ... } 블록 '바깥'에 있어야 합니다!
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}