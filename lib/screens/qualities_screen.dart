import 'dart:async';
import '../widgets/cv_navigation_menu.dart';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../models/quality.dart';
import 'template_selection_screen.dart';
import 'professional_summary_screen.dart';

class QualityEntry {
  String? remoteId;
  final TextEditingController qualityController = TextEditingController();
  bool isExpanded = true;
  void Function(QualityEntry)? onUpdate;

  QualityEntry({this.onUpdate}) {
    qualityController.addListener(_onQualityUpdate);
  }

  void _onQualityUpdate() {
    onUpdate?.call(this);
  }

  void dispose() {
    qualityController.removeListener(_onQualityUpdate);
    qualityController.dispose();
  }
}

class QualitiesScreen extends StatefulWidget {
  const QualitiesScreen({super.key});

  @override
  State<QualitiesScreen> createState() => _QualitiesScreenState();
}

class _QualitiesScreenState extends State<QualitiesScreen> {
  final ApiClient _apiClient = ApiClient();
  final List<QualityEntry> _qualitiesList = [];
  final TextEditingController _customQualityController =
      TextEditingController();
  bool _isLoading = true;
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
          'api/quality/',
          queryParameters: {'cv': activeCvId},
        );

        if (response.statusCode == 200) {
          final List<dynamic> qualities = response.data;
          setState(() {
            _qualitiesList.clear();
            if (qualities.isNotEmpty) {
              for (var q in qualities) {
                final entry = QualityEntry(onUpdate: _triggerAutoSave);
                entry.remoteId = q['id']?.toString();
                entry.qualityController.text = q['quality'] ?? '';
                _qualitiesList.add(entry);
              }
            } else {
              _qualitiesList.add(QualityEntry(onUpdate: _triggerAutoSave));
            }
          });
        }
      } else {
        setState(() {
          _qualitiesList.add(QualityEntry(onUpdate: _triggerAutoSave));
        });
      }
    } catch (e) {
      debugPrint('Error loading qualities: $e');
      if (mounted) {
        setState(() {
          _qualitiesList.add(QualityEntry(onUpdate: _triggerAutoSave));
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _saveData({QualityEntry? targetEntry}) async {
    final prefs = await SharedPreferences.getInstance();
    final activeCvId = prefs.getString('active_cv_id');
    if (activeCvId == null) return false;

    if (targetEntry == null) {
      if (_isSavingRemote) return false;
      setState(() => _isSavingRemote = true);
    }

    bool allSuccess = true;
    try {
      final listToSync = targetEntry != null 
          ? [targetEntry] 
          : _qualitiesList.where((e) => e.qualityController.text.isNotEmpty).toList();

      if (listToSync.isEmpty) {
        if (targetEntry == null) setState(() => _isSavingRemote = false);
        return true;
      }

      final bulkData = listToSync.map((e) {
        final Map<String, dynamic> data = {
          "cv": activeCvId,
          "quality": e.qualityController.text,
        };
        if (e.remoteId != null) {
          data["id"] = e.remoteId;
        }
        return data;
      }).toList();

      final response = await _apiClient.dio.post('api/quality/', data: bulkData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final dynamic respData = response.data;
        final List<dynamic> processedList = (respData is Map && respData['body'] != null) 
            ? respData['body'] 
            : (respData is List ? respData : [respData]);
            
        for (var processed in processedList) {
          if (processed is! Map) continue;
          final entry = listToSync.firstWhere(
            (e) => (e.remoteId != null && e.remoteId == processed['id']?.toString()) ||
                   (e.qualityController.text == processed['quality']),
            orElse: () => listToSync.first,
          );
          entry.remoteId = processed['id']?.toString();
        }
      } else {
        allSuccess = false;
      }

      return allSuccess;
    } catch (e) {
      debugPrint('Error syncing qualities: $e');
      return false;
    } finally {
      if (mounted && targetEntry == null) {
        setState(() => _isSavingRemote = false);
      }
    }
  }

  void _triggerAutoSave(QualityEntry entry) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      _saveData(targetEntry: entry);
    });
  }

  void _addQuality() {
    if (_qualitiesList.isNotEmpty &&
        _qualitiesList.last.qualityController.text.isEmpty) {
      return;
    }
    setState(() {
      _qualitiesList.add(QualityEntry(onUpdate: _triggerAutoSave));
    });
  }

  void _addSuggestedQuality(String name) {
    if (name.isEmpty) return;

    bool alreadyExists = _qualitiesList.any((e) =>
        e.qualityController.text.toLowerCase() == name.trim().toLowerCase());
    if (alreadyExists) return;

    QualityEntry? target;
    setState(() {
      int emptyIndex =
          _qualitiesList.indexWhere((e) => e.qualityController.text.isEmpty);

      target = QualityEntry(onUpdate: _triggerAutoSave);
      target!.qualityController.text = name;

      if (emptyIndex != -1) {
        _qualitiesList[emptyIndex].dispose();
        _qualitiesList[emptyIndex] = target!;
      } else {
        _qualitiesList.add(target!);
      }
    });
    if (target != null) _triggerAutoSave(target!);
  }

  void _removeQuality(int index) async {
    final entry = _qualitiesList[index];
    final remoteId = entry.remoteId;

    setState(() {
      _qualitiesList.removeAt(index);
      if (_qualitiesList.isEmpty) {
        _addQuality();
      }
    });

    // If it was already on the server, delete it there too
    if (remoteId != null) {
      try {
        await _apiClient.dio.delete('api/quality/$remoteId/');
      } catch (e) {
        debugPrint('Error deleting quality from server: $e');
        // Optional: Show a snackbar if deletion failed?
      }
    }
  }

  void _addCustomQuality() {
    if (_customQualityController.text.trim().isEmpty) return;
    _addSuggestedQuality(_customQualityController.text.trim());
    _customQualityController.clear();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _customQualityController.dispose();
    for (var entry in _qualitiesList) {
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
                      builder: (context) => const TemplateSelectionScreen()));
            },
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
                    content: Text(success ? 'Qualities saved successfully!' : 'Error saving qualities'),
                    backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: _isSavingRemote
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF6366F1)))
                  : const Text('Save'),
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
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('78%',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Your resume score',
                          style: TextStyle(
                              color: Color(0xFF6B7280), fontSize: 14)),
                    ],
                  ),
                ),
                Container(
                  height: 4,
                  width: double.infinity,
                  color: const Color(0xFFF3F4F6),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.78,
                    child: Container(
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [
                      Color(0xFFF59E0B),
                      Color(0xFFF97316)
                    ]))),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Qualities',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937))),
                          const SizedBox(height: 8),
                          Text(
                              'Add qualities that describe your professional character.',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500])),
                          const SizedBox(height: 16),
                          const Text('Suggested Qualities',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...[
                                'Effective communication',
                                'Problem-solving',
                                'Creativity',
                                'Learning easily',
                                'Critical thinking',
                                'Time management',
                                'Teamwork',
                                'Adaptability'
                              ].map((q) => ActionChip(
                                    label: Text(q),
                                    onPressed: () => _addSuggestedQuality(q),
                                    backgroundColor: const Color(0xFFEEF2FF),
                                    side: BorderSide.none,
                                    labelStyle: const TextStyle(
                                        color: Color(0xFF4B5563),
                                        fontWeight: FontWeight.w500),
                                  )),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFFE5E7EB)),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 120,
                                      child: TextField(
                                        controller: _customQualityController,
                                        decoration: const InputDecoration(
                                          hintText: 'Custom quality',
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding:
                                              EdgeInsets.symmetric(vertical: 8),
                                          hintStyle: TextStyle(
                                              fontSize: 13, color: Colors.grey),
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                        onSubmitted: (_) => _addCustomQuality(),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle,
                                          color: Color(0xFF3B82F6), size: 20),
                                      onPressed: _addCustomQuality,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      splashRadius: 20,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _qualitiesList.length,
                            onReorder: _onReorder,
                            itemBuilder: (context, index) {
                              return _buildQualityCard(index,
                                  Key('${_qualitiesList[index].hashCode}'));
                            },
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                              onPressed: _addQuality,
                              icon: const Icon(Icons.add),
                              label: const Text('Add one more quality')),
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
                          _buildDotsIndicator(),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              await _saveData();
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfessionalSummaryScreen()),
                              );
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
                              'Next: Summary',
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

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final QualityEntry item = _qualitiesList.removeAt(oldIndex);
      _qualitiesList.insert(newIndex, item);
    });
    // For qualities, we often re-sync everything after reorder
    _saveData();
  }

  Widget _buildQualityCard(int index, Key key) {
    final entry = _qualitiesList[index];
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.drag_indicator,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: entry.qualityController,
              decoration: const InputDecoration(
                hintText: 'e.g. Leadership',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF9CA3AF), size: 20),
            onPressed: () => _removeQuality(index),
            tooltip: 'Remove',
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      children: List.generate(
          7,
          (index) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == 4
                        ? const Color(0xFF3B82F6)
                        : Colors.grey[300]),
              )),
    );
  }
}
