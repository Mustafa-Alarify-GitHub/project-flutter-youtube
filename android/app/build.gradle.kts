plugins {
    id("com.android.application")
    id("kotlin-android")
    // يجب تطبيق مكوّن فلاتر الإضافي بعد مكوّنات أندرويد وكوتلن
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // المعرّف الخاص بحزمة التطبيق (Package Name)
    namespace = "com.example.ww"
    
    // تم تحديثه إلى 34 لحل مشكلة التوافق مع المكتبات الحديثة
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // معرف التطبيق الفريد على المتجر
        applicationId = "com.example.ww"
        
        // يعتمد على أقل نسخة يدعمها فلاتر تلقائياً
        minSdk = flutter.minSdkVersion
        
        // تم تحديثه إلى 34 ليتوافق مع الـ compileSdk
        targetSdk = 34
        
        // يتم جلب رقم الإصدار واسم الإصدار تلقائياً من ملف pubspec.yaml
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // هنا يتم إعداد التوقيع الرقمي للتطبيق عند رفعه للمتجر
            // حالياً يستخدم مفتاح الـ debug لتتمكن من تجربة الـ release محلياً
            signingConfig = signingConfigs.getByName("debug")
            
            // تفعيل حماية وتقليص حجم الكود (اختياري)
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    // يشير إلى مسار مجلد المشروع الأساسي (الذي يحتوي على مجلد lib)
    source = "../.."
}