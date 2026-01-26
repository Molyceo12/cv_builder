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
  late Future<List<CvSummary>> _cvsFuture;

  @override
  void initState() {
    super.initState();
    _cvsFuture = _fetchCvs();
  }

  Future<List<CvSummary>> _fetchCvs() async {
    try {
      final response = await _apiClient.dio.get('api/cvs/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CvSummary.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load CVs');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
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
      body: FutureBuilder<List<CvSummary>>(
        future: _cvsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No resumes found on server.'));
          }

          final cvs = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cvs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cv = cvs[index];
              return _buildCvCard(cv);
            },
          );
        },
      ),
    );
  }

  Widget _buildCvCard(CvSummary cv) {
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
        subtitle: Text('Created on: ${cv.createdAt.substring(0, 10)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          // Save to Shared Preferences for persistence
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('active_cv_id', cv.id);
          
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PersonalDetailsScreen(cvId: cv.id),
              ),
            );
          }
        },
      ),
    );
  }
}
