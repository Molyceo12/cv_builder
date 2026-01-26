import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/education.dart';
import 'template_selection_screen.dart';
import 'skills_screen.dart';

class EducationEntry {
  final TextEditingController schoolController = TextEditingController();
  final TextEditingController degreeController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController cityStateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isCurrent = false;
  bool isExpanded = true;

  void dispose() {
    schoolController.dispose();
    degreeController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    cityStateController.dispose();
    descriptionController.dispose();
  }
}

class EducationHistoryScreen extends StatefulWidget {
  const EducationHistoryScreen({super.key});

  @override
  State<EducationHistoryScreen> createState() => _EducationHistoryScreenState();
}

class _EducationHistoryScreenState extends State<EducationHistoryScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final List<EducationEntry> _educationList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final personalDetails = await _dbHelper.getLatestPersonalDetails();
    if (personalDetails != null) {
      final educationList = await _dbHelper.getEducation(personalDetails.id!);
      setState(() {
        _educationList.clear();
        if (educationList.isNotEmpty) {
          for (var edu in educationList) {
            final entry = EducationEntry();
            entry.schoolController.text = edu.school;
            entry.degreeController.text = edu.degree;
            entry.startDateController.text = edu.startDate;
            entry.endDateController.text = edu.endDate ?? '';
            entry.isCurrent = edu.isCurrent;
            entry.cityStateController.text = edu.cityState;
            entry.descriptionController.text = edu.description ?? '';
            _educationList.add(entry);
          }
        } else {
          _educationList.add(EducationEntry());
        }
      });
    } else {
      setState(() {
        _educationList.add(EducationEntry());
      });
    }
    setState(() => _isLoading = false);
  }

  void _addEmptyEducation() {
    setState(() {
      _educationList.add(EducationEntry());
    });
  }

  Future<void> _saveData() async {
    final personalDetails = await _dbHelper.getLatestPersonalDetails();
    if (personalDetails == null) return;

    final educationToSave = _educationList
        .where((e) => e.schoolController.text.isNotEmpty)
        .map((e) {
      return Education(
        personalDetailsId: personalDetails.id!,
        school: e.schoolController.text,
        degree: e.degreeController.text,
        startDate: e.startDateController.text,
        endDate: e.isCurrent ? 'Present' : e.endDateController.text,
        isCurrent: e.isCurrent,
        cityState: e.cityStateController.text,
        description: e.descriptionController.text,
      );
    }).toList();

    await _dbHelper.saveEducation(personalDetails.id!, educationToSave);
  }

  void _removeEducation(int index) {
    setState(() {
      _educationList.removeAt(index);
      if (_educationList.isEmpty) {
        _addEmptyEducation();
      }
    });
  }

  // Formatting helper (simplified)
  void _applyFormatting(TextEditingController controller, String formatType) {
    final text = controller.text;
    final selection = controller.selection;
    if (selection.start == -1 || selection.end == -1) return;

    final selectedText = text.substring(selection.start, selection.end);
    String newText = '';

    // Basic Markdown injection
    switch (formatType) {
      case 'bold':
        newText = '**$selectedText**';
        break;
      case 'italic':
        newText = '*$selectedText*';
        break;
      case 'underline':
        newText = '<u>$selectedText</u>';
        break;
      case 'strike':
        newText = '~~$selectedText~~';
        break;
      case 'bullet':
        newText = '\n• $selectedText';
        break;
      case 'number':
        newText = '\n1. $selectedText';
        break;
      default:
        return;
    }

    final newValue = text.replaceRange(selection.start, selection.end, newText);
    controller.value = TextEditingValue(
      text: newValue,
      selection:
          TextSelection.collapsed(offset: selection.start + newText.length),
    );
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
        title: const Text(
          'Education',
          style:
              TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.visibility_outlined, color: Color(0xFF6B7280)),
            onPressed: () async {
              await _saveData();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TemplateSelectionScreen()),
                );
              }
            },
            tooltip: 'Preview CV',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () async {
                await _saveData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Education history saved successfully!'),
                      backgroundColor: Color(0xFF10B981),
                      duration: Duration(seconds: 2),
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
                                '45%',
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
                      const Flexible(
                        child: Text(
                          '+15% Add education',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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
                    widthFactor: 0.45,
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
                            'Education',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'A varied education on your resume sums up the value that your learnings and background will bring to job.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Education entries
                          ...List.generate(_educationList.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildEducationCard(index),
                            );
                          }),

                          // Add button
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _addEmptyEducation,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              'Add one more education',
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

                // Bottom Nav
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
                          // Dots indicator
                          Row(
                            children: List.generate(5, (index) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == 2
                                      ? const Color(0xFF6366F1)
                                      : const Color(0xFFE5E7EB),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
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
                                          const SkillsScreen()),
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
                            ),
                            child: const Text(
                              'Next: Skills',
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

  Widget _buildEducationCard(int index) {
    final education = _educationList[index];

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
                education.isExpanded = !education.isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator, color: Colors.grey[400], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      education.schoolController.text.isEmpty
                          ? '(Not specified)'
                          : education.schoolController.text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Icon(
                    education.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
                    onPressed: () => _removeEducation(index),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (education.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: 'School',
                    controller: education.schoolController,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: 'Degree',
                    controller: education.degreeController,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: 'City',
                    controller: education.cityStateController,
                  ),
                  const SizedBox(height: 16),

                  // Dates
                  Column(
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
                          Icon(Icons.info_outline,
                              size: 14, color: Colors.blue[400]),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              controller: education.startDateController,
                              hint: 'MM / YYYY',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDateField(
                              controller: education.endDateController,
                              hint:
                                  education.isCurrent ? 'Present' : 'MM / YYYY',
                              enabled: !education.isCurrent,
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
                              value: education.isCurrent,
                              activeColor: const Color(0xFF6366F1),
                              onChanged: (value) {
                                setState(() {
                                  education.isCurrent = value ?? false;
                                  if (education.isCurrent) {
                                    education.endDateController.text =
                                        'Present';
                                  } else {
                                    education.endDateController.text = '';
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
                                education.isCurrent = !education.isCurrent;
                                if (education.isCurrent) {
                                  education.endDateController.text = 'Present';
                                } else {
                                  education.endDateController.text = '';
                                }
                              });
                            },
                            child: Text(
                              'Currently study here',
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
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      // Just re-using the rich editor builder from a helper would be nice, but I'll inline a simplified one here
                      _buildRichTextEditorWidget(education),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormField(
      {required String label, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600),
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

  Widget _buildDateField(
      {required TextEditingController controller,
      required String hint,
      bool enabled = true}) {
    return TextField(
      controller: controller,
      readOnly: true,
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
                            primary: Color(0xFF6366F1),
                            onPrimary: Colors.white,
                            onSurface: Color(0xFF1F2937))),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
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
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        suffixIcon: Icon(Icons.calendar_today_outlined,
            size: 16, color: Colors.grey[400]),
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

  // Simplified Rich Text Editor widget
  Widget _buildRichTextEditorWidget(EducationEntry education) {
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
                    bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.format_bold, size: 18),
                      onPressed: () => _applyFormatting(
                          education.descriptionController, 'bold'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.format_italic, size: 18),
                      onPressed: () => _applyFormatting(
                          education.descriptionController, 'italic'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.format_underlined, size: 18),
                      onPressed: () => _applyFormatting(
                          education.descriptionController, 'underline'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.strikethrough_s, size: 18),
                      onPressed: () => _applyFormatting(
                          education.descriptionController, 'strike'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  Container(
                      width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.format_list_bulleted, size: 18),
                      onPressed: () => _applyFormatting(
                          education.descriptionController, 'bullet'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.format_list_numbered, size: 18),
                      onPressed: () => _applyFormatting(
                          education.descriptionController, 'number'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  Container(
                      width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.link, size: 18),
                      onPressed: () {}, // Link functionality
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.format_color_text, size: 18),
                      onPressed: () {}, // Color functionality
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  IconButton(
                      icon: const Icon(Icons.format_paint, size: 18),
                      onPressed: () {}, // Highlight/Marker functionality
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.auto_awesome, size: 14),
                    label:
                        const Text('Get help', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  )
                ],
              ),
            ),
          ),
          TextField(
            controller: education.descriptionController,
            maxLines: 4,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'e.g. Graduated with High Honors.',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (_) => setState(() {}),
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
                  '${education.descriptionController.text.length} / 200+',
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
}
