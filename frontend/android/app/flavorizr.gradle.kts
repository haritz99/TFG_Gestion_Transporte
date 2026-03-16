import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("default")

    productFlavors {
        create("dev") {
            dimension = "default"
            applicationId = "com.example.myapp.dev"
            resValue(type = "string", name = "app_name", value = "Gestion Transporte Dev")
        }
        create("staging") {
            dimension = "default"
            applicationId = "com.example.myapp.staging"
            resValue(type = "string", name = "app_name", value = "Gestion Transporte Staging")
        }
        create("prod") {
            dimension = "default"
            applicationId = "com.example.myapp"
            resValue(type = "string", name = "app_name", value = "Gestion Transporte")
        }
    }
}