import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

/// خدمة مراقبة الاتصال (ConnectivityService)
/// المسؤولة عن متابعة حالة الإنترنت في التطبيق وتنبيه المستخدم عند انقطاعه
class ConnectivityService extends GetxService {
  // أداة التحقق من الاتصال من حزمة connectivity_plus
  final Connectivity _connectivity = Connectivity();
  
  // متغير مراقب (Observable) لحالة الاتصال الحالية، افتراضياً متصل (true)
  var isConnected = true.obs;
  
  // اشتراك لمراقبة التغيرات اللحظية في حالة الشبكة
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  // متغير للتحقق مما إذا كان قد تم إظهار رسالة الانقطاع مسبقاً لمنع التكرار
  bool _isSnackbarVisible = false;

  /// تهيئة الخدمة عند تشغيل التطبيق
  Future<ConnectivityService> init() async {
    // التحقق من حالة الاتصال الأولية فور تشغيل الخدمة
    await _checkInitialStatus();
    // البدء في الاستماع لأي تغيير يطرأ على حالة الشبكة (WiFi, Data, None)
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    return this;
  }

  /// دالة للتحقق من الحالة عند بدء التشغيل
  Future<void> _checkInitialStatus() async {
    List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  /// تحديث حالة الاتصال وإظهار تنبيه للمستخدم في حالة الانقطاع
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // نعتبر الجهاز غير متصل إذا كانت القائمة تحتوي على 'none' فقط
    bool currentlyConnected = !results.contains(ConnectivityResult.none);
    
    // إذا تغيرت الحالة من متصل إلى غير متصل
    if (isConnected.value && !currentlyConnected) {
      _showOfflineSnackbar();
    } 
    // إذا عاد الاتصال، يمكن إظهار رسالة نجاح أو إغلاق رسالة الخطأ (اختياري)
    else if (!isConnected.value && currentlyConnected) {
       Get.closeAllSnackbars(); // إغلاق أي تنبيهات سابقة فور عودة الإنترنت
       _isSnackbarVisible = false;
    }

    isConnected.value = currentlyConnected;
  }

  /// دالة لإظهار رسالة الانقطاع مرة واحدة فقط
  void _showOfflineSnackbar() {
    if (_isSnackbarVisible) return; // منع التكرار إذا كانت الرسالة ظاهرة بالفعل

    // التحقق من أن الواجهة جاهزة قبل عرض الإشعار لتجنب خطأ Null check operator
    if (Get.overlayContext == null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!isConnected.value) _showOfflineSnackbar();
      });
      return;
    }

    _isSnackbarVisible = true;
    Get.rawSnackbar(
      titleText: Text(
        'no_internet_title'.tr,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      messageText: Text(
        'offline_mode_active_msg'.tr, // رسالة تبين الدخول في وضع الأوفلاين
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.orange.shade800,
      icon: const Icon(Icons.wifi_off, color: Colors.white),
      snackPosition: SnackPosition.TOP, // ظهورها بالأعلى لتبدو كشريط حالة
      isDismissible: false, // لا تختفي إلا إذا عاد الإنترنت أو سحبها المستخدم
      // duration: const Duration(days: 1), // تبقى ظاهرة لفترة طويلة جداً (دائمة عملياً)
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          _isSnackbarVisible = false;
        },
        child: Text('OK'.tr, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  void onClose() {
    // إلغاء الاشتراك عند إغلاق الخدمة لتجنب تسرب الذاكرة (Memory Leak)
    _subscription.cancel();
    super.onClose();
  }
}
