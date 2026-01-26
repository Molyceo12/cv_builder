import 'dart:async';
import '../widgets/cv_navigation_menu.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../network/api_client.dart';
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
  String? remoteId;
  String? lastSavedSnapshot;

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    githubLinkController.dispose();
    liveLinkController.dispose();
    playStoreLinkController.dispose();
    appStoreLinkController.dispose();
    technologiesController.dispose();
  }

  Map<String, dynamic> toPayload(String cvId) {
    final descLines = descriptionController.text
        .split('\n')
        .map((line) {
          String trimmed = line.trim();
          if (trimmed.startsWith('•')) {
            trimmed = trimmed.substring(1).trim();
          }
          return trimmed;
        })
        .where((line) => line.isNotEmpty)
        .toList();

    return {
      'cv': cvId,
      'title': titleController.text,
      'description': descLines.join(' • '),
      'github_link': githubLinkController.text,
      'live_link': liveLinkController.text,
      'playstore_link': playStoreLinkController.text,
      'applestore_link': appStoreLinkController.text,
      'technologies': technologiesController.text,
    };
  }
}

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ApiClient _apiClient = ApiClient();
  final List<ProjectEntry> _projects = [];
  bool _isLoading = true;
  bool _isSavingRemote = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (var p in _projects) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeCvId = prefs.getString('active_cv_id');

      if (activeCvId != null) {
        final response = await _apiClient.dio.get(
          'api/project/',
          queryParameters: {'cv': activeCvId},
        );

        if (response.statusCode == 200) {
          final List<dynamic> projectData = response.data;
          setState(() {
            _projects.clear();
            for (var p in projectData) {
              final entry = ProjectEntry();
              entry.remoteId = p['id'].toString();
              entry.titleController.text = p['title'] ?? '';

              final desc = p['description'];
              if (desc is List) {
                entry.descriptionController.text = desc
                    .map((e) => e.toString().trim())
                    .where((e) => e.isNotEmpty)
                    .map((e) => e.startsWith('•') ? e : '• $e')
                    .join('\n');
              } else if (desc is String) {
                // Split by either ' • ' or ', ' for robustness
                entry.descriptionController.text = desc
                    .split(RegExp(r' • |, '))
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .map((e) => e.startsWith('•') ? e : '• $e')
                    .join('\n');
              }

              entry.githubLinkController.text = p['github_link'] ?? '';
              entry.liveLinkController.text = p['live_link'] ?? '';
              entry.playStoreLinkController.text = p['playstore_link'] ?? '';
              entry.appStoreLinkController.text = p['applestore_link'] ?? '';
              entry.technologiesController.text = p['technologies'] ?? '';

              entry.lastSavedSnapshot = entry.toPayload(activeCvId).toString();
              _projects.add(entry);
              _setupListeners(entry);
            }
            if (_projects.isEmpty) _addEmptyProject();
          });
        } else {
          _addEmptyProject();
        }
      } else {
        _addEmptyProject();
      }
    } catch (e) {
      debugPrint('Error loading projects: $e');
      if (_projects.isEmpty) _addEmptyProject();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addEmptyProject() {
    setState(() {
      final entry = ProjectEntry();
      _projects.add(entry);
      _setupListeners(entry);
    });
  }

  void _setupListeners(ProjectEntry entry) {
    entry.titleController.addListener(_triggerAutoSave);
    entry.descriptionController.addListener(_triggerAutoSave);
    entry.githubLinkController.addListener(_triggerAutoSave);
    entry.liveLinkController.addListener(_triggerAutoSave);
    entry.playStoreLinkController.addListener(_triggerAutoSave);
    entry.appStoreLinkController.addListener(_triggerAutoSave);
    entry.technologiesController.addListener(_triggerAutoSave);
  }

  Future<bool> _saveData({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final activeCvId = prefs.getString('active_cv_id');
    if (activeCvId == null) return false;

    if (_isSavingRemote) return false;

    final List<Map<String, dynamic>> tasks = [];
    for (var entry in _projects) {
      if (entry.titleController.text.isEmpty) continue;
      final payload = entry.toPayload(activeCvId);
      final snapshot = payload.toString();

      // If forced (manual click), we save everything.
      // Otherwise (auto-save), we check for dirty changes.
      if (force || snapshot != entry.lastSavedSnapshot) {
        tasks.add({'entry': entry, 'payload': payload, 'snapshot': snapshot});
      }
    }

    if (tasks.isEmpty) return false;

    _debounce?.cancel();
    setState(() => _isSavingRemote = true);
    bool anySaved = false;

    try {
      for (var task in tasks) {
        final ProjectEntry entry = task['entry'];
        final payload = task['payload'];
        final snapshot = task['snapshot'];

        if (entry.remoteId != null) {
          // UPDATE (PATCH)
          await _apiClient.dio
              .patch('api/project/${entry.remoteId}/', data: payload);
          entry.lastSavedSnapshot = snapshot;
          anySaved = true;
        } else {
          // CREATE (POST)
          final response =
              await _apiClient.dio.post('api/project/', data: payload);
          if (response.statusCode == 201 || response.statusCode == 200) {
            final dynamic body = response.data['body'];
            if (body != null) {
              entry.remoteId = body['id'].toString();
              entry.lastSavedSnapshot = snapshot;
              anySaved = true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving project: $e');
    } finally {
      if (mounted) {
        setState(() => _isSavingRemote = false);
      }
    }
    return anySaved;
  }

  void _triggerAutoSave() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 2000), () {
      _saveData();
    });
  }

  void _removeProject(int index) async {
    final entry = _projects[index];
    final remoteId = entry.remoteId;

    setState(() {
      _projects.removeAt(index);
      if (_projects.isEmpty) {
        _addEmptyProject();
      }
    });

    if (remoteId != null) {
      try {
        await _apiClient.dio.delete('api/project/$remoteId/');
      } catch (e) {
        debugPrint('Error deleting project: $e');
      }
    }
  }

  void _applyFormatting(ProjectEntry entry, String formatType) {
    final controller = entry.descriptionController;
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
      _triggerAutoSave();
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
    _triggerAutoSave();
    setState(() {});
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
              await _saveData(force: true);
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
                final messenger = ScaffoldMessenger.of(context);
                final success = await _saveData(force: true);
                if (mounted && success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Projects saved successfully!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              child: _isSavingRemote
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save',
                      style: TextStyle(color: Color(0xFF1F2937))),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                              await _saveData(force: true);
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
                      label: 'GitHub Link',
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
            ? _buildRichTextEditorWidget(project)
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

  Widget _buildRichTextEditorWidget(ProjectEntry project) {
    final controller = project.descriptionController;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        children: [
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
                      onPressed: () => _applyFormatting(project, 'bold'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.format_italic, size: 18),
                      onPressed: () => _applyFormatting(project, 'italic'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.format_underlined, size: 18),
                      onPressed: () => _applyFormatting(project, 'underline'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.strikethrough_s, size: 18),
                      onPressed: () => _applyFormatting(project, 'strike'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  Container(
                      width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.format_list_bulleted, size: 18),
                      onPressed: () => _applyFormatting(project, 'bullet'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.format_list_numbered, size: 18),
                      onPressed: () => _applyFormatting(project, 'number'),
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
