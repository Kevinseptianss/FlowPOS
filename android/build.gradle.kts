allprojects {
    repositories {
        google()
        mavenCentral()
    }
    beforeEvaluate {
        pluginManager.withPlugin("com.android.library") {
            extensions.configure<com.android.build.gradle.LibraryExtension> {
                if (namespace == null) {
                    namespace = group.toString()
                }
                compileSdk = 35  // ← pastikan ini ada
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
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
