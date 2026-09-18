import 'package:al_maqraa/Admin/controller/settings/admin_settings_controller.dart';
import 'package:al_maqraa/core/utils/clipboard_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controller/settings/admin_manage_users_controller.dart';
import '../../models/admin_models.dart';

class AdminManageUsersScreen extends StatelessWidget {
  const AdminManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminManageUsersController>();
    final systemCtrl = Get.put(AdminSettingsController());
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Content: Users List in Grid
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, controller),
                  const SizedBox(height: 20),
                  _buildFilterTabs(context, controller),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final usersList = controller.filteredUsers;
                      
                      if (usersList.isEmpty) {
                        return _buildEmptyState();
                      }
                      
                      return RefreshIndicator(
                        onRefresh: controller.refreshData,
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 130, // Compact height for grid items
                          ),
                          itemCount: usersList.length,
                          padding: const EdgeInsets.only(bottom: 20),
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final user = usersList[index];
                            return _buildUserCard(context, controller, user);
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          
          // Small Sidebar for System Controls
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black.withValues(alpha: 0.1) : Colors.grey.shade50,
              border: Border(
                left: Get.locale?.languageCode == 'ar' ? BorderSide.none : BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                right: Get.locale?.languageCode == 'ar' ? BorderSide(color: Colors.grey.withValues(alpha: 0.1)) : BorderSide.none,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildSystemControls(context, systemCtrl),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminManageUsersController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'manage_management_users'.tr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.indigo,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'add_and_view_admins_coordinators'.tr,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddUserDialog(context, controller),
          icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 16),
          label: Text(
            'add_new_user'.tr,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(BuildContext context, AdminManageUsersController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.indigo.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Obx(() => Row(
        children: [
          _buildFilterTab(
            label: 'all'.tr,
            count: controller.users.length,
            isSelected: controller.selectedTabRole.value == 'all',
            onTap: () => controller.selectedTabRole.value = 'all',
          ),
          _buildFilterTab(
            label: 'role_admin'.tr,
            count: controller.adminsCount,
            isSelected: controller.selectedTabRole.value == 'admin',
            onTap: () => controller.selectedTabRole.value = 'admin',
          ),
          _buildFilterTab(
            label: 'role_coordinator'.tr,
            count: controller.coordinatorsCount,
            isSelected: controller.selectedTabRole.value == 'coordinator',
            onTap: () => controller.selectedTabRole.value = 'coordinator',
          ),
        ],
      )),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Colors.indigo : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.indigo.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.indigo.shade700,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 50, color: Colors.indigo.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            'no_users_found'.tr,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    AdminManageUsersController controller,
    AdminUserModel user,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isCurrentUser = user.id == controller.currentUserId;
    final bool isAdmin = user.role == 'admin' || user.role == 'super_admin';

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser 
            ? Border.all(color: Colors.indigo.withValues(alpha: 0.4), width: 1.2)
            : Border.all(color: Colors.transparent, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _showEditUserDialog(context, controller, user),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: isAdmin ? Colors.purple.shade50 : Colors.blue.shade50,
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings_rounded : Icons.manage_accounts_rounded,
                        color: isAdmin ? Colors.purple : Colors.blue,
                        size: 20,
                      ),
                    ),
                    if (isCurrentUser)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          child: const Icon(Icons.check, size: 7, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isDarkMode ? Colors.white : const Color(0xFF2D3142),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isAdmin ? Colors.purple.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              isAdmin ? 'role_admin'.tr : 'role_coordinator'.tr,
                              style: TextStyle(
                                color: isAdmin ? Colors.purple : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      icon: Icons.copy_rounded,
                      color: Colors.indigo,
                      onPressed: () => copyToClipboard(
                        user.email,
                        label: 'email'.tr,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildActionButton(
                      icon: Icons.edit_rounded,
                      color: Colors.blue,
                      onPressed: () => _showEditUserDialog(context, controller, user),
                    ),
                    if (!isCurrentUser) ...[
                      const SizedBox(height: 6),
                      _buildActionButton(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.red,
                        onPressed: () => _confirmDeleteUser(context, controller, user),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(icon, size: 14, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  void _confirmDeleteUser(
    BuildContext context,
    AdminManageUsersController controller,
    AdminUserModel user,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDarkMode ? Theme.of(context).cardColor : Colors.white,
        title: Text('delete_user'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text('${'confirm_delete_user'.tr} ${user.name}؟', style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () { Get.back(); controller.deleteUser(user.id); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text('delete'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(
    BuildContext context,
    AdminManageUsersController controller,
    AdminUserModel user,
  ) {
    controller.nameController.text = user.name;
    controller.emailController.text = user.email;
    controller.selectedRole.value = (user.role == 'admin' || user.role == 'super_admin') ? 'admin' : 'coordinator';
    _showUserFormDialog(context, controller, isEdit: true, userId: user.id);
  }

  void _showAddUserDialog(
    BuildContext context,
    AdminManageUsersController controller,
  ) {
    _showUserFormDialog(context, controller, isEdit: false);
  }

  void _showUserFormDialog(
    BuildContext context,
    AdminManageUsersController controller, {
    bool isEdit = false,
    String? userId,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      Dialog(
        backgroundColor: isDarkMode ? Theme.of(context).cardColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'edit_user'.tr : 'add_new_user'.tr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 20),
              _buildTextField(context, controller.nameController, 'full_name'.tr, Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _buildTextField(context, controller.emailController, 'email'.tr, Icons.email_outlined),
              if (!isEdit) ...[
                const SizedBox(height: 12),
                _buildTextField(context, controller.passwordController, 'password'.tr, Icons.lock_outline_rounded, isPassword: true),
              ],
              const SizedBox(height: 12),
              Obx(() => _buildDropdown<String>(
                context: context,
                label: 'role'.tr,
                value: controller.selectedRole.value,
                items: [
                  DropdownMenuItem(value: 'admin', child: Text('role_admin'.tr, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87))),
                  DropdownMenuItem(value: 'coordinator', child: Text('role_coordinator'.tr, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87))),
                ],
                onChanged: (val) => controller.selectedRole.value = val!,
              )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isProcessing.value ? null : () => isEdit ? controller.editUser(userId!) : controller.addUser(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: controller.isProcessing.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'save'.tr : 'add'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => controller.clearControllers());
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
        prefixIcon: Icon(icon, size: 18, color: Colors.indigo),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black87),
      dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildSystemControls(
    BuildContext context,
    AdminSettingsController systemCtrl,
  ) {
    return Obx(() {
      if (systemCtrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_rounded, color: Colors.indigo, size: 18),
              const SizedBox(width: 8),
              Text(
                'system_controls'.tr,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.indigo),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSystemControlCard(
            title: 'registration_status'.tr,
            subtitle: systemCtrl.studentRegistrationEnabled.value ? 'registration_open'.tr : 'registration_closed'.tr,
            icon: Icons.app_registration,
            trailing: Transform.scale(
              scale: 0.7,
              child: Switch(
                value: systemCtrl.studentRegistrationEnabled.value,
                onChanged: (val) => systemCtrl.toggleRegistration(val),
                activeColor: Colors.green,
              ),
            ),
          ),
          _buildSystemControlCard(
            title: 'batch_management_mode'.tr,
            subtitle: systemCtrl.batchMode.value == 'student' ? 'student'.tr : 'admin'.tr,
            icon: Icons.layers_outlined,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: systemCtrl.batchMode.value,
                items: [
                  DropdownMenuItem(value: 'student', child: Text('student'.tr, style: const TextStyle(fontSize: 11))),
                  DropdownMenuItem(value: 'admin', child: Text('admin'.tr, style: const TextStyle(fontSize: 11))),
                ],
                onChanged: (val) => systemCtrl.setBatchMode(val),
              ),
            ),
          ),
          if (systemCtrl.batchMode.value == 'admin')
            _buildSystemControlCard(
              title: 'default_batch_num'.tr,
              subtitle: '',
              icon: Icons.numbers,
              trailing: Container(
                width: 50,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
                ),
                child: TextField(
                  controller: systemCtrl.batchController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                  onChanged: (val) {
                    final num = int.tryParse(val);
                    if (num != null) systemCtrl.defaultBatchNumber.value = num;
                  },
                ),
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: systemCtrl.isSaving.value ? null : () => systemCtrl.saveSettings(),
              icon: systemCtrl.isSaving.value
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text('save'.tr, style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSystemControlCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: Colors.indigo, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
