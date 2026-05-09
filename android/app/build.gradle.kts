import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// android/key.properties veya ortam değişkenleri (zayıf varsayılan parola yok)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun signingSecret(envName: String, propName: String): String? {
    val fromEnv = System.getenv(envName)?.trim()
    if (!fromEnv.isNullOrEmpty()) return fromEnv
    val fromProp = keystoreProperties.getProperty(propName)?.trim()
    return if (fromProp.isNullOrEmpty()) null else fromProp
}

val releaseStorePassword = signingSecret("KEY_STORE_PASSWORD", "storePassword")
val releaseKeyPassword = signingSecret("KEY_PASSWORD", "keyPassword")
val releaseKeyAlias = signingSecret("KEY_ALIAS", "keyAlias") ?: "upload"
val releaseStoreFileName = keystoreProperties.getProperty("storeFile")?.trim() ?: "upload-keystore.jks"
val releaseStoreFile = file(releaseStoreFileName)

val hasReleaseSigning =
    releaseStorePassword != null &&
        releaseKeyPassword != null &&
        releaseStoreFile.isFile

android {
    namespace = "com.baykus.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.baykus.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = releaseStoreFile
                storePassword = releaseStorePassword!!
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword!!
            }
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }

        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
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

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

afterEvaluate {
    val signingHelp =
        """
        Release imzası yapılandırılmadı.
        • android/key.properties dosyasını android/key.properties.example şablonundan oluşturun, VEYA
        • KEY_STORE_PASSWORD ve KEY_PASSWORD ortam değişkenlerini ayarlayın.
        • android/app/$releaseStoreFileName dosyasının var olduğundan emin olun.
        """.trimIndent()
    listOf("bundleRelease", "assembleRelease").forEach { taskName ->
        tasks.findByName(taskName)?.doFirst {
            check(hasReleaseSigning) { signingHelp }
        }
    }
}
