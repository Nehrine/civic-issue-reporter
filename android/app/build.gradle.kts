plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")
    
    // 👇 THIS ACTIVATES FIREBASE
    id("com.google.gms.google-services") 
}

android {
    namespace = "com.example.civic_issue_app" // This can be anything, usually matches package name
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        // 👇👇👇 IMPORTANT: MATCH THIS TO YOUR FIREBASE CONSOLE 👇👇👇
        applicationId = "com.example.civic_issue_app" 
        
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

dependencies {
    // Leave this empty. Flutter handles dependencies in pubspec.yaml
}