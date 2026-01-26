import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/language.dart';
import 'template_selection_screen.dart';
import 'qualities_screen.dart';

class LanguageEntry {
  final TextEditingController nameController = TextEditingController();
  String level = 'Intermediate';
  bool isExpanded = true;

  VoidCallback? onUpdate;

  LanguageEntry({this.onUpdate}) {
    nameController.addListener(_onNameUpdate);
  }

  void _onNameUpdate() {
    onUpdate?.call();
  }

  void dispose() {
    nameController.removeListener(_onNameUpdate);
    nameController.dispose();
  }
}

class LanguagesScreen extends StatefulWidget {
  const LanguagesScreen({super.key});

  @override
  State<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguagesScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final List<LanguageEntry> _languagesList = [];
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _lastSaveTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final personalDetails = await _dbHelper.getLatestPersonalDetails();
    if (personalDetails != null) {
      final languages = await _dbHelper.getLanguages(personalDetails.id!);
      setState(() {
        _languagesList.clear();
        if (languages.isNotEmpty) {
          for (var lang in languages) {
            final entry = LanguageEntry(onUpdate: _triggerAutoSave);
            entry.nameController.text = lang.language;
            entry.level = lang.level;
            _languagesList.add(entry);
          }
        } else {
          _languagesList.add(LanguageEntry(onUpdate: _triggerAutoSave));
        }
      });
    } else {
      setState(() {
        _languagesList.add(LanguageEntry(onUpdate: _triggerAutoSave));
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    final personalDetails = await _dbHelper.getLatestPersonalDetails();
    if (personalDetails == null) return;

    final languagesToSave =
        _languagesList.where((e) => e.nameController.text.isNotEmpty).map((e) {
      return Language(
        personalDetailsId: personalDetails.id!,
        language: e.nameController.text,
        level: e.level,
      );
    }).toList();

    await _dbHelper.saveLanguages(personalDetails.id!, languagesToSave);
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

  void _addLanguage() {
    setState(() {
      _languagesList.add(LanguageEntry(onUpdate: _triggerAutoSave));
    });
  }

  void _addSuggestedLanguage(String name) {
    bool alreadyExists = _languagesList
        .any((e) => e.nameController.text.toLowerCase() == name.toLowerCase());
    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name is already in your list')),
      );
      return;
    }

    int emptyIndex =
        _languagesList.indexWhere((e) => e.nameController.text.isEmpty);

    setState(() {
      if (emptyIndex != -1) {
        _languagesList[emptyIndex].nameController.text = name;
        _languagesList[emptyIndex].isExpanded = true;
      } else {
        final entry = LanguageEntry(onUpdate: _triggerAutoSave);
        entry.nameController.text = name;
        entry.isExpanded = true;
        _languagesList.add(entry);
      }
    });
    _triggerAutoSave();
  }

  void _removeLanguage(int index) {
    setState(() {
      _languagesList.removeAt(index);
      if (_languagesList.isEmpty) {
        _addLanguage();
      }
    });
  }

  @override
  void dispose() {
    for (var entry in _languagesList) {
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
                      content: Text('Languages saved successfully!'),
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
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '72%',
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
                          const SizedBox(width: 4),
                          Text(
                            'Add languages',
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
                    widthFactor: 0.72,
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
                                'Languages',
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
                                  '+5%',
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
                            'Enter the languages you speak and your proficiency level.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Suggested Languages
                          const Text(
                            'Suggested Languages',
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
                              'Kinyarwanda',
                              'English',
                              'French',
                              'Kiswahili'
                            ].map((langName) {
                              return ActionChip(
                                label: Text(langName),
                                onPressed: () =>
                                    _addSuggestedLanguage(langName),
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

                          // Languages list
                          ...List.generate(_languagesList.length, (index) {
                            return _buildLanguageCard(index);
                          }),

                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _addLanguage,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              'Add one more language',
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
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const QualitiesScreen()),
                                    );
                                  }
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
                                  'Next: Qualities',
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

  Widget _buildLanguageCard(int index) {
    final entry = _languagesList[index];
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
            subtitle: Text(entry.level,
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
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
                  onPressed: () => _removeLanguage(index),
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
                            const Text(
                              'Language',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Level — ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
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

  Widget _buildLevelSelector(LanguageEntry entry) {
    const levels = ['Basic', 'Intermediate', 'Advanced', 'Fluent', 'Native'];
    final currentIndex = levels.indexOf(entry.level);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
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
                _triggerAutoSave();
              },
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isActual
                      ? levelColor
                      : (isSelected
                          ? levelColor.withOpacity(0.2)
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
      case 'Basic':
        return const Color(0xFFF87171);
      case 'Intermediate':
        return const Color(0xFFFB923C);
      case 'Advanced':
        return const Color(0xFFFBBF24);
      case 'Fluent':
        return const Color(0xFF4ADE80);
      case 'Native':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Widget _buildDotsIndicator() {
    return Row(
      children: List.generate(7, (index) {
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
