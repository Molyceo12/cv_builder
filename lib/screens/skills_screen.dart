import 'dart:async';
import '../widgets/cv_navigation_menu.dart';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../models/skill.dart';
import 'template_selection_screen.dart';
import 'languages_screen.dart';

class SkillEntry {
  String? remoteId;
  final TextEditingController nameController = TextEditingController();
  String level = 'Skillful';
  bool isExpanded = true;

  void Function(SkillEntry)? onUpdate;

  SkillEntry({this.onUpdate}) {
    nameController.addListener(_onNameUpdate);
  }

  void _onNameUpdate() {
    onUpdate?.call(this);
  }

  void dispose() {
    nameController.removeListener(_onNameUpdate);
    nameController.dispose();
  }
}

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final _apiClient = ApiClient();
  final List<SkillEntry> _skillsList = [];
  bool _isLoading = true;
  bool _showExperienceLevel = true;
  bool _isSavingRemote = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeCvId = prefs.getString('active_cv_id');

      if (activeCvId != null) {
        final response = await _apiClient.dio.get(
          'api/skill/',
          queryParameters: {'cv': activeCvId},
        );

        if (response.statusCode == 200) {
          final List<dynamic> skills = response.data;
          setState(() {
            _skillsList.clear();
            if (skills.isNotEmpty) {
              for (var skill in skills) {
                final entry = SkillEntry(onUpdate: _triggerAutoSave);
                entry.remoteId = skill['id']?.toString();
                entry.nameController.text = skill['skill_name'] ?? '';
                entry.level = skill['level'] ?? 'Skillful';
                _skillsList.add(entry);
              }
            } else {
              _skillsList.add(SkillEntry(onUpdate: _triggerAutoSave));
            }
          });
        }
      } else {
        setState(() => _skillsList.add(SkillEntry(onUpdate: _triggerAutoSave)));
      }
    } catch (e) {
      debugPrint('Error loading skills: $e');
      if (mounted) {
        setState(() {
          _skillsList.add(SkillEntry(onUpdate: _triggerAutoSave));
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _saveData({SkillEntry? targetEntry}) async {
    final prefs = await SharedPreferences.getInstance();
    final activeCvId = prefs.getString('active_cv_id');
    if (activeCvId == null) return false;

    // Guard manual save indicators
    if (targetEntry == null) {
      if (_isSavingRemote) return false;
      setState(() => _isSavingRemote = true);
    }

    bool allSuccess = true;
    try {
      final listToSync = targetEntry != null
          ? [targetEntry]
          : _skillsList.where((e) => e.nameController.text.isNotEmpty).toList();

      if (listToSync.isEmpty) {
        if (targetEntry == null) setState(() => _isSavingRemote = false);
        return true;
      }

      for (var entry in listToSync) {
        final Map<String, dynamic> payload = {
          "cv": activeCvId,
          "skill_name": entry.nameController.text,
          "level": entry.level,
        };

        try {
          late Response response;
          if (entry.remoteId != null) {
            response = await _apiClient.dio.patch(
              'api/skill/${entry.remoteId}/',
              data: payload,
            );
          } else {
            response = await _apiClient.dio.post(
              'api/skill/',
              data: payload,
            );
          }

          if (response.statusCode == 201 || response.statusCode == 200) {
            final dynamic respData = response.data;
            final body = respData is Map ? (respData['body'] ?? respData) : respData;
            entry.remoteId = body['id']?.toString() ?? entry.remoteId;
          } else {
            allSuccess = false;
          }
        } catch (e) {
          debugPrint('Error syncing individual skill: $e');
          allSuccess = false;
        }
      }

      return allSuccess;
    } catch (e) {
      debugPrint('Error in skills save loop: $e');
      return false;
    } finally {
      if (mounted && targetEntry == null) {
        setState(() => _isSavingRemote = false);
      }
    }
  }

  void _triggerAutoSave(SkillEntry entry) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      _saveData(targetEntry: entry);
    });
  }

  void _addSkill() {
    setState(() {
      _skillsList.add(SkillEntry(onUpdate: _triggerAutoSave));
    });
  }

  void _addSuggestedSkill(String name) {
    // Check if skill already exists
    bool alreadyExists = _skillsList
        .any((e) => e.nameController.text.toLowerCase() == name.toLowerCase());
    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name is already in your list')),
      );
      return;
    }

    // Find first empty entry or add new one
    int emptyIndex =
        _skillsList.indexWhere((e) => e.nameController.text.isEmpty);

    SkillEntry? target;
    setState(() {
      if (emptyIndex != -1) {
        target = _skillsList[emptyIndex];
        target!.nameController.text = name;
        target!.isExpanded = true;
      } else {
        target = SkillEntry(onUpdate: _triggerAutoSave);
        target!.nameController.text = name;
        target!.isExpanded = true;
        _skillsList.add(target!);
      }
    });
    if (target != null) _triggerAutoSave(target!);
  }

  void _removeSkill(int index) async {
    final entry = _skillsList[index];
    final remoteId = entry.remoteId;

    setState(() {
      _skillsList.removeAt(index);
      if (_skillsList.isEmpty) {
        _addSkill();
      }
    });

    if (remoteId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final activeCvId = prefs.getString('active_cv_id');
        if (activeCvId != null) {
          await _apiClient.deleteSkill(remoteId, cvId: activeCvId);
        }
      } catch (e) {
        debugPrint('Error deleting skill: $e');
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (var entry in _skillsList) {
      entry.dispose();
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
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TemplateSelectionScreen()),
              );
            },
            tooltip: 'Preview CV',
          ),
          IconButton(
            onPressed: () => CvNavigationMenu.show(context),
            tooltip: 'CV Sections',
            icon: const Icon(
              Icons.menu_open_rounded,
              color: Color(0xFF1F2937),
              size: 24,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final success = await _saveData();
                if (!mounted) return;
                
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Skills saved successfully!' : 'Error saving skills'),
                    backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
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
              child: _isSavingRemote
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
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '64%',
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
                            '+4%',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add skills',
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
                    widthFactor: 0.64,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
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
                          Row(
                            children: [
                              const Text(
                                'Skills',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '+4%',
                                  style: TextStyle(
                                    color: Color(0xFF059669),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose 5 important skills that show you fit the position. Make sure they match the key skills mentioned in the job listing (especially when applying via an online system).',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Suggested Skills
                          const Text(
                            'Suggested Skills',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 0,
                            children: [
                              'Flutter',
                              'React Native',
                              'Python',
                              'Laravel',
                              'Next.js',
                              'Nuxt.js',
                              'Dart',
                              'React',
                              'Node.js',
                              'SQL',
                              'PostgreSQL',
                              'AWS',
                              'Docker',
                              'Firebase',
                              'Git',
                              'Java',
                              'JavaScript'
                            ].map((skillName) {
                              return ActionChip(
                                label: Text(skillName),
                                onPressed: () => _addSuggestedSkill(skillName),
                                backgroundColor: const Color(0xFFEEF2FF),
                                labelStyle: const TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  side: const BorderSide(
                                      color: Color(0xFFC7D2FE)),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Switch(
                                value: !_showExperienceLevel,
                                onChanged: (value) {
                                  setState(() {
                                    _showExperienceLevel = !value;
                                  });
                                },
                                activeThumbColor: const Color(0xFF6366F1),
                                activeTrackColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
                              ),
                              const Text(
                                "Don't show experience level",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Skills list
                          ...List.generate(_skillsList.length, (index) {
                            return _buildSkillCard(index);
                          }),

                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _addSkill,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              'Add one more skill',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF3B82F6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 8),
                            ),
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
                      const Spacer(),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Only show dots if there's enough space
                            Flexible(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildDotsIndicator(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await _saveData();
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LanguagesScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0084FF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Next: Languages',
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
                ),
              ],
            ),
    );
  }

  Widget _buildSkillCard(int index) {
    final entry = _skillsList[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading:
                Icon(Icons.drag_indicator, color: Colors.grey[400], size: 20),
            title: Text(
              entry.nameController.text.isEmpty
                  ? '(Not specified)'
                  : entry.nameController.text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: _showExperienceLevel
                ? Text(entry.level,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12))
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    entry.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                  ),
                  onPressed: () =>
                      setState(() => entry.isExpanded = !entry.isExpanded),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.grey[400], size: 20),
                  onPressed: () => _removeSkill(index),
                ),
              ],
            ),
          ),
          if (entry.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Skill',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: TextField(
                                controller: entry.nameController,
                                textAlignVertical: TextAlignVertical.center,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                  border: InputBorder.none,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_showExperienceLevel)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Level — ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    entry.level,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getLevelColor(entry.level),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildLevelSelector(entry),
                            ],
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

  Widget _buildLevelSelector(SkillEntry entry) {
    const levels = ['Novice', 'Beginner', 'Skillful', 'Experienced', 'Expert'];
    final currentIndex = levels.indexOf(entry.level);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6), // Match TextField background
        borderRadius: BorderRadius.circular(4),
        // Removed border to match TextField
      ),
      child: Row(
        children: List.generate(levels.length, (index) {
          final isSelected = index <= currentIndex;
          final isActual = index == currentIndex;
          final levelColor = _getLevelColor(levels[index]);

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => entry.level = levels[index]);
                _triggerAutoSave(entry);
              },
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isActual
                      ? levelColor
                      : (isSelected
                          ? levelColor.withValues(alpha: 0.2)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: Container(
                    width: 1,
                    height: 10,
                    color: !isSelected && index < levels.length - 1
                        ? Colors.grey[300]
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Novice':
        return const Color(0xFFF87171); // Soft Red
      case 'Beginner':
        return const Color(0xFFFB923C); // Soft Orange
      case 'Skillful':
        return const Color(0xFFFBBF24); // Soft Amber/Yellow
      case 'Experienced':
        return const Color(0xFF4ADE80); // Soft Green
      case 'Expert':
        return const Color(0xFF6366F1); // Indigo
      default:
        return const Color(0xFF6366F1);
    }
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
            color: index == 3 ? const Color(0xFF3B82F6) : Colors.grey[300],
          ),
        );
      }),
    );
  }
}
