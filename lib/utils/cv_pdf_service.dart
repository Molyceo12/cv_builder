import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/personal_details.dart';
import '../models/work_experience.dart';
import '../models/education.dart';
import '../models/skill.dart';
import '../models/project.dart';
import '../models/language.dart';
import '../models/certificate.dart';
import '../models/reference.dart';
import '../models/quality.dart';
import '../templates/modern_green_template.dart';
import '../templates/classic_template.dart';

class CVPdfService {
  static Future<Uint8List> generateCV({
    required PersonalDetails personalDetails,
    required List<WorkExperience> experiences,
    required List<Education> educationList,
    required List<Skill> skills,
    required List<Language> languages,
    required List<Quality> qualities,
    required List<Project> projects,
    required List<Certificate> certificates,
    required List<Reference> references,
    String templateType = 'modern', // 'modern' or 'classic'
  }) async {
    if (templateType == 'classic') {
      return ClassicTemplate.generateCV(
        personalDetails: personalDetails,
        experiences: experiences,
        educationList: educationList,
        skills: skills,
        languages: languages,
        qualities: qualities,
        projects: projects,
        certificates: certificates,
        references: references,
      );
    } else {
      // Default to Modern Green
      return ModernGreenTemplate.generateCV(
        personalDetails: personalDetails,
        experiences: experiences,
        educationList: educationList,
        skills: skills,
        languages: languages,
        qualities: qualities,
        projects: projects,
        certificates: certificates,
        references: references,
      );
    }
  }
}
