// android/build.gradle.kts
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// FIX: Convert strings to File objects using `file()`
rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
