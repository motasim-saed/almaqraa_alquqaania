package com.example.al_maqraa

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
// أحياناً يفشل التعرف على هذه المكتبة إذا لم يتم عمل build بنجاح مرة واحدة على الأقل
// سنحاول استخدام التحديد الكامل للمسار داخل الكود لتجنب مشاكل الـ Import

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        try {
            // محاولة إعداد الكاميرا برمجياً إذا كانت المكتبة متاحة
            val cameraPluginClass = Class.forName("io.flutter.plugins.camera.CameraPlugin")
            val cameraImplementationClass = Class.forName("io.flutter.plugins.camera.CameraImplementation")
            val camera2Field = cameraImplementationClass.getField("CAMERA_2")
            val camera2Value = camera2Field.get(null)
            
            val setMethod = cameraPluginClass.getMethod("setCameraImplementation", cameraImplementationClass)
            setMethod.invoke(null, camera2Value)
        } catch (e: Exception) {
            // في حال عدم العثور على المكتبة أثناء الـ compile، سيتم تجاهل الخطأ ولن يتوقف البناء
            println("CameraPlugin not found or failed to set implementation: ${e.message}")
        }
    }
}
