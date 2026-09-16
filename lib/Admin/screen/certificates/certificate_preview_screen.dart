import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:get/get.dart';

/// شاشة معاينة الشهادة (CertificatePreviewScreen)
/// تدعم الثيم الفاتح والغامق بشكل كامل
class CertificatePreviewScreen extends StatelessWidget {
  final Future<Uint8List> pdfFuture;
  final String title;

  const CertificatePreviewScreen({
    super.key,
    required this.pdfFuture,
    this.title = 'certificates',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          title.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.titleLarge?.color,
        elevation: 0,
        centerTitle: true,
      ),
      body: PdfPreview(
        build: (format) => pdfFuture,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        // تخصيص ألوان المعاينة لتناسب الثيم
        pdfPreviewPageDecoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        loadingWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.primaryColor),
              const SizedBox(height: 20),
              Text(
                'generating_pdf'.tr,
                style: TextStyle(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
        // تخصيص أزرار التحكم في المعاينة
        actions: [
          PdfPrintAction(
            icon: const Icon(Icons.print_rounded),
            jobName: title.tr,
          ),
          PdfShareAction(
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
    );
  }
}
