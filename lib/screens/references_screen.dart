import 'dart:async';
import '../widgets/cv_navigation_menu.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import 'template_selection_screen.dart';

class ReferenceEntry {
  String? remoteId;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool isExpanded = true;
  String lastSavedSnapshot = '';

  ReferenceEntry({this.remoteId});

  void dispose() {
    nameController.dispose();
    roleController.dispose();
    companyController.dispose();
    phoneController.dispose();
    emailController.dispose();
  }

  Map<String, dynamic> toPayload(String cvId) {
    return {
      if (remoteId != null) 'id': remoteId,
      'cv': cvId,
      'name': nameController.text,
      'role': roleController.text,
      'company': companyController.text,
      'phone': phoneController.text,
      'email': emailController.text,
    };
  }
}

class ReferencesScreen extends StatefulWidget {
  const ReferencesScreen({super.key});

  @override
  State<ReferencesScreen> createState() => _ReferencesScreenState();
}

class _ReferencesScreenState extends State<ReferencesScreen> {
  final _apiClient = ApiClient();
  final List<ReferenceEntry> _referencesList = [];
  bool _isLoading = true;
  bool _isSavingRemote = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var entry in _referencesList) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeCvId = prefs.getString('active_cv_id');
      if (activeCvId != null) {
        final response = await _apiClient.dio.get('api/reference/', queryParameters: {'cv': activeCvId});
        if (response.statusCode == 200) {
          final List<dynamic> refs = response.data;
          setState(() {
            _referencesList.clear();
            if (refs.isNotEmpty) {
              for (var r in refs) {
                final entry = ReferenceEntry(remoteId: r['id']);
                entry.nameController.text = r['name'] ?? '';
                entry.roleController.text = r['role'] ?? '';
                entry.companyController.text = r['company'] ?? '';
                entry.phoneController.text = r['phone'] ?? '';
                entry.emailController.text = r['email'] ?? '';
                entry.isExpanded = false;
                entry.lastSavedSnapshot = entry.toPayload(activeCvId).toString();
                _addListeners(entry);
                _referencesList.add(entry);
              }
            } else {
              _addEmptyReference();
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading references: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addEmptyReference() {
    final entry = ReferenceEntry();
    _addListeners(entry);
    setState(() {
      _referencesList.add(entry);
    });
  }

  void _addListeners(ReferenceEntry entry) {
    entry.nameController.addListener(_triggerAutoSave);
    entry.roleController.addListener(_triggerAutoSave);
    entry.companyController.addListener(_triggerAutoSave);
    entry.phoneController.addListener(_triggerAutoSave);
    entry.emailController.addListener(_triggerAutoSave);
  }

  void _triggerAutoSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 2000), () {
      _saveData();
    });
  }

  void _removeReference(int index) {
    setState(() {
      _referencesList.removeAt(index);
      if (_referencesList.isEmpty) {
        _addEmptyReference();
      }
    });
    _triggerAutoSave();
  }

  Future<bool> _saveData({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final activeCvId = prefs.getString('active_cv_id');
    if (activeCvId == null) return false;

    if (_isSavingRemote) return false;

    final List<Map<String, dynamic>> tasks = [];
    for (var entry in _referencesList) {
      if (entry.nameController.text.isEmpty) continue;
      final payload = entry.toPayload(activeCvId);
      final snapshot = payload.toString();

      if (force || snapshot != entry.lastSavedSnapshot) {
        tasks.add({'entry': entry, 'payload': payload, 'snapshot': snapshot});
      }
    }

    if (tasks.isEmpty) return false;

    setState(() => _isSavingRemote = true);

    bool allSuccess = true;
    try {
      for (var task in tasks) {
        final entry = task['entry'] as ReferenceEntry;
        final payload = task['payload'] as Map<String, dynamic>;
        final snapshot = task['snapshot'];

        try {
          late Response response;
          if (entry.remoteId != null) {
            response = await _apiClient.dio.patch(
              'api/reference/${entry.remoteId}/',
              data: payload,
            );
          } else {
            response = await _apiClient.dio.post(
              'api/reference/',
              data: payload,
            );
          }

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data;
            final body = data is Map ? (data['body'] ?? data) : data;
            entry.remoteId = body['id']?.toString() ?? entry.remoteId;
            entry.lastSavedSnapshot = snapshot;
          } else {
            allSuccess = false;
          }
        } catch (e) {
          debugPrint("Error saving individual reference: $e");
          allSuccess = false;
        }
      }
    } catch (e) {
      debugPrint("Error in reference save loop: $e");
      allSuccess = false;
    } finally {
      setState(() => _isSavingRemote = false);
    }
    return allSuccess;
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
          'References',
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
                      content: Text('References saved successfully!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              child: _isSavingRemote 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F2937)),
                  )
                : const Text('Save', style: TextStyle(color: Color(0xFF1F2937))),
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
                            'Final Step!',
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
                            'References',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add professional references who can vouch for your work.',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ...List.generate(_referencesList.length,
                              (index) => _buildReferenceCard(index)),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _addEmptyReference,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              'Add another reference',
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
                            children: List.generate(9, (index) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == 8
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
                                          const TemplateSelectionScreen()),
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
                              'Finish & Preview',
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

  Widget _buildReferenceCard(int index) {
    final ref = _referencesList[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => ref.isExpanded = !ref.isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ref.nameController.text.isEmpty
                          ? '(Not specified)'
                          : ref.nameController.text,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Icon(
                      ref.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
                    onPressed: () => _removeReference(index),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          if (ref.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildTextField(
                      ref.nameController, 'Name', 'e.g. Mr. John Doe'),
                  const SizedBox(height: 16),
                  _buildTextField(ref.roleController, 'Role / Position',
                      'e.g. Senior Lecturer, Department of...'),
                  const SizedBox(height: 16),
                  _buildTextField(ref.companyController, 'Company / University',
                      'e.g. University of Rwanda'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                            ref.phoneController, 'Phone', 'e.g. +250...'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(ref.emailController, 'Email',
                            'e.g. example@ur.ac.rw'),
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
}
