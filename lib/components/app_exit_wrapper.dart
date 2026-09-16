import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// ويدجت تغليف للتحكم في عملية الخروج من التطبيق عبر زر الرجوع.
/// يظهر حوار تأكيد للمستخدم قبل الخروج.
class AppExitWrapper extends StatelessWidget {
  final Widget child;

  const AppExitWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final bool? exitResult = await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'exit_confirmation'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'exit_confirmation_msg'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text(
                  'cancel'.tr,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Get.back(result: true),
                child: Text(
                  'exit'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        if (exitResult == true) {
          // الخروج الفعلي من التطبيق
          SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}
