import 'package:cv_builder/screens/personal_details_screen.dart';
import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../models/cv_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CvSelectionScreen extends StatefulWidget {
  const CvSelectionScreen({super.key});

  @override
  State<CvSelectionScreen> createState() => _CvSelectionScreenState();
}

class _CvSelectionScreenState extends State<CvSelectionScreen> {
  final ApiClient _apiClient = ApiClient();
  List<CvSummary>? _cvs;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCvs();
  }

  Future<void> _fetchCvs() async {
    try {
      final response = await _apiClient.dio.get('api/cvs/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (mounted) {
          setState(() {
            _cvs = data.map((json) => CvSummary.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load CVs';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCv(int index) async {
    final cv = _cvs![index];
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Resume?'),
          content: Text('Are you sure you want to permanently delete "${cv.name}" and all of its data? This cannot be undone.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      ),
    );
    
    try {
      final response = await _apiClient.dio.delete('api/cvs/${cv.id}/');
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _cvs!.removeAt(index);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CV deleted successfully')),
          );
        }
      } else {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete CV: $e')),
        );
      }
    }
  }

  Future<void> _duplicateCv(int index) async {
    final cv = _cvs![index];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      ),
    );

    try {
      final response = await _apiClient.dio.post('api/cvs/${cv.id}/duplicate/');
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newCv = CvSummary.fromJson(response.data['body']);
        setState(() {
          _cvs!.insert(index + 1, newCv);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CV duplicated successfully')));
        }
      } else {
        throw Exception('Failed to duplicate');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to duplicate CV: $e')));
      }
    }
  }

  void _editCvName(int index) {
    final cv = _cvs![index];
    final TextEditingController controller = TextEditingController(text: cv.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Resume Name',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter new name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty && newName != cv.name) {
                    Navigator.pop(context); // Close bottom sheet
                    
                    final originalName = cv.name;
                    setState(() {
                      _cvs![index] = CvSummary(id: cv.id, name: newName, createdAt: cv.createdAt);
                    });
                    
                    try {
                      final response = await _apiClient.dio.patch(
                        'api/cvs/${cv.id}/',
                        data: {'name': newName},
                      );
                      if (response.statusCode == 200) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CV renamed successfully')));
                        }
                      } else {
                          throw Exception('Failed to rename');
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _cvs![index] = CvSummary(id: cv.id, name: originalName, createdAt: cv.createdAt);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to rename CV: $e')));
                      }
                    }
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Resume'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage'));
    } else if (_cvs == null || _cvs!.isEmpty) {
      return const Center(child: Text('No resumes found on server.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchCvs,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _cvs!.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final cv = _cvs![index];
          return _buildCvCard(cv, index);
        },
      ),
    );
  }

  void _showCvOptionsBottomSheet(BuildContext context, int index, CvSummary cv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xFF6366F1)),
                  title: const Text('Edit Name'),
                  onTap: () {
                    Navigator.pop(context);
                    _editCvName(index);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy, color: Color(0xFF6366F1)),
                  title: const Text('Duplicate'),
                  onTap: () {
                    Navigator.pop(context);
                    _duplicateCv(index);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteCv(index);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCvCard(CvSummary cv, int index) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0E7FF),
          child: Icon(Icons.description, color: Color(0xFF6366F1)),
        ),
        title: Text(
          cv.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Created on: ${cv.createdAt.length >= 10 ? cv.createdAt.substring(0, 10) : cv.createdAt}'),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showCvOptionsBottomSheet(context, index, cv),
        ),
        onTap: () async {
          // Save to Shared Preferences for persistence
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('active_cv_id', cv.id);
          
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PersonalDetailsScreen(cvId: cv.id),
              ),
            );
            // Refresh list automatically when returning
            _fetchCvs();
          }
        },
      ),
    );
  }
}
