import 'package:flutter/material.dart'; // استيراد حزمة فلاتر الأساسية لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import '../../models/admin_models.dart'; // استيراد نماذج بيانات الأدمن (المعلمين والطلاب)
import '../../controller/applicants/applicants_controller.dart'; // استيراد متحكم المتقدمين للوصول إلى البيانات
import 'widgets/applicant_details_dialog.dart'; // استيراد ويدجت نافذة تفاصيل المتقدم

// شاشة طلبات الطلاب المتقدمين - StudentApplicantsScreen
class StudentApplicantsScreen extends StatelessWidget {
  const StudentApplicantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ApplicantsController>()
        ? Get.find<ApplicantsController>()
        : Get.put(ApplicantsController());

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.greenAccent.withValues(alpha: 0.3),
            child: Obx(
              () => TabBar(
                tabs: [
                  Tab(text: '${'male'.tr} (${controller.studentMaleCount})'),
                  Tab(text: '${'female'.tr} (${controller.studentFemaleCount})'),
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.green,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFilteredList(controller, Gender.male),
                _buildFilteredList(controller, Gender.female),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredList(ApplicantsController controller, Gender gender) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final list = controller.filteredStudentApplicants(gender);

            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'no_data'.tr,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                int crossAxisCount = 3;
                double aspectRatio = 2.7;

                if (width < 1100) {
                  crossAxisCount = 2;
                  aspectRatio = 2.6;
                } else {
                  crossAxisCount = 4;
                  aspectRatio = 2.6;
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Card(
                      elevation: 0, // تقليل الظل لاستخدام الحدود كعنصر أساسي
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        // إضافة حدود واضحة ومتجاوبة مع الثيم
                        side: BorderSide(
                          color: isDarkMode 
                              ? Colors.white
                              : Colors.green,
                          width: 1.5,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Get.dialog(
                            ApplicantDetailsDialog(
                              applicant: item,
                              isTeacher: false,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                                    child: const Icon(
                                      Icons.school,
                                      size: 24,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Icon(
                                      item.gender == Gender.male
                                          ? Icons.male
                                          : Icons.female,
                                      size: 14,
                                      color: item.gender == Gender.male
                                          ? Colors.blue
                                          : Colors.pink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      item.level.tr,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.isDistributed)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'distributed'.tr,
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
