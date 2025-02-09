allprojects {
    repositories {
        google()
        mavenCentral()
    }
    buildscript {
        dependencies {
            // The Android Gradle Plugin knows how to build native code with the NDK.
            classpath("com.android.tools.build:gradle:8.11.1")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
