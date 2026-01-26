import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/certificate.dart';
import '../models/personal_details.dart';
import 'template_selection_screen.dart';
import 'references_screen.dart';

class CertificateEntry {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isExpanded = true;

  void dispose() {
    titleController.dispose();
    dateController.dispose();
    descriptionController.dispose();
  }
}

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final List<CertificateEntry> _certificatesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var entry in _certificatesList) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final details = await _dbHelper.getLatestPersonalDetails();
    if (details != null) {
      final certificates = await _dbHelper.getCertificates(details.id!);
      setState(() {
        _certificatesList.clear();
        if (certificates.isNotEmpty) {
          for (var cert in certificates) {
            final entry = CertificateEntry();
            entry.titleController.text = cert.title;
            entry.dateController.text = cert.date;
            entry.descriptionController.text = cert.description;
            entry.isExpanded = false;
            _certificatesList.add(entry);
          }
        } else {
          // Add one empty entry by default if none exist
          _certificatesList.add(CertificateEntry());
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _certificatesList.add(CertificateEntry());
        _isLoading = false;
      });
    }
  }

  void _addEmptyCertificate() {
    setState(() {
      _certificatesList.add(CertificateEntry());
    });
  }

  void _removeCertificate(int index) {
    setState(() {
      _certificatesList.removeAt(index);
      if (_certificatesList.isEmpty) {
        _addEmptyCertificate();
      }
    });
  }

  Future<void> _saveData() async {
    final personalDetails = await _dbHelper.getLatestPersonalDetails();
    if (personalDetails == null) return;

    final certificatesToSave = _certificatesList
        .where((e) => e.titleController.text.isNotEmpty)
        .map((e) {
      return Certificate(
        personalDetailsId: personalDetails.id!,
        title: e.titleController.text,
        date: e.dateController.text,
        description: e.descriptionController.text,
      );
    }).toList();

    await _dbHelper.saveCertificates(personalDetails.id!, certificatesToSave);
  }

  void _applyFormatting(TextEditingController controller, String formatType) {
    final text = controller.text;
    final selection = controller.selection;
    if (selection.start == -1 || selection.end == -1) return;

    final selectedText = text.substring(selection.start, selection.end);
    String newText = '';

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
          'Certificates',
          style:
              TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
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
            icon: const Icon(Icons.remove_red_eye_outlined,
                color: Color(0xFF1F2937), size: 22),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () async {
                await _saveData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Certificates saved successfully!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              child: const Text('Save',
                  style: TextStyle(color: Color(0xFF1F2937))),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '100%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your resume score',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Text(
                            'Completed!',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress bar
                Container(
                  height: 4,
                  width: double.infinity,
                  color: const Color(0xFFF3F4F6),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1.0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF34D399)],
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Certificates',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your certifications to showcase your expertise.',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ...List.generate(_certificatesList.length,
                              (index) => _buildCertificateCard(index)),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _addEmptyCertificate,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              'Add another certificate',
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
                          Row(
                            children: List.generate(8, (index) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == 7
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
                                          const ReferencesScreen()),
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
                              'Next: References',
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

  Widget _buildCertificateCard(int index) {
    final cert = _certificatesList[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => cert.isExpanded = !cert.isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cert.titleController.text.isEmpty
                          ? '(Not specified)'
                          : cert.titleController.text,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Icon(
                      cert.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
                    onPressed: () => _removeCertificate(index),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          if (cert.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildTextField(cert.titleController, 'Certificate Title',
                      'e.g. AWS Certified Solutions Architect'),
                  const SizedBox(height: 16),
                  _buildDateField(
                    controller: cert.dateController,
                    label: 'Date',
                    hint: 'MM / YYYY',
                  ),
                  const SizedBox(height: 16),
                  _buildRichTextField(
                      cert.descriptionController, 'Description'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildDateField(
      {required TextEditingController controller,
      required String label,
      required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF6366F1),
                      onPrimary: Colors.white,
                      onSurface: Color(0xFF1F2937),
                    ),
                  ),
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
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            suffixIcon: Icon(Icons.calendar_today_outlined,
                size: 18, color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildRichTextField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                  color: Color(0xFFF9FAFB),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.format_bold, size: 18),
                          onPressed: () => _applyFormatting(controller, 'bold'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20),
                      const SizedBox(width: 8),
                      IconButton(
                          icon: const Icon(Icons.format_italic, size: 18),
                          onPressed: () =>
                              _applyFormatting(controller, 'italic'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20),
                      const SizedBox(width: 8),
                      IconButton(
                          icon: const Icon(Icons.format_underlined, size: 18),
                          onPressed: () =>
                              _applyFormatting(controller, 'underline'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20),
                      const SizedBox(width: 8),
                      IconButton(
                          icon: const Icon(Icons.strikethrough_s, size: 18),
                          onPressed: () =>
                              _applyFormatting(controller, 'strike'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20),
                      const SizedBox(width: 8),
                      Container(
                          width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                      const SizedBox(width: 8),
                      IconButton(
                          icon:
                              const Icon(Icons.format_list_bulleted, size: 18),
                          onPressed: () =>
                              _applyFormatting(controller, 'bullet'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20),
                      const SizedBox(width: 8),
                      IconButton(
                          icon:
                              const Icon(Icons.format_list_numbered, size: 18),
                          onPressed: () =>
                              _applyFormatting(controller, 'number'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20),
                    ],
                  ),
                ),
              ),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe your certificate...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
