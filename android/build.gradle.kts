allprojects {
    repositories {
        google()
        mavenCentral()
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
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

subprojects {
    fun configureNamespace(proj: Project) {
        if (proj.hasProperty("android")) {
            val android = proj.extensions.getByName("android")
            try {
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                val getNamespace = android.javaClass.getMethod("getNamespace")
                if (getNamespace.invoke(android) == null) {
                    val manifestFile = proj.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestXml = manifestFile.readText()
                        val packageMatch = Regex("package=\"([^\"]*)\"").find(manifestXml)
                        if (packageMatch != null) {
                            val packageName = packageMatch.groups[1]?.value
                            setNamespace.invoke(android, packageName)
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore errors
            }
        }
    }

    if (project.state.executed) {
        configureNamespace(project)
    } else {
        project.afterEvaluate {
            configureNamespace(project)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
