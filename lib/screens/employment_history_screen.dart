import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../database/database_helper.dart';
import '../models/work_experience.dart';
import 'template_selection_screen.dart';
import 'education_history_screen.dart';

class WorkExperienceEntry {
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController employerController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController cityStateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isCurrent = false;
  bool isExpanded = true;

  void dispose() {
    jobTitleController.dispose();
    employerController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    cityStateController.dispose();
    descriptionController.dispose();
  }
}

class EmploymentHistoryScreen extends StatefulWidget {
  final String? cvId;
  const EmploymentHistoryScreen({super.key, this.cvId});

  @override
  State<EmploymentHistoryScreen> createState() =>
      _EmploymentHistoryScreenState();
}

class _EmploymentHistoryScreenState extends State<EmploymentHistoryScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _apiClient = ApiClient();
  final List<WorkExperienceEntry> _experiences = [];
  bool _isLoading = true;
  bool _isSavingRemote = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final personalDetails = await _dbHelper.getLatestPersonalDetails();
    if (personalDetails != null) {
      final experiences =
          await _dbHelper.getWorkExperiences(personalDetails.id!);
      if (experiences.isNotEmpty) {
        setState(() {
          _experiences.clear();
          for (var exp in experiences) {
            final entry = WorkExperienceEntry();
            entry.jobTitleController.text = exp.jobTitle;
            entry.employerController.text = exp.employer;
            entry.startDateController.text = exp.startDate;
            entry.endDateController.text = exp.endDate ?? '';
            entry.isCurrent = exp.isCurrent;
            entry.cityStateController.text = exp.cityState;
            entry.descriptionController.text = exp.description ?? '';
            _experiences.add(entry);
          }
        });
      } else {
        _addEmptyExperience();
      }
    } else {
      _addEmptyExperience();
    }
    setState(() => _isLoading = false);
  }

  void _addEmptyExperience() {
    setState(() {
      _experiences.add(WorkExperienceEntry());
    });
  }

  Future<bool> _saveData() async {
    final personalDetails = await _dbHelper.getLatestPersonalDetails();
    if (personalDetails == null) return false;

    final experiencesToSave = _experiences
        .where((e) => e.jobTitleController.text.isNotEmpty)
        .map((e) {
      return WorkExperience(
        personalDetailsId: personalDetails.id!,
        jobTitle: e.jobTitleController.text,
        employer: e.employerController.text,
        startDate: e.startDateController.text,
        endDate: e.isCurrent ? 'Present' : e.endDateController.text,
        isCurrent: e.isCurrent,
        cityState: e.cityStateController.text,
        description: e.descriptionController.text,
      );
    }).toList();

    await _dbHelper.saveWorkExperiences(personalDetails.id!, experiencesToSave);

    // Get active CV ID from widget or SharedPreferences
    String? activeCvId = widget.cvId;
    if (activeCvId == null) {
      final prefs = await SharedPreferences.getInstance();
      activeCvId = prefs.getString('active_cv_id');
    }

    // Remote Sync
    debugPrint('🔍 [DEBUG] CV ID check: $activeCvId');
    if (activeCvId != null) {
      final success = await _saveRemoteExperiences(activeCvId);
      return success;
    }
    return true; // Local success only
  }

  Future<bool> _saveRemoteExperiences(String activeCvId) async {
    if (_isSavingRemote) return false;
    setState(() => _isSavingRemote = true);
    bool allSuccess = true;

    try {
      for (var entry in _experiences) {
        if (entry.jobTitleController.text.isEmpty) continue;

        // Convert MM / YYYY to YYYY-MM-DD
        String formatApiDate(String date) {
          if (date.isEmpty || date == 'Present') return '';
          try {
            final parts = date.split(' / ');
            if (parts.length == 2) {
              return "${parts[1]}-${parts[0]}-01";
            }
          } catch (_) {}
          return "";
        }

        List<String> descriptionList = entry.descriptionController.text
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.replaceAll('•', '').trim())
            .toList();

        final data = {
          "cv": activeCvId,
          "job_title": entry.jobTitleController.text,
          "employer": entry.employerController.text,
          "start_date": formatApiDate(entry.startDateController.text),
          "end_date": entry.isCurrent
              ? null
              : formatApiDate(entry.endDateController.text),
          "is_current": entry.isCurrent,
          "city_state": entry.cityStateController.text,
          "description": descriptionList,
        };

        final response = await _apiClient.dio.post(
          'api/work-experiences/',
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        if (response.statusCode != 201 && response.statusCode != 200) {
          allSuccess = false;
        }
      }
      debugPrint('✅ [SYNC] Work experiences sync status: $allSuccess');
      return allSuccess;
    } catch (e) {
      debugPrint('❌ [SYNC] Error syncing work experiences: $e');
      return false;
    } finally {
      if (mounted) setState(() => _isSavingRemote = false);
    }
  }

  void _removeExperience(int index) {
    setState(() {
      _experiences.removeAt(index);
      if (_experiences.isEmpty) {
        _addEmptyExperience();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _saveData();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplateSelectionScreen(),
                  ),
                );
              }
            },
            tooltip: 'Preview CV',
            icon: const Icon(
              Icons.remove_red_eye_outlined,
              color: Color(0xFF1F2937),
              size: 22,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () async {
                final isSuccess = await _saveData();
                if (mounted) {
                  String message = 'Employment history saved!';
                  Color bgColor = const Color(0xFF10B981); // Green

                  if (widget.cvId == null) {
                    message += ' (Saved locally - No CV ID)';
                    bgColor = Colors.orange;
                  } else if (isSuccess) {
                    message += ' (Synced to cloud)';
                  } else {
                    message += ' (Sync failed check logs)';
                    bgColor = Colors.red;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: bgColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '19%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Your resume score',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              '+25%',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Add employment history',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress bar
                Container(
                  height: 4,
                  color: const Color(0xFFF3F4F6),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.19,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Employment History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Show your relevant experience (last 10 years). Use bullet points to note your achievements, if possible - use numbers/facts (Achieved X, measured by Y, by doing Z).',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Experience entries
                          ...List.generate(_experiences.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildExperienceCard(index),
                            );
                          }),

                          // Add another experience button
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _addEmptyExperience,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              'Add another experience',
                              style: TextStyle(fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom navigation
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: List.generate(5, (index) {
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: index == 1
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFFE5E7EB),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              await _saveData();
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const EducationHistoryScreen()),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Next: Education',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExperienceCard(int index) {
    final experience = _experiences[index];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                experience.isExpanded = !experience.isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.drag_indicator,
                    color: Colors.grey[400],
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      experience.jobTitleController.text.isEmpty
                          ? '(Not specified)'
                          : experience.jobTitleController.text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Icon(
                    experience.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
                    onPressed: () => _removeExperience(index),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (experience.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Job title and Employer
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: 'Job title',
                          controller: experience.jobTitleController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: 'Employer',
                          controller: experience.employerController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Start & End Date and City, State
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Start & End Date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Colors.blue[400],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    controller: experience.startDateController,
                                    hint: 'MM / YYYY',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDateField(
                                    controller: experience.endDateController,
                                    hint: experience.isCurrent
                                        ? 'Present'
                                        : 'MM / YYYY',
                                    enabled: !experience.isCurrent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Present Checkbox
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: experience.isCurrent,
                                    activeColor: const Color(0xFF6366F1),
                                    onChanged: (value) {
                                      setState(() {
                                        experience.isCurrent = value ?? false;
                                        if (experience.isCurrent) {
                                          experience.endDateController.text =
                                              'Present';
                                        } else {
                                          experience.endDateController.text =
                                              '';
                                        }
                                      });
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      experience.isCurrent =
                                          !experience.isCurrent;
                                      if (experience.isCurrent) {
                                        experience.endDateController.text =
                                            'Present';
                                      } else {
                                        experience.endDateController.text = '';
                                      }
                                    });
                                  },
                                  child: Text(
                                    'Currently work here',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: 'City, State',
                          controller: experience.cityStateController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRichTextEditor(experience),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      readOnly: true, // Prevent keyboard from showing
      enabled: enabled,
      onTap: enabled
          ? () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1950),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF6366F1), // Indigo
                        onPrimary: Colors.white,
                        onSurface: Color(0xFF1F2937),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                // Format as MM / YYYY
                final formatted =
                    "${picked.month.toString().padLeft(2, '0')} / ${picked.year}";
                controller.text = formatted;
                setState(() {});
              }
            }
          : null,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 13,
        ),
        suffixIcon: Icon(
          Icons.calendar_today_outlined,
          size: 16,
          color: Colors.grey[400],
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildRichTextEditor(WorkExperienceEntry experience) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // ... Bold, Italic etc (can be active too but focus on list for now)
                  _buildToolbarButton(
                    Icons.format_bold,
                    'Bold',
                    onPressed: () => _applyFormatting(
                        experience.descriptionController, 'bold'),
                  ),
                  _buildToolbarButton(
                    Icons.format_italic,
                    'Italic',
                    onPressed: () => _applyFormatting(
                        experience.descriptionController, 'italic'),
                  ),
                  _buildToolbarButton(
                    Icons.format_underlined,
                    'Underline',
                    onPressed: () => _applyFormatting(
                        experience.descriptionController, 'underline'),
                  ),
                  _buildToolbarButton(
                    Icons.format_list_bulleted,
                    'Bullet list',
                    isActive: _isFormatActive(
                        experience.descriptionController, 'bullet'),
                    onPressed: () => _applyFormatting(
                        experience.descriptionController, 'bullet'),
                  ),
                  _buildToolbarButton(
                    Icons.format_list_numbered,
                    'Numbered list',
                    isActive: _isFormatActive(
                        experience.descriptionController, 'number'),
                    onPressed: () => _applyFormatting(
                        experience.descriptionController, 'number'),
                  ),
                  // ... shortened for brevity, keep others standard
                ],
              ),
            ),
          ),

          // Text field
          TextField(
            controller: experience.descriptionController,
            maxLines: 6,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText:
                  'e.g. Created and implemented lesson plans based on child-led interests and curiosities.',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _handleTextChange(experience.descriptionController, value);
            },
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Recruiter tip: write 200+ characters to increase interview chances',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${experience.descriptionController.text.length} / 200+',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _applyFormatting(TextEditingController controller, String type) {
    final text = controller.text;
    final selection = controller.selection;

    if (selection.baseOffset == -1) return;

    if (type == 'bullet' || type == 'number') {
      // 1. Expand selection to cover full lines
      int start = selection.start;
      if (start > 0) {
        int lastNewline = text.lastIndexOf('\n', start - 1);
        start = lastNewline == -1 ? 0 : lastNewline + 1;
      }

      int end = selection.end;
      int nextNewline = text.indexOf('\n', end);
      if (nextNewline == -1) {
        end = text.length;
      } else {
        end = nextNewline;
      }

      String leftPart = text.substring(0, start);
      String linesPart = text.substring(start, end);
      String rightPart = text.substring(end);

      List<String> lines = linesPart.split('\n');
      bool allHaveFormat = true;

      // 2. Check if currently formatted
      if (type == 'bullet') {
        for (var line in lines) {
          if (line.trim().isNotEmpty && !line.trim().startsWith('•')) {
            allHaveFormat = false;
            break;
          }
        }
      } else {
        // number
        // lenient check for "1. ", "2. " etc
        final regex = RegExp(r'^\d+\.\s');
        for (var line in lines) {
          if (line.trim().isNotEmpty && !regex.hasMatch(line.trim())) {
            allHaveFormat = false;
            break;
          }
        }
      }

      String formattedLines;

      // 3. Toggle Logic
      if (allHaveFormat) {
        // Remove formatting
        formattedLines = lines.map((line) {
          if (type == 'bullet') {
            return line.replaceFirst(RegExp(r'^\s*•\s*'), '');
          } else {
            return line.replaceFirst(RegExp(r'^\s*\d+\.\s*'), '');
          }
        }).join('\n');
      } else {
        // Add formatting
        if (type == 'bullet') {
          formattedLines = lines.map((line) {
            String trimmed = line.trim();
            if (trimmed.startsWith('•')) return line; // Keep existing
            return '• $line';
          }).join('\n');
        } else {
          int count = 1;
          formattedLines = lines.map((line) {
            String trimmed = line.trim();
            if (RegExp(r'^\d+\.\s').hasMatch(trimmed))
              return line; // Keep existing
            return '${count++}. $line';
          }).join('\n');
        }
      }

      String newText = '$leftPart$formattedLines$rightPart';

      // 4. Update Controller
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection(
          baseOffset: start,
          extentOffset: start + formattedLines.length,
        ),
      );
      setState(() {});
      return;
    }

    // Default formatting (Bold, Italic, etc.) stays the same...
    String leftPart = text.substring(0, selection.start);
    String selectedPart = text.substring(selection.start, selection.end);
    String rightPart = text.substring(selection.end);

    String newText;
    int newSelectionStart;
    int newSelectionEnd;

    switch (type) {
      case 'bold':
        newText = '$leftPart**$selectedPart**$rightPart';
        newSelectionStart = selection.start + 2;
        newSelectionEnd = selection.end + 2;
        break;
      case 'italic':
        newText = '$leftPart*$selectedPart*$rightPart';
        newSelectionStart = selection.start + 1;
        newSelectionEnd = selection.end + 1;
        break;
      case 'underline':
        newText = '$leftPart<u>$selectedPart</u>$rightPart';
        newSelectionStart = selection.start + 3;
        newSelectionEnd = selection.end + 3;
        break;
      case 'strike':
        newText = '$leftPart~~$selectedPart~~$rightPart';
        newSelectionStart = selection.start + 2;
        newSelectionEnd = selection.end + 2;
        break;
      default:
        return;
    }

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: newSelectionStart,
        extentOffset: newSelectionEnd,
      ),
    );
    setState(() {});
  }

  bool _isFormatActive(TextEditingController controller, String type) {
    if (controller.selection.baseOffset == -1) return false;
    final text = controller.text;
    final selection = controller.selection;

    // Find current line
    int start = selection.start;
    if (start > 0) {
      int lastNewline = text.lastIndexOf('\n', start - 1);
      start = lastNewline == -1 ? 0 : lastNewline + 1;
    }
    int end = text.indexOf('\n', selection.end);
    if (end == -1) end = text.length;

    String line = text.substring(start, end).trim();

    if (type == 'bullet') return line.startsWith('•');
    if (type == 'number') return RegExp(r'^\d+\.').hasMatch(line);

    return false;
  }

  void _handleTextChange(TextEditingController controller, String value) {
    // 1. Detect Enter key
    final selection = controller.selection;
    if (selection.baseOffset <= 0) {
      setState(() {});
      return;
    }

    // Check if the character just before cursor is newline
    // But value is the NEW text.
    // If the user typed Enter, the char at selection.start - 1 should be \n
    if (selection.start > 0 && value[selection.start - 1] == '\n') {
      // Find previous line
      int currentPos = selection.start - 1;
      int prevLineEnd = currentPos;
      int prevLineStart = value.lastIndexOf('\n', prevLineEnd - 1);
      prevLineStart = prevLineStart == -1 ? 0 : prevLineStart + 1;

      String prevLine = value.substring(prevLineStart, prevLineEnd).trim();

      String prefix = '';
      if (prevLine.startsWith('•')) {
        prefix = '• ';
      } else {
        final match = RegExp(r'^(\d+)\.').firstMatch(prevLine);
        if (match != null) {
          int num = int.parse(match.group(1)!);
          prefix = '${num + 1}. ';
        }
      }

      if (prefix.isNotEmpty) {
        // Insert prefix
        String newText =
            value.replaceRange(selection.start, selection.end, prefix);
        controller.value = TextEditingValue(
          text: newText,
          selection:
              TextSelection.collapsed(offset: selection.start + prefix.length),
        );
      }
    }
    setState(() {});
  }

  Widget _buildToolbarButton(IconData icon, String tooltip,
      {VoidCallback? onPressed, bool isActive = false}) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      tooltip: tooltip,
      color: isActive ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
      style: isActive
          ? IconButton.styleFrom(backgroundColor: const Color(0xFFE0E7FF))
          : null,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
