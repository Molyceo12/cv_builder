import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/personal_details.dart';
import 'template_selection_screen.dart';
import 'projects_screen.dart';

class ProfessionalSummaryScreen extends StatefulWidget {
  const ProfessionalSummaryScreen({super.key});

  @override
  State<ProfessionalSummaryScreen> createState() =>
      _ProfessionalSummaryScreenState();
}

class _ProfessionalSummaryScreenState extends State<ProfessionalSummaryScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _summaryController = TextEditingController();
  PersonalDetails? _personalDetails;
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _lastSaveTime;

  @override
  void initState() {
    super.initState();
    _loadData();
    _summaryController.addListener(_onSummaryChanged);
  }

  @override
  void dispose() {
    _summaryController.removeListener(_onSummaryChanged);
    _summaryController.dispose();
    super.dispose();
  }

  void _onSummaryChanged() {
    _triggerAutoSave();
    setState(() {}); // Update character count
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final details = await _dbHelper.getLatestPersonalDetails();
    if (details != null) {
      setState(() {
        _personalDetails = details;
        _summaryController.text = details.summary;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    final summary = _summaryController.text;

    if (_personalDetails != null) {
      final updatedDetails = _personalDetails!.copyWith(
        summary: summary,
      );

      await _dbHelper.updatePersonalDetails(updatedDetails);
      _personalDetails = updatedDetails;
    } else {
      // Create a new record if it doesn't exist
      final newDetails = PersonalDetails(
        jobTarget: '',
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        address: '',
        cityState: '',
        country: '',
        postalCode: '',
        drivingLicense: '',
        linkedin: '',
        summary: summary,
      );
      final id = await _dbHelper.insertPersonalDetails(newDetails);
      _personalDetails = newDetails.copyWith(id: id);
    }
  }

  void _triggerAutoSave() {
    final now = DateTime.now();
    _lastSaveTime = now;

    Future.delayed(const Duration(seconds: 1), () async {
      if (_lastSaveTime == now && mounted) {
        setState(() => _isSaving = true);
        await _saveData();
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    });
  }

  void _showAISuggestions() {
    final templates = [
      {
        'title': 'Experienced Mobile Engineer',
        'text':
            'Dedicated Mobile Engineer with 5+ years of experience in developing high-performance iOS and Android applications. Expert in Flutter and Dart, with a strong background in native development. Proven track record of delivering user-centric features and optimizing app performance for millions of users.'
      },
      {
        'title': 'Full-Stack Developer',
        'text':
            'Versatile Full-Stack Developer proficient in modern web technologies including React, Node.js, and Python. Passionate about building scalable cloud-based solutions and intuitive user interfaces. Strong problem-solving skills and experience working in agile environments to ship high-quality code.'
      },
      {
        'title': 'Software Engineer (Clean Code)',
        'text':
            'Software Engineer committed to writing clean, maintainable, and testable code. Experienced in architectural patterns, CI/CD pipelines, and automated testing. Adept at collaborating with cross-functional teams to translate complex requirements into robust technical solutions while meeting tight deadlines.'
      },
      {
        'title': 'Junior Developer / Recent Graduate',
        'text':
            'Highly motivated and fast-learning Junior Developer with a solid foundation in computer science principles and modern programming languages. Eager to contribute to innovative projects and grow professionally within a collaborative team. Strong focus on detail and a passion for technology.'
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Suggestions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Choose a template that matches your experience. You can edit it after selecting.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _summaryController.text = template['text']!;
                          });
                          Navigator.pop(context);
                          _triggerAutoSave();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template['title']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                template['text']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined,
                color: Color(0xFF1F2937)),
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
                      content: Text('Summary saved successfully!'),
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
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF6366F1)))
                  : const Text(
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
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                              '87%',
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
                    widthFactor: 0.87,
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
                            'Professional Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Write 2-4 short, energetic sentences about how great you are. Mention the role and what you did. What were the big achievements? Describe your motivation and list your skills.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Editor Container
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFFEFF6FF), // Light blue-grey background
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                // Toolbar
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: IntrinsicHeight(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _buildToolbarIcon(Icons.format_bold),
                                          _buildToolbarIcon(
                                              Icons.format_italic),
                                          _buildToolbarIcon(
                                              Icons.format_underlined),
                                          _buildToolbarIcon(
                                              Icons.format_strikethrough),
                                          const VerticalDivider(
                                              width: 16, thickness: 1),
                                          _buildToolbarIcon(
                                              Icons.format_list_bulleted),
                                          _buildToolbarIcon(
                                              Icons.format_list_numbered),
                                          const VerticalDivider(
                                              width: 16, thickness: 1),
                                          _buildToolbarIcon(Icons.link),
                                          _buildToolbarIcon(Icons.format_size),
                                          _buildToolbarIcon(
                                              Icons.format_color_text),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: _showAISuggestions,
                                            icon: const Icon(Icons.auto_awesome,
                                                size: 14,
                                                color: Color(0xFF6366F1)),
                                            label: const Text(
                                              'Get help with writing',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6366F1),
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Text Field
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: TextField(
                                    controller: _summaryController,
                                    maxLines: 8,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText:
                                          'Describe your professional background...',
                                    ),
                                    style: GoogleFonts.lato(
                                      fontSize: 15,
                                      color: const Color(0xFF1F2937),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Character count footer
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Recruiter tip: write 400-600 characters to increase interview chances',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                              Text(
                                '${_summaryController.text.length} / 600',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.sentiment_satisfied_alt,
                                color: _summaryController.text.length >= 400
                                    ? const Color(0xFF10B981)
                                    : Colors.grey[400],
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Navigation
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildDotsIndicator(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _saveData();
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ProjectsScreen()),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0084FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Next: Projects',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildToolbarIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(icon, size: 18, color: Colors.grey[600]),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      children: List.generate(6, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == 4 ? const Color(0xFF3B82F6) : Colors.grey[300],
          ),
        );
      }),
    );
  }
}
