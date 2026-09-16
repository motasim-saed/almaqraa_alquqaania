import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/admin_models.dart';
import '../../repository/admin_repository.dart';
import '../../repository/supabase_admin_repository.dart';
import 'package:intl/intl.dart';

class StudentLeaveManagementScreen extends StatefulWidget {
  const StudentLeaveManagementScreen({super.key});

  @override
  State<StudentLeaveManagementScreen> createState() =>
      _StudentLeaveManagementScreenState();
}

class _StudentLeaveManagementScreenState
    extends State<StudentLeaveManagementScreen> {
  final AdminRepository _repository = SupabaseAdminRepository();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  List<StudentModel> _students = [];
  List<StudentModel> _filteredStudents = [];
  StudentModel? _selectedStudent;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  Gender _selectedGender = Gender.all;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final list = await _repository.getStudents(status: 'accepted');
      if (mounted) {
        setState(() {
          _students = list;
          _applyFilters();
        });
      }
    } catch (e) {
      Get.snackbar('error'.tr, '${'failed_load_students'.tr}: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _students.where((s) {
        final nameMatch = s.name.toLowerCase().contains(query);
        final genderMatch = _selectedGender == Gender.all || s.gender == _selectedGender;
        return nameMatch && genderMatch;
      }).toList();
    });
  }

  Future<void> _submit() async {
    if (_selectedStudent == null ||
        _startDate == null ||
        _endDate == null ||
        _reasonController.text.isEmpty) {
      Get.snackbar('alert'.tr, 'complete_all_fields'.tr,
          backgroundColor: Colors.orangeAccent, colorText: Colors.white);
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final success = await _repository.assignStudentLeave(
        studentId: _selectedStudent!.id,
        startDate: _startDate!,
        endDate: _endDate!,
        reason: _reasonController.text.trim(),
      );

      if (success) {
        try {
          final chatId = await _repository.getOrCreateChat(_selectedStudent!.id, 'student');
          if (chatId != null) {
            final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
            final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);
            String msg = 'السلام عليكم،\nتم تسجيل استئذان لك من تاريخ $startStr إلى تاريخ $endStr.\n';
            final reason = _reasonController.text.trim();
            if (reason.isNotEmpty) {
              msg += 'السبب: $reason';
            }
            await _repository.sendMessage(chatId, 'admin', msg);
          }
        } catch (e) {
        }

        if (mounted) {
          Get.back();
          Get.snackbar('success'.tr, 'leave_recorded_msg'.tr,
              backgroundColor: Colors.green, colorText: Colors.white);
        }
      } else {
        Get.snackbar('error'.tr, 'save_failed_msg'.tr,
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('error'.tr, '${'error_occurred'.tr}: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isMobile = !kIsWeb && MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8F9FD),
      appBar: isMobile ? AppBar(
        title: Text('student_leave_management'.tr, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: theme.primaryColor,
        centerTitle: true,
        elevation: 0,
      ) : null,

      body: _isLoading && _students.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'step_1_choose_student'.tr,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo', color: theme.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(Gender.all, 'all'.tr),
                          const SizedBox(width: 8),
                          _buildFilterChip(Gender.male, 'male'.tr),
                          const SizedBox(width: 8),
                          _buildFilterChip(Gender.female, 'female'.tr),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _searchController,
                      style: TextStyle(fontFamily: 'Cairo', color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: 'search_student_hint'.tr,
                        hintStyle: TextStyle(color: theme.hintColor),
                        prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                        filled: true,
                        fillColor: theme.cardColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: theme.primaryColor, width: 2),
                        ),
                      ),
                      onChanged: (val) => _applyFilters(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? theme.dividerColor : theme.dividerColor.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView.separated(
                          itemCount: _filteredStudents.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.05)),
                          itemBuilder: (context, index) {
                            final s = _filteredStudents[index];
                            final isSelected = _selectedStudent?.id == s.id;
                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: theme.primaryColor.withValues(alpha: 0.1),
                              title: Text(s.name, style: TextStyle(fontSize: 14, fontFamily: 'Cairo', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              subtitle: Text(s.academicNumber, style: TextStyle(fontSize: 12, color: theme.hintColor)),
                              trailing: isSelected ? Icon(Icons.check_circle, color: theme.primaryColor) : null,
                              onTap: () => setState(() => _selectedStudent = s),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'step_2_select_period'.tr,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo', color: theme.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                                builder: (context, child) => Theme(data: isDark ? ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: theme.primaryColor, onPrimary: Colors.white, surface: theme.cardColor, onSurface: Colors.white)) : theme, child: child!)
                              );
                              if (date != null && mounted) setState(() => _startDate = date);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              // تمييز خلفية الزر عند الاختيار
                              backgroundColor: _startDate != null ? theme.primaryColor.withValues(alpha: 0.08) : Colors.transparent,
                              side: BorderSide(color: _startDate != null ? theme.primaryColor : theme.dividerColor, width: _startDate != null ? 1.8 : 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: Icon(Icons.calendar_today, size: 18, color: _startDate != null ? theme.primaryColor : theme.hintColor),
                            label: Text(
                              _startDate == null ? 'start_date_label'.tr : DateFormat('yyyy-MM-dd').format(_startDate!),
                              style: TextStyle(
                                fontSize: 12, 
                                fontFamily: 'Cairo', 
                                color: _startDate != null ? theme.primaryColor : theme.hintColor,
                                fontWeight: _startDate != null ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: _startDate ?? DateTime.now(),
                                lastDate: DateTime(2100),
                                builder: (context, child) => Theme(data: isDark ? ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: theme.primaryColor, onPrimary: Colors.white, surface: theme.cardColor, onSurface: Colors.white)) : theme, child: child!)
                              );
                              if (date != null && mounted) setState(() => _endDate = date);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              // تمييز خلفية الزر عند الاختيار
                              backgroundColor: _endDate != null ? theme.primaryColor.withValues(alpha: 0.08) : Colors.transparent,
                              side: BorderSide(color: _endDate != null ? theme.primaryColor : theme.dividerColor, width: _endDate != null ? 1.8 : 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: Icon(Icons.calendar_month, size: 18, color: _endDate != null ? theme.primaryColor : theme.hintColor),
                            label: Text(
                              _endDate == null ? 'end_date_label'.tr : DateFormat('yyyy-MM-dd').format(_endDate!),
                              style: TextStyle(
                                fontSize: 12, 
                                fontFamily: 'Cairo', 
                                color: _endDate != null ? theme.primaryColor : theme.hintColor,
                                fontWeight: _endDate != null ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'step_3_reason_detail'.tr,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo', color: theme.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      style: TextStyle(fontFamily: 'Cairo', color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: 'reason_hint'.tr,
                        hintStyle: TextStyle(color: theme.hintColor),
                        filled: true,
                        fillColor: theme.cardColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: theme.primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: isDark ? 6 : 4,
                          shadowColor: theme.primaryColor.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            // تمييز الزر بإطار خفيف في الثيم الغامق
                            side: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.05)),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                            : Text(
                                'save_leave_button'.tr,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterChip(Gender gender, String label) {
    final theme = Theme.of(context);
    final bool isSelected = _selectedGender == gender;
    return FilterChip(
      label: Text(
        label, 
        style: TextStyle(
          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color, 
          fontFamily: 'Cairo', 
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedGender = gender;
          _applyFilters();
        });
      },
      selectedColor: theme.primaryColor,
      backgroundColor: theme.cardColor,
      checkmarkColor: Colors.white,
      elevation: isSelected ? 4 : 0,
      pressElevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), 
        side: BorderSide(color: isSelected ? theme.primaryColor : theme.dividerColor)
      ),
    );
  }
}
