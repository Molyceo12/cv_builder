import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../models/personal_details.dart';
import '../models/work_experience.dart';
import '../models/education.dart';
import '../models/skill.dart';
import '../models/language.dart';
import '../models/project.dart';
import '../models/certificate.dart';
import '../models/quality.dart';
import '../models/reference.dart';
import '../utils/cv_pdf_service.dart';
import '../widgets/preview_skeleton.dart';

class CVPreviewScreen extends StatefulWidget {
  final String initialTemplate;
  const CVPreviewScreen({super.key, this.initialTemplate = 'modern'});

  @override
  State<CVPreviewScreen> createState() => _CVPreviewScreenState();
}

class _CVPreviewScreenState extends State<CVPreviewScreen> {
  final _apiClient = ApiClient();
  final TransformationController _transformationController =
      TransformationController();
  PersonalDetails? _personalDetails;
  List<WorkExperience> _experiences = [];
  List<Education> _educationList = [];
  List<Skill> _skills = [];
  List<Language> _languages = [];
  List<Quality> _qualities = [];
  List<Project> _projects = [];
  List<Certificate> _certificates = [];
  List<Reference> _references = [];
  bool _isLoading = true;

  late String _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.initialTemplate;
    _loadData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final activeCvId = prefs.getString('active_cv_id');

      if (activeCvId != null) {
        // 1. Load Personal Details
        final pdResponse = await _apiClient.dio.get(
          'api/personal-details/',
          queryParameters: {'cv': activeCvId},
        );

        if (pdResponse.statusCode == 200 && (pdResponse.data as List).isNotEmpty) {
          final pdData = pdResponse.data[0];
          _personalDetails = PersonalDetails(
            id: 0, // Not strictly needed for PDF
            jobTarget: pdData['jobTarget'] ?? '',
            firstName: pdData['firstName'] ?? '',
            lastName: pdData['lastName'] ?? '',
            email: pdData['email'] ?? '',
            phone: pdData['phone'] ?? '',
            address: pdData['address'] ?? '',
            cityState: pdData['cityState'] ?? '',
            country: pdData['country'] ?? '',
            postalCode: pdData['postalCode'] ?? '',
            drivingLicense: pdData['drivingLicense'] ?? '',
            linkedin: pdData['linkedin'] ?? '',
            dateOfBirth: pdData['dateOfBirth'] ?? '',
            placeOfBirth: pdData['placeOfBirth'] ?? '',
            gender: pdData['gender'] ?? '',
            nationality: pdData['nationality'] ?? '',
            github: pdData['github'] ?? '',
          );
        }

        // 2. Load Work Experiences
        final weResponse = await _apiClient.dio.get(
          'api/work-experiences/',
          queryParameters: {'cv': activeCvId},
        );

        if (weResponse.statusCode == 200) {
          final List<dynamic> weData = weResponse.data;
          _experiences = weData.map((exp) {
            String formatApiDate(String? date) {
              if (date == null || date.isEmpty) return '';
              try {
                final parts = date.split('-');
                if (parts.length >= 2) return "${parts[1]} / ${parts[0]}";
              } catch (_) {}
              return date;
            }

            return WorkExperience(
              personalDetailsId: 0,
              jobTitle: exp['job_title'] ?? '',
              employer: exp['employer'] ?? '',
              startDate: formatApiDate(exp['start_date']),
              endDate: exp['is_current'] == true ? 'Present' : formatApiDate(exp['end_date']),
              isCurrent: exp['is_current'] ?? false,
              cityState: exp['city_state'] ?? '',
              description: exp['description'] is List 
                  ? (exp['description'] as List).map((i) => "• $i").join('\n') 
                  : (exp['description'] ?? ''),
            );
          }).toList();
        }
        
        // 3. Load Education History
        final eduResponse = await _apiClient.dio.get(
          'api/education/',
          queryParameters: {'cv': activeCvId},
        );

        if (eduResponse.statusCode == 200) {
          final List<dynamic> eduData = eduResponse.data;
          _educationList = eduData.map((edu) {
            return Education(
              personalDetailsId: 0,
              school: edu['school'] ?? '',
              degree: edu['degree'] ?? '',
              startDate: edu['start_date'] ?? '',
              endDate: edu['is_current'] == true ? 'Present' : (edu['end_date'] ?? ''),
              isCurrent: edu['is_current'] ?? false,
              cityState: edu['city_state'] ?? '',
              description: edu['description'] ?? '',
            );
          }).toList();
        }

        // 3b. Load Professional Summary
        final sumResponse = await _apiClient.dio.get(
          'api/summary/',
          queryParameters: {'cv': activeCvId},
        );
        if (sumResponse.statusCode == 200) {
          final List<dynamic> sumData = sumResponse.data;
          if (sumData.isNotEmpty && _personalDetails != null) {
            _personalDetails = _personalDetails!.copyWith(
              summary: sumData.first['summary_text'] ?? '',
            );
          }
        }
        
        // 4. Load Skills
        final skillsResponse = await _apiClient.dio.get(
          'api/skill/',
          queryParameters: {'cv': activeCvId},
        );

        if (skillsResponse.statusCode == 200) {
          final List<dynamic> skillData = skillsResponse.data;
          _skills = skillData.map((s) {
            return Skill(
              personalDetailsId: 0,
              skillName: s['skill_name'] ?? '',
              level: s['level'] ?? 'Skillful',
            );
          }).toList();
        }

        // 5. Load Languages
        final langResponse = await _apiClient.dio.get(
          'api/language/',
          queryParameters: {'cv': activeCvId},
        );

        if (langResponse.statusCode == 200) {
          final List<dynamic> langData = langResponse.data;
          _languages = langData.map((l) {
            return Language(
              personalDetailsId: 0,
              language: l['language'] ?? '',
              level: l['level'] ?? 'Intermediate',
            );
          }).toList();
        }

        // 6. Load Qualities
        final qualityResponse = await _apiClient.dio.get(
          'api/quality/',
          queryParameters: {'cv': activeCvId},
        );
        if (qualityResponse.statusCode == 200) {
          final List<dynamic> qData = qualityResponse.data;
          _qualities = qData.map((q) => Quality(
            personalDetailsId: 0,
            quality: q['quality'] ?? '',
          )).toList();
        }

        // 7. Load Projects
        final projResponse = await _apiClient.dio.get(
          'api/project/',
          queryParameters: {'cv': activeCvId},
        );
        if (projResponse.statusCode == 200) {
          final List<dynamic> pData = projResponse.data;
          _projects = pData.map((p) {
            String desc = '';
            final rawDesc = p['description'];
            if (rawDesc is List) {
              desc = rawDesc.map((i) => "• $i").join('\n');
            } else if (rawDesc is String) {
              // Split by either ' • ' or ', ' for robustness
              desc = rawDesc.split(RegExp(r' • |, '))
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .map((s) => s.startsWith('•') ? s : '• $s')
                  .join('\n');
            }

            return Project(
              personalDetailsId: 0,
              title: p['title'] ?? '',
              technologies: p['technologies'] ?? '',
              description: desc,
              githubLink: p['github_link'] ?? '',
              liveLink: p['live_link'] ?? '',
              playStoreLink: p['playstore_link'] ?? '',
              appStoreLink: p['applestore_link'] ?? '',
            );
          }).toList();
        }

        // 8. Load Certificates
        final certResponse = await _apiClient.dio.get(
          'api/certificate/',
          queryParameters: {'cv': activeCvId},
        );
        if (certResponse.statusCode == 200) {
          final List<dynamic> cData = certResponse.data;
          _certificates = cData.map((c) => Certificate(
            personalDetailsId: 0,
            title: c['title'] ?? '',
            date: c['date'] ?? '',
            description: c['description'] ?? '',
          )).toList();
        }

        // 9. Load References
        final refResponse = await _apiClient.dio.get(
          'api/reference/',
          queryParameters: {'cv': activeCvId},
        );
        if (refResponse.statusCode == 200) {
          final List<dynamic> rData = refResponse.data;
          _references = rData.map((r) => Reference(
            personalDetailsId: 0,
            name: r['name'] ?? '',
            role: r['role'] ?? '',
            company: r['company'] ?? '',
            email: r['email'] ?? '',
            phone: r['phone'] ?? '',
          )).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading CV data from API: $e');
    }

    setState(() => _isLoading = false);
  }

  // Update generate calls to pass _selectedTemplate
  Future<void> _shareDoc() async {
    final bytes = await CVPdfService.generateCV(
      personalDetails: _personalDetails!,
      experiences: _experiences,
      educationList: _educationList,
      skills: _skills,
      languages: _languages,
      qualities: _qualities,
      projects: _projects,
      certificates: _certificates,
      references: _references,
      templateType: _selectedTemplate,
    );
    await Printing.sharePdf(
        bytes: bytes, filename: '${_personalDetails!.firstName}_CV.pdf');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const PreviewSkeleton();
    }
    if (_personalDetails == null) {
      return const Scaffold(body: Center(child: Text('No data found')));
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Main Content (PDF)
          InteractiveViewer(
            transformationController: _transformationController,
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(80),
            minScale: 0.1,
            maxScale: 4.0,
            child: PdfPreview(
              key: ValueKey(
                  _selectedTemplate), // Force rebuild on template change
              build: (format) => CVPdfService.generateCV(
                personalDetails: _personalDetails!,
                experiences: _experiences,
                educationList: _educationList,
                skills: _skills,
                languages: _languages,
                qualities: _qualities,
                projects: _projects,
                certificates: _certificates,
                references: _references,
                templateType: _selectedTemplate,
              ),
              loadingWidget: const PreviewSkeleton(),
              allowPrinting: false,
              allowSharing: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName: '${_personalDetails!.firstName}_CV.pdf',
            ),
          ),

          // 3. Bottom Bar (Zoom + Actions)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.grey[700],
                      tooltip: 'Zoom Out',
                      onPressed: () {
                        final matrix = _transformationController.value.clone();
                        matrix.scale(0.8);
                        _transformationController.value = matrix;
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: Colors.grey[700],
                      tooltip: 'Zoom In',
                      onPressed: () {
                        final matrix = _transformationController.value.clone();
                        matrix.scale(1.25);
                        _transformationController.value = matrix;
                      },
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      color: Colors.blue[700],
                      tooltip: 'Share',
                      onPressed: _shareDoc,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
