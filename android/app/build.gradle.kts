// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    
    // 🔥 Add the Google Services plugin (THIS LINE)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.haven_os"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.haven_os"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// 🔥 Optional but recommended: Firebase BoM helps keep Firebase SDK versions aligned
dependencies {
    // Firebase Bill of Materials (BoM) – ensures all Firebase SDK versions are compatible
    implementation(platform("com.google.firebase:firebase-bom:34.18.0"))
    
    // No need to add firebase‑core or firebase‑firestore here;
    // the Flutter packages will pull them automatically.
    // Adding the BoM is enough to manage versions.
}