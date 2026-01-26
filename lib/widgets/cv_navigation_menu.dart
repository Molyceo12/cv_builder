import 'package:flutter/material.dart';
import '../screens/personal_details_screen.dart';
import '../screens/professional_summary_screen.dart';
import '../screens/employment_history_screen.dart';
import '../screens/education_history_screen.dart';
import '../screens/skills_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/languages_screen.dart';
import '../screens/references_screen.dart';
import '../screens/certificates_screen.dart';
import '../screens/qualities_screen.dart';

class CvNavigationMenu {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Text(
                      'CV Sections',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 20),
                      children: [
                        _buildSectionTile(context, 'Personal Details', Icons.person, const PersonalDetailsScreen()),
                        _buildSectionTile(context, 'Professional Summary', Icons.summarize, const ProfessionalSummaryScreen()),
                        _buildSectionTile(context, 'Employment History', Icons.work, const EmploymentHistoryScreen()),
                        _buildSectionTile(context, 'Education', Icons.school, const EducationHistoryScreen()),
                        _buildSectionTile(context, 'Skills', Icons.star, const SkillsScreen()),
                        _buildSectionTile(context, 'Projects', Icons.folder, const ProjectsScreen()),
                        _buildSectionTile(context, 'Languages', Icons.language, const LanguagesScreen()),
                        _buildSectionTile(context, 'References', Icons.people, const ReferencesScreen()),
                        _buildSectionTile(context, 'Certificates', Icons.workspace_premium, const CertificatesScreen()),
                        _buildSectionTile(context, 'Qualities', Icons.psychology, const QualitiesScreen()),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static Widget _buildSectionTile(BuildContext context, String title, IconData icon, Widget screen) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E7FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: () {
        Navigator.pop(context); // Close bottom sheet
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}
