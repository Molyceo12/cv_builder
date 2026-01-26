import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/project.dart';
import 'certificates_screen.dart';
import 'template_selection_screen.dart';

class ProjectEntry {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController githubLinkController = TextEditingController();
  final TextEditingController liveLinkController = TextEditingController();
  final TextEditingController playStoreLinkController = TextEditingController();
  final TextEditingController appStoreLinkController = TextEditingController();
  final TextEditingController technologiesController = TextEditingController();
  bool isExpanded = true;

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    githubLinkController.dispose();
    liveLinkController.dispose();
    playStoreLinkController.dispose();
    appStoreLinkController.dispose();
    technologiesController.dispose();
  }
}

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final List<ProjectEntry> _projects = [];
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
      final projects = await _dbHelper.getProjects(personalDetails.id!);
      if (projects.isNotEmpty) {
        setState(() {
          _projects.clear();
          for (var p in projects) {
            final entry = ProjectEntry();
            entry.titleController.text = p.title;
            entry.descriptionController.text = p.description;
            entry.githubLinkController.text = p.githubLink;
            entry.liveLinkController.text = p.liveLink;
            entry.playStoreLinkController.text = p.playStoreLink;
            entry.appStoreLinkController.text = p.appStoreLink;
            entry.technologiesController.text = p.technologies;
            _projects.add(entry);
          }
        });
      } else {
        _addEmptyProject();
      }
    } else {
      _addEmptyProject();
    }
    setState(() => _isLoading = false);
  }

  void _addEmptyProject() {
    setState(() {
      _projects.add(ProjectEntry());
    });
  }

  Future<void> _saveData() async {
    final personalDetails = await _dbHelper.getLatestPersonalDetails();
    if (personalDetails == null) return;

    final projectsToSave =
        _projects.where((e) => e.titleController.text.isNotEmpty).map((e) {
      return Project(
        personalDetailsId: personalDetails.id!,
        title: e.titleController.text,
        description: e.descriptionController.text,
        githubLink: e.githubLinkController.text,
        liveLink: e.liveLinkController.text,
        playStoreLink: e.playStoreLinkController.text,
        appStoreLink: e.appStoreLinkController.text,
        technologies: e.technologiesController.text,
      );
    }).toList();

    // Validation: Check for mandatory GitHub link
    for (var project in projectsToSave) {
      if (project.githubLink.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'GitHub Link is mandatory for project "${project.title.isEmpty ? 'Untitled' : project.title}"'),
                backgroundColor: Colors.red),
          );
        }
        return; // Stop saving if validation fails
      }
    }

    await _dbHelper.saveProjects(personalDetails.id!, projectsToSave);
  }

  void _removeProject(int index) {
    setState(() {
      _projects.removeAt(index);
      if (_projects.isEmpty) {
        _addEmptyProject();
      }
    });
  }

  // Formatting helper logic
  void _applyFormatting(TextEditingController controller, String formatType) {
    final text = controller.text;
    final selection = controller.selection;
    if (selection.start == -1 || selection.end == -1) return;

    if (formatType == 'bullet' || formatType == 'number') {
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
      String formattedLines;

      if (formatType == 'bullet') {
        formattedLines = lines.map((line) {
          if (line.trim().startsWith('•')) return line;
          return '• $line';
        }).join('\n');
      } else {
        int count = 1;
        formattedLines = lines.map((line) {
          return '${count++}. $line';
        }).join('\n');
      }

      String newText = '$leftPart$formattedLines$rightPart';
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: start,
          extentOffset: start + formattedLines.length,
        ),
      );
      setState(() {});
      return;
    }

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
  void dispose() {
    for (var p in _projects) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Projects',
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
                      content: Text('Projects saved successfully!'),
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
                              '95%',
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
                            '+5%',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add projects',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
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
                    widthFactor: 0.95,
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
                            'Projects',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your best projects. Include links to GitHub and Play Store if available.',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ...List.generate(_projects.length,
                              (index) => _buildProjectCard(index)),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _addEmptyProject,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              'Add another project',
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
                            children: List.generate(7, (index) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == 6
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
                                          const CertificatesScreen()),
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
                              'Next: Certificates',
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

  Widget _buildProjectCard(int index) {
    final project = _projects[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => project.isExpanded = !project.isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator, color: Colors.grey[400], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      project.titleController.text.isEmpty
                          ? '(Not specified)'
                          : project.titleController.text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Icon(
                    project.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
                    onPressed: () => _removeProject(index),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          if (project.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildTextField(
                      label: 'Project Title',
                      controller: project.titleController,
                      hint: 'e.g. CV Builder App'),
                  const SizedBox(height: 16),
                  _buildTextField(
                      label: 'Technologies',
                      controller: project.technologiesController,
                      hint: 'e.g. Flutter, Firebase, NodeJS'),
                  const SizedBox(height: 16),
                  _buildTextField(
                      label: 'Description',
                      controller: project.descriptionController,
                      hint: 'What did you build?',
                      maxLines: 3,
                      isRichText: true,
                      project: project),
                  const SizedBox(height: 16),
                  _buildTextField(
                      label: 'GitHub Link *',
                      controller: project.githubLinkController,
                      hint: 'github.com/...'),
                  const SizedBox(height: 16),
                  _buildTextField(
                      label: 'Live Link',
                      controller: project.liveLinkController,
                      hint: 'website.com'),
                  const SizedBox(height: 16),
                  _buildTextField(
                      label: 'Play Store Link',
                      controller: project.playStoreLinkController,
                      hint: 'play.google.com/...'),
                  const SizedBox(height: 16),
                  _buildTextField(
                      label: 'App Store Link',
                      controller: project.appStoreLinkController,
                      hint: 'apps.apple.com/...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      String? hint,
      int maxLines = 1,
      bool isRichText = false,
      ProjectEntry? project}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        isRichText && project != null
            ? _buildRichTextEditorWidget(controller)
            : TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: InputDecoration(
                  hintText: hint,
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (_) => setState(() {}),
              ),
      ],
    );
  }

  Widget _buildRichTextEditorWidget(TextEditingController controller) {
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
                      onPressed: () => _applyFormatting(controller, 'bold'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.format_italic, size: 18),
                      onPressed: () => _applyFormatting(controller, 'italic'),
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
                      onPressed: () => _applyFormatting(controller, 'strike'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  Container(
                      width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.format_list_bulleted, size: 18),
                      onPressed: () => _applyFormatting(controller, 'bullet'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.format_list_numbered, size: 18),
                      onPressed: () => _applyFormatting(controller, 'number'),
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
              hintText: 'What did you build?',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
