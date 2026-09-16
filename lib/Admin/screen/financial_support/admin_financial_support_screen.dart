import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controller/financial_support_controller.dart';
import '../../models/financial_support_model.dart';

class AdminFinancialSupportScreen extends StatelessWidget {
  final controller = Get.put(FinancialSupportController());

  AdminFinancialSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.accounts.isEmpty) {
          return Center(child: Text('no_accounts_found'.tr, style: const TextStyle(fontFamily: 'Cairo')));
        }
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 380, // ارتفاع البطاقة لتكون مربعة تقريباً
          ),
          itemCount: controller.accounts.length,
          itemBuilder: (context, index) {
            final account = controller.accounts[index];
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Get.isDarkMode 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.black.withValues(alpha: 0.02),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.providerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (account.accountHolderName.isNotEmpty)
                                Text(
                                  account.accountHolderName,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                account.isDivided ? 'split_north_south'.tr : 'unified_account'.tr,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          if (!account.isDivided) ...[
                            _buildDetailRow('yemeni'.tr, account.accountYemeni, Icons.money),
                            _buildDetailRow('saudi'.tr, account.accountSaudi, Icons.account_balance),
                            _buildDetailRow('dollar'.tr, account.accountDollar, Icons.attach_money),
                          ] else ...[
                            _buildSectionHeader('south'.tr, Icons.south_rounded),
                            _buildDetailRow('yemeni'.tr, account.accountSouthYemeni, Icons.money),
                            _buildDetailRow('saudi'.tr, account.accountSouthSaudi, Icons.account_balance),
                            _buildDetailRow('dollar'.tr, account.accountSouthDollar, Icons.attach_money),
                            const SizedBox(height: 8),
                            _buildSectionHeader('north'.tr, Icons.north_rounded),
                            _buildDetailRow('yemeni'.tr, account.accountNorthYemeni, Icons.money),
                            _buildDetailRow('saudi'.tr, account.accountNorthSaudi, Icons.account_balance),
                            _buildDetailRow('dollar'.tr, account.accountNorthDollar, Icons.attach_money),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: IconButton(
                            onPressed: () => _showAccountDialog(context, account: account),
                            icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blue.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: IconButton(
                            onPressed: () => _confirmDelete(context, account.id),
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  void _showAccountDialog(BuildContext context, {FinancialSupportModel? account}) {
    final providerController = TextEditingController(text: account?.providerName);
    final accountHolderController = TextEditingController(text: account?.accountHolderName);
    bool isDivided = account?.isDivided ?? false;
    
    final yemeniController = TextEditingController(text: account?.accountYemeni);
    final saudiController = TextEditingController(text: account?.accountSaudi);
    final dollarController = TextEditingController(text: account?.accountDollar);

    final northYemeniController = TextEditingController(text: account?.accountNorthYemeni);
    final northSaudiController = TextEditingController(text: account?.accountNorthSaudi);
    final northDollarController = TextEditingController(text: account?.accountNorthDollar);

    final southYemeniController = TextEditingController(text: account?.accountSouthYemeni);
    final southSaudiController = TextEditingController(text: account?.accountSouthSaudi);
    final southDollarController = TextEditingController(text: account?.accountSouthDollar);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: 500,
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Row(
                      children: [
                        Icon(account == null ? Icons.add_box_rounded : Icons.edit_note_rounded, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 12),
                        Text(
                          account == null ? 'add_account'.tr : 'edit_account'.tr,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('provider_name'.tr),
                          TextField(
                            controller: providerController,
                            decoration: _inputDecoration('provider_name'.tr, Icons.account_balance_rounded),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 20),
                          _buildFieldLabel('account_holder_name'.tr),
                          TextField(
                            controller: accountHolderController,
                            decoration: _inputDecoration('account_holder_name'.tr, Icons.person_rounded),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 20),
                          
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SwitchListTile(
                              title: Text(
                                'split_north_south'.tr,
                                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              value: isDivided,
                              onChanged: (val) => setState(() => isDivided = val),
                              activeColor: Theme.of(context).primaryColor,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          if (!isDivided) ...[
                            _buildDialogSectionHeader('unified_account'.tr, Icons.layers_rounded),
                            _buildFieldLabel('account_number_yemeni'.tr),
                            TextField(
                              controller: yemeniController,
                              decoration: _inputDecoration('yemeni'.tr, Icons.money),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                            const SizedBox(height: 12),
                            _buildFieldLabel('account_number_saudi'.tr),
                            TextField(
                              controller: saudiController,
                              decoration: _inputDecoration('saudi'.tr, Icons.account_balance),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                            const SizedBox(height: 12),
                            _buildFieldLabel('account_number_dollar'.tr),
                            TextField(
                              controller: dollarController,
                              decoration: _inputDecoration('dollar'.tr, Icons.attach_money),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ] else ...[
                            _buildDialogSectionHeader('south'.tr, Icons.south_rounded, color: Colors.blue),
                            _buildFieldLabel('account_number_yemeni'.tr),
                            TextField(
                              controller: southYemeniController,
                              decoration: _inputDecoration('yemeni'.tr, Icons.money),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                            const SizedBox(height: 12),
                            _buildFieldLabel('account_number_saudi'.tr),
                            TextField(
                              controller: southSaudiController,
                              decoration: _inputDecoration('saudi'.tr, Icons.account_balance),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                            const SizedBox(height: 12),
                            _buildFieldLabel('account_number_dollar'.tr),
                            TextField(
                              controller: southDollarController,
                              decoration: _inputDecoration('dollar'.tr, Icons.attach_money),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                            
                            const SizedBox(height: 24),
                            _buildDialogSectionHeader('north'.tr, Icons.north_rounded, color: Colors.teal),
                            _buildFieldLabel('account_number_yemeni'.tr),
                            TextField(
                              controller: northYemeniController,
                              decoration: _inputDecoration('yemeni'.tr, Icons.money),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                            const SizedBox(height: 12),
                            _buildFieldLabel('account_number_saudi'.tr),
                            TextField(
                              controller: northSaudiController,
                              decoration: _inputDecoration('saudi'.tr, Icons.account_balance),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                            const SizedBox(height: 12),
                            _buildFieldLabel('account_number_dollar'.tr),
                            TextField(
                              controller: northDollarController,
                              decoration: _inputDecoration('dollar'.tr, Icons.attach_money),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  // Actions
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Get.back(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('cancel'.tr, style: const TextStyle(fontFamily: 'Cairo')),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final newModel = FinancialSupportModel(
                                id: account?.id ?? '',
                                providerName: providerController.text,
                                accountHolderName: accountHolderController.text,
                                isDivided: isDivided,
                                accountYemeni: yemeniController.text,
                                accountSaudi: saudiController.text,
                                accountDollar: dollarController.text,
                                accountNorthYemeni: northYemeniController.text,
                                accountNorthSaudi: northSaudiController.text,
                                accountNorthDollar: northDollarController.text,
                                accountSouthYemeni: southYemeniController.text,
                                accountSouthSaudi: southSaudiController.text,
                                accountSouthDollar: southDollarController.text,
                              );

                              if (account == null) {
                                controller.addAccount(newModel);
                              } else {
                                controller.updateAccount(newModel);
                              }
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('save'.tr, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildDialogSectionHeader(String title, IconData icon, {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    Get.defaultDialog(
      title: 'confirm_delete'.tr,
      middleText: 'delete_account_confirm_msg'.tr,
      textConfirm: 'delete'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      onConfirm: () {
        controller.deleteAccount(id);
        Get.back();
      },
    );
  }

  Widget _buildDetailRow(String label, String? value, IconData icon) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
