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
    tasks.configureEach {
        if (name.startsWith("check") && name.endsWith("AarMetadata")) {
            enabled = false
            val variant = name.removePrefix("check").removeSuffix("AarMetadata")
                .replaceFirstChar { it.lowercase() }
            project.layout.buildDirectory
                .dir("intermediates/aar_metadata_check/$variant/$name")
                .get().asFile.mkdirs()
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
