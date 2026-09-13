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
    project.evaluationDependsOn(":app")
}

subprojects {
    val fixNamespace: Project.() -> Unit = {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                if (getNamespace.invoke(androidExt) == null) {
                    val fallbackNamespace = "com.fundamentzz.plugins.${name.replace("-", "_").replace(":", "")}"
                    setNamespace.invoke(androidExt, fallbackNamespace)
                }
            } catch (_: Exception) {}
        }
    }

    if (state.executed) {
        fixNamespace()
    } else {
        afterEvaluate { fixNamespace() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
