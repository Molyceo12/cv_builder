import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../database/database_helper.dart';
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

class CVPreviewScreen extends StatefulWidget {
  final String initialTemplate;
  const CVPreviewScreen({super.key, this.initialTemplate = 'modern'});

  @override
  State<CVPreviewScreen> createState() => _CVPreviewScreenState();
}

class _CVPreviewScreenState extends State<CVPreviewScreen> {
  final _dbHelper = DatabaseHelper.instance;
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
    final details = await _dbHelper.getLatestPersonalDetails();
    if (details != null) {
      _experiences = await _dbHelper.getWorkExperiences(details.id!);
      _educationList = await _dbHelper.getEducation(details.id!);
      _skills = await _dbHelper.getSkills(details.id!);
      _languages = await _dbHelper.getLanguages(details.id!);
      _qualities = await _dbHelper.getQualities(details.id!);
      _projects = await _dbHelper.getProjects(details.id!);
      _certificates = await _dbHelper.getCertificates(details.id!);
      _references = await _dbHelper.getReferences(details.id!);
      setState(() {
        _personalDetails = details;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
