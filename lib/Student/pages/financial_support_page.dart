import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../Admin/controller/financial_support_controller.dart';

class FinancialSupportPage extends StatelessWidget {
  final controller = Get.put(FinancialSupportController());

  FinancialSupportPage({super.key});

  Widget _buildAccountRow(String label, String accountNumber) {
    if (accountNumber.trim().isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 15, fontFamily: 'Cairo', fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              accountNumber,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: accountNumber));
                Get.snackbar('copied'.tr, 'account_copied_msg'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('financial_support'.tr, style: const TextStyle(fontFamily: 'Cairo')),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.accounts.isEmpty) {
          return Center(child: Text('no_accounts_available'.tr, style: const TextStyle(fontFamily: 'Cairo')));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 420, // ارتفاع مناسب للبيانات
          ),
          itemCount: controller.accounts.length,
          itemBuilder: (context, index) {
            final account = controller.accounts[index];
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            account.providerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              fontFamily: 'Cairo'
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (account.accountHolderName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              account.accountHolderName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontFamily: 'Cairo'
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (!account.isDivided) ...[
                              _buildAccountRow('yemeni'.tr, account.accountYemeni),
                              _buildAccountRow('saudi'.tr, account.accountSaudi),
                              _buildAccountRow('dollar'.tr, account.accountDollar),
                            ] else ...[
                              _buildSectionBadge('south'.tr),
                              const SizedBox(height: 12),
                              _buildAccountRow('yemeni'.tr, account.accountSouthYemeni),
                              _buildAccountRow('saudi'.tr, account.accountSouthSaudi),
                              _buildAccountRow('dollar'.tr, account.accountSouthDollar),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: Colors.white24, height: 1),
                              ),
                              _buildSectionBadge('north'.tr),
                              const SizedBox(height: 12),
                              _buildAccountRow('yemeni'.tr, account.accountNorthYemeni),
                              _buildAccountRow('saudi'.tr, account.accountNorthSaudi),
                              _buildAccountRow('dollar'.tr, account.accountNorthDollar),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildSectionBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal:16, vertical:4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha:0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          fontFamily: 'Cairo'
        ),
      ),
    );
  }
}
