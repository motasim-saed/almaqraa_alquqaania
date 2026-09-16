import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/app_constants.dart';
import '../utils/app_cached_image.dart';
import '../config/supabase_config.dart';

/// شاشة الدعم الفني ومعلومات التواصل
/// تعرض بيانات المطور مع إمكانية التواصل عبر عدة قنوات ومشاركة التطبيق
class TechSupportScreen extends StatelessWidget {
  const TechSupportScreen({super.key});

  /// فتح رابط خارجي
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        'error'.tr,
        'cannot_open_url'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  /// مشاركة رابط التطبيق
  void _shareApp() {
    Share.share('${'share_app_message'.tr} ${AppConstants.appShareLink}');
  }

  @override
  Widget build(BuildContext context) {
    // بناء رابط الصورة من Supabase Storage
    final String supportImageUrl = SupabaseConfig.getImageUrl(
      AppConstants.bucketSupport,
      AppConstants.supportImagePath,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('tech_support'.tr),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // صورة المطور من Supabase Storage مع التخزين المحلي والضبط الرأسي للتوسيط
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 110,
                      height: 110,
                      child: AppCachedImage(
                        imageUrl: supportImageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorWidget: Container(
                          color: Colors.blue.withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            'assetes/images/maqraa.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'support_title'.tr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'support_subtitle'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 40),

                // واتساب
                _buildContactButton(
                  icon: Icons.chat,
                  title: 'whatsapp'.tr,
                  color: Colors.green,
                  onTap: () => _launchUrl(AppConstants.whatsappUrl),
                ),
                const SizedBox(height: 16),

                // تليجرام
                _buildContactButton(
                  icon: Icons.send,
                  title: 'telegram'.tr,
                  color: Colors.blue,
                  onTap: () => _launchUrl(AppConstants.telegramUrl),
                ),
                const SizedBox(height: 16),

                // البريد الإلكتروني
                _buildContactButton(
                  icon: Icons.email,
                  title: 'email_support'.tr,
                  color: Colors.redAccent,
                  onTap: () => _launchUrl(AppConstants.emailUrl),
                ),

                // مشاركة التطبيق (يظهر فقط عند وجود رابط التطبيق)
                if (AppConstants.appShareLink.isNotEmpty) ...[
                  const Divider(height: 60, thickness: 1),
                  _buildContactButton(
                    icon: Icons.share,
                    title: 'share_app'.tr,
                    color: Colors.orange,
                    onTap: _shareApp,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }
}
