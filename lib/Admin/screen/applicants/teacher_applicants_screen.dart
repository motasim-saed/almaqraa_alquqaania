import 'package:flutter/material.dart'; // استيراد حزمة فلاتر الأساسية لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import '../../models/admin_models.dart'; // استيراد نماذج بيانات الأدمن (المعلمين والطلاب)
import '../../controller/applicants/applicants_controller.dart'; // استيراد متحكم المتقدمين للوصول إلى البيانات والعمليات
import 'widgets/applicant_details_dialog.dart'; // استيراد ويدجت نافذة تفاصيل المتقدم

// شاشة طلبات المعلمين المتقدمين - TeacherApplicantsScreen
class TeacherApplicantsScreen extends StatelessWidget {
  const TeacherApplicantsScreen({super.key});

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
            color: Colors.indigo[400],
            child: Obx(
              () => TabBar(
                tabs: [
                  Tab(text: '${'male'.tr} (${controller.teacherMaleCount})'),
                  Tab(text: '${'female'.tr} (${controller.teacherFemaleCount})'),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
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

            final list = controller.filteredTeacherApplicants(gender);

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
                      elevation: 0,
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        // إضافة حدود واضحة متناسقة مع لون الشاشة النيلي
                        side: BorderSide(
                          color: isDarkMode 
                              ? Colors.white
                              : Colors.indigo,
                          width: 1.5,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Get.dialog(
                            ApplicantDetailsDialog(
                              applicant: item,
                              isTeacher: true,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                                    child: const Icon(
                                      Icons.person,
                                      size: 24,
                                      color: Colors.indigo,
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
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
                                    const SizedBox(height: 2),
                                    _buildInfoItem(Icons.star_outline, item.specialization),
                                    const SizedBox(height: 2),
                                    _buildInfoItem(Icons.email_outlined, item.email),
                                    const Spacer(),
                                    if (!item.canCoverBalance)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'needs_sponsorship'.tr,
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
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

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
