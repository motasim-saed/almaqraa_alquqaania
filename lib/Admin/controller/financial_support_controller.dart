import 'package:get/get.dart';
import '../models/financial_support_model.dart';
import '../repository/financial_support_repository.dart';

class FinancialSupportController extends GetxController {
  final FinancialSupportRepository _repository = FinancialSupportRepository();

  var accounts = <FinancialSupportModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAccounts();
  }

  Future<void> fetchAccounts() async {
    isLoading.value = true;
    try {
      accounts.assignAll(await _repository.getAccounts());
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_fetch_accounts'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addAccount(FinancialSupportModel account) async {
    try {
      await _repository.addAccount(account);
      fetchAccounts();
      Get.back();
      Get.snackbar('success'.tr, 'account_added_success'.tr);
    } catch (e) {
      // print('Add account error: $e');
      Get.snackbar('error'.tr, 'failed_to_add_account'.tr);
    }
  }

  Future<void> updateAccount(FinancialSupportModel account) async {
    try {
      await _repository.updateAccount(account);
      fetchAccounts();
      Get.back();
      Get.snackbar('success'.tr, 'account_updated_success'.tr);
    } catch (e) {
      // print('Update account error: $e');
      Get.snackbar('error'.tr, 'failed_to_update_account'.tr);
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await _repository.deleteAccount(id);
      accounts.removeWhere((element) => element.id == id);
      Get.snackbar('success'.tr, 'account_deleted_success'.tr);
    } catch (e) {
      // print('Delete account error: $e');
      Get.snackbar('error'.tr, 'failed_to_delete_account'.tr);
    }
  }
}
