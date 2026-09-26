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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// 모든 하위 프로젝트 및 플러그인의 안드로이드 에스디케이(SDK) 버전을 강제로 36으로 고정합니다.
// 평가 완료 여부를 확인하여 충돌 없이 설정을 주입하는 고도화된 방식입니다.
subprojects {
    val configureAndroid = {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                // 컴파일 및 타겟 에스디케이 버전을 36으로 강제 지정합니다.
                android.compileSdkVersion(36)
            }
        }
    }

    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate { configureAndroid() }
    }
}
