import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/circle_supervisor_controller.dart';
import '../pages/daily_progress_screen.dart';
import '../../Admin/models/admin_models.dart';

class CircleSupervisorScreen extends StatelessWidget {
  const CircleSupervisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CircleSupervisorController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'متابعة طلاب الحلقة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (controller.circleName.isNotEmpty)
                Text(
                  'حلقة: ${controller.circleName.value}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (!controller.isSupervisor.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ليس لديك صلاحية للإشراف على الحلقة حالياً',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'يتم منح هذه الصلاحية من قبل معلم الحلقة لمتابعة إنجازات الطلاب',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // شريط البحث
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: Theme.of(context).cardColor,
              child: TextField(
                onChanged: controller.search,
                decoration: InputDecoration(
                  hintText: 'البحث عن طالب...',
                  hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              ),
            ),

            // قائمة الطلاب
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.fetchCircleStudents,
                color: Theme.of(context).colorScheme.primary,
                child: controller.filteredStudents.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 70,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                controller.searchQuery.value.isEmpty
                                    ? 'لا يوجد طلاب مسجلين في الحلقة حالياً'
                                    : 'لم يتم العثور على نتائج للبحث',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: controller.filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = controller.filteredStudents[index];
                          return _buildStudentCard(context, student);
                        },
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentModel student) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Get.isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // الانتقال لشاشة سجل الإنجاز اليومي بوضع المراجعة
          Get.to(
            () => Scaffold(
              appBar: AppBar(
                title: Text(
                  'إنجاز: ${student.name}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                elevation: 0,
              ),
              body: DailyProgressScreen(
                studentId: student.id,
                isTeacherMode: true, // تفعيل إمكانية المراجعة والاعتماد / الرفض
                showStats: true,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // صورة / أيقونة الطالب
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: student.avatarUrl != null && student.avatarUrl!.isNotEmpty
                    ? NetworkImage(student.avatarUrl!)
                    : null,
                child: student.avatarUrl == null || student.avatarUrl!.isEmpty
                    ? Text(
                        student.name.isNotEmpty ? student.name[0] : 'ط',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // معلومات الطالب
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (student.level.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              student.level,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (student.email.isNotEmpty)
                          Text(
                            student.email,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontFamily: 'Cairo',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // زر الانتقال
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'متابعة',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
