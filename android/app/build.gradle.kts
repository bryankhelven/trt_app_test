plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dev.example.tarot_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.example.tarot_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
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

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Flutter 3.47.2 omits dev plugins from release dependencies but its Java
// registrant can still reference integration_test. Keep registration variant
// specific, retaining the integration plugin for debug/profile only.
val originalRegistrant = file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
tasks.withType<JavaCompile>().configureEach {
    exclude { it.file == originalRegistrant }
}
for (mode in listOf("debug", "profile", "release")) {
    val variant = mode.replaceFirstChar { it.uppercase() }
    val generatedDir = layout.buildDirectory.dir("generated/arcanumRegistrant/$mode")
    android.sourceSets.maybeCreate(mode).java.srcDir(generatedDir.get().asFile)
    val prepareRegistrant = tasks.register("prepare${variant}ArcanumRegistrant") {
        inputs.file(originalRegistrant)
        outputs.dir(generatedDir)
        doLast {
            var content = originalRegistrant.readText()
            if (mode == "release") {
                content = content.replace(
                    Regex("(?s)    try \\{\\s*flutterEngine\\.getPlugins\\(\\)\\.add\\(new dev\\.flutter\\.plugins\\.integration_test\\.IntegrationTestPlugin\\(\\)\\);\\s*\\} catch \\(Exception e\\) \\{.*?\\n    \\}\\n"),
                    ""
                )
                check(!content.contains("dev.flutter.plugins.integration_test")) {
                    "Unexpected integration registrant format; review Flutter compatibility workaround."
                }
            }
            val output = generatedDir.get().file("io/flutter/plugins/GeneratedPluginRegistrant.java").asFile
            output.parentFile.mkdirs()
            output.writeText(content)
        }
    }
    tasks.matching { it.name == "pre${variant}Build" }.configureEach {
        dependsOn(prepareRegistrant)
    }
}
