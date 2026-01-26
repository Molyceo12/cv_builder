import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/personal_details.dart';
import '../models/work_experience.dart';
import '../models/education.dart';
import '../models/skill.dart';
import '../models/project.dart';
import '../models/language.dart';
import '../models/certificate.dart';
import '../models/reference.dart';
import '../models/quality.dart';

class ModernGreenTemplate {
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
  }) async {
    // 1. Setup fonts
    final fontLato = await PdfGoogleFonts.latoRegular();
    final fontLatoBold = await PdfGoogleFonts.latoBold();
    final fontMerriweatherBold = await PdfGoogleFonts.merriweatherBold();
    final fontIcons = await PdfGoogleFonts.materialIcons();

    // 2. Define the Page Theme with background
    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      buildBackground: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [
                PdfColor.fromHex('#064E3B'),
                PdfColor.fromHex('#064E3B'),
                PdfColors.white,
                PdfColors.white,
              ],
              stops: [0, 190 / 595.27, 190 / 595.27, 1], // A4 width is 595.27
            ),
          ),
        );
      },
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (context) {
          return [
            pw.Partitions(
              children: [
                // Left Sidebar
                pw.Partition(
                  width: 190,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // Personal Details Block
                      pw.Container(
                        color: PdfColor.fromHex('#064E3B'),
                        padding: const pw.EdgeInsets.only(
                            left: 20, right: 20, top: 25, bottom: 10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '${personalDetails.firstName} ${personalDetails.lastName}'
                                  .trim(),
                              style: pw.TextStyle(
                                font: fontMerriweatherBold,
                                fontSize: 20,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.SizedBox(height: 20),
                            pw.Text(
                              'Personal details',
                              style: pw.TextStyle(
                                font: fontMerriweatherBold,
                                fontSize: 16,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            _buildContactItem(personalDetails.email, fontLato,
                                fontIcons, 0xe0be, PdfColors.white),
                            _buildContactItem(personalDetails.phone, fontLato,
                                fontIcons, 0xe0cd, PdfColors.white),
                            if (personalDetails.address.isNotEmpty ||
                                personalDetails.cityState.isNotEmpty ||
                                personalDetails.country.isNotEmpty)
                              _buildContactItem(
                                  '${personalDetails.address}, ${personalDetails.cityState}, ${personalDetails.country}'
                                      .replaceAll(RegExp(r'^, |,$'), '')
                                      .replaceAll(', ,', ','),
                                  fontLato,
                                  fontIcons,
                                  0xe88a,
                                  PdfColors.white),
                            if (personalDetails.dateOfBirth.isNotEmpty)
                              _buildContactItem(personalDetails.dateOfBirth,
                                  fontLato, fontIcons, 0xe935, PdfColors.white),
                            if (personalDetails.placeOfBirth.isNotEmpty)
                              _buildContactItem(personalDetails.placeOfBirth,
                                  fontLato, fontIcons, 0xe0c8, PdfColors.white),
                            _buildContactItem(personalDetails.gender, fontLato,
                                fontIcons, 0xe7fd, PdfColors.white),
                            _buildContactItem(personalDetails.nationality,
                                fontLato, fontIcons, 0xe80b, PdfColors.white),
                            if (personalDetails.github.isNotEmpty)
                              _buildContactItem(
                                  'github.com/${(personalDetails.github).replaceAll("https://github.com/", "")}',
                                  fontLato,
                                  fontIcons,
                                  0xe86f,
                                  PdfColors.white),
                            if (personalDetails.linkedin.isNotEmpty)
                              _buildContactItem(
                                  'linkedin.com/in/${(personalDetails.linkedin).replaceAll("https://linkedin.com/in/", "").replaceAll("https://www.linkedin.com/in/", "")}',
                                  fontLato,
                                  fontIcons,
                                  0xe157,
                                  PdfColors.white),
                          ],
                        ),
                      ),
                      // Skills Block
                      if (skills.isNotEmpty)
                        pw.Container(
                          color: PdfColor.fromHex('#064E3B'),
                          padding:
                              const pw.EdgeInsets.symmetric(horizontal: 20),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(height: 15),
                              pw.Text(
                                'Skills',
                                style: pw.TextStyle(
                                  font: fontMerriweatherBold,
                                  fontSize: 16,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.SizedBox(height: 10),
                              ...skills.map(
                                  (skill) => _buildSkillItem(skill, fontLato)),
                            ],
                          ),
                        ),
                      // Languages Block
                      if (languages.isNotEmpty)
                        pw.Container(
                          color: PdfColor.fromHex('#064E3B'),
                          padding:
                              const pw.EdgeInsets.symmetric(horizontal: 20),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(height: 25),
                              pw.Text(
                                'Languages',
                                style: pw.TextStyle(
                                  font: fontMerriweatherBold,
                                  fontSize: 16,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.SizedBox(height: 10),
                              ...languages.map(
                                  (lang) => _buildLanguageItem(lang, fontLato)),
                            ],
                          ),
                        ),
                      // Qualities Block
                      if (qualities.isNotEmpty)
                        pw.Container(
                          color: PdfColor.fromHex('#064E3B'),
                          padding:
                              const pw.EdgeInsets.symmetric(horizontal: 20),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(height: 25),
                              pw.Text(
                                'Qualities',
                                style: pw.TextStyle(
                                  font: fontMerriweatherBold,
                                  fontSize: 16,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.SizedBox(height: 10),
                              ...qualities.map((q) =>
                                  _buildQualityItem(q.quality, fontLato)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Right Content
                pw.Partition(
                  width: 380,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(
                        left: 30, right: 30, top: 25, bottom: 25),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (personalDetails.summary.isNotEmpty) ...[
                          pw.Text(
                            'Profile',
                            style: pw.TextStyle(
                              font: fontMerriweatherBold,
                              fontSize: 18,
                              color: PdfColor.fromHex('#1F2937'),
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Divider(
                              color: PdfColor.fromHex('#374151'), thickness: 1),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            personalDetails.summary,
                            style: pw.TextStyle(
                              font: fontLato,
                              fontSize: 11,
                              color: PdfColor.fromHex('#374151'),
                              lineSpacing: 1.5,
                            ),
                          ),
                          pw.SizedBox(height: 15),
                        ],
                        if (experiences.isNotEmpty) ...[
                          pw.Text(
                            'Experience',
                            style: pw.TextStyle(
                              font: fontMerriweatherBold,
                              fontSize: 22,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Divider(
                              color: PdfColor.fromHex('#374151'), thickness: 1),
                          pw.SizedBox(height: 10),
                          ...experiences.expand((exp) => _buildExperienceItem(
                              exp, fontLato, fontLatoBold)),
                        ],
                        if (educationList.isNotEmpty) ...[
                          pw.SizedBox(height: 15),
                          pw.Text(
                            'Education',
                            style: pw.TextStyle(
                              font: fontMerriweatherBold,
                              fontSize: 22,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Divider(
                              color: PdfColor.fromHex('#374151'), thickness: 1),
                          pw.SizedBox(height: 10),
                          ...educationList.expand((edu) =>
                              _buildEducationItem(edu, fontLato, fontLatoBold)),
                        ],
                        if (projects.isNotEmpty) ...[
                          pw.SizedBox(height: 15),
                          pw.Text(
                            'Projects',
                            style: pw.TextStyle(
                              font: fontMerriweatherBold,
                              fontSize: 22,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Divider(
                              color: PdfColor.fromHex('#374151'), thickness: 1),
                          pw.SizedBox(height: 10),
                          ...projects.expand((p) =>
                              _buildProjectItem(p, fontLato, fontLatoBold)),
                        ],
                        if (certificates.isNotEmpty) ...[
                          pw.SizedBox(height: 15),
                          pw.Text(
                            'Certificates',
                            style: pw.TextStyle(
                              font: fontMerriweatherBold,
                              fontSize: 18,
                              color: PdfColor.fromHex('#1F2937'),
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Divider(
                              color: PdfColor.fromHex('#374151'), thickness: 1),
                          pw.SizedBox(height: 10),
                          ...certificates.expand((c) =>
                              _buildCertificateItem(c, fontLato, fontLatoBold)),
                        ],
                        if (references.isNotEmpty) ...[
                          pw.SizedBox(height: 15),
                          pw.Text(
                            'References',
                            style: pw.TextStyle(
                              font: fontMerriweatherBold,
                              fontSize: 22,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Divider(
                              color: PdfColor.fromHex('#374151'), thickness: 1),
                          pw.SizedBox(height: 10),
                          ...references.expand((r) =>
                              _buildReferenceItem(r, fontLato, fontLatoBold)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildContactItem(String text, pw.Font font,
      pw.Font iconFont, int iconCodePoint, PdfColor color) {
    if (text.isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Icon(pw.IconData(iconCodePoint),
              color: color, size: 12, font: iconFont),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildDetailedDescription(
      String? description, pw.Font font) {
    if (description == null || description.isEmpty) return [];
    final List<pw.Widget> widgets = [];
    final lines = description.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (trimmedLine.startsWith('•') ||
          trimmedLine.startsWith('-') ||
          RegExp(r'^\d+\.').hasMatch(trimmedLine)) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 4, top: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('•', style: pw.TextStyle(font: font, fontSize: 10)),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Text(
                    trimmedLine
                        .replaceFirst(RegExp(r'^[\s\d\.\-\•]+'), '')
                        .trim(),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColor.fromHex('#4B5563'),
                      lineSpacing: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              trimmedLine,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColor.fromHex('#4B5563'),
                lineSpacing: 1.4,
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  static pw.Widget _buildSkillItem(Skill skill, pw.Font font) {
    double progress = 0.6;

    switch (skill.level.trim().toLowerCase()) {
      case 'novice':
        progress = 0.15;
        break;
      case 'beginner':
        progress = 0.3;
        break;
      case 'skillful':
        progress = 0.6;
        break;
      case 'experienced':
        progress = 0.85;
        break;
      case 'expert':
        progress = 1.0;
        break;
    }

    // Color logic - Uniform White as requested
    PdfColor barColor = PdfColors.white;

    const double barWidth = 160;
    const double barHeight = 6;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            skill.skillName,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          // Bar with left rounding
          pw.Stack(
            children: [
              pw.Container(
                width: barWidth,
                height: barHeight,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey,
                  borderRadius:
                      pw.BorderRadius.horizontal(left: pw.Radius.circular(3)),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Container(
                  width: barWidth * progress,
                  height: barHeight,
                  decoration: pw.BoxDecoration(
                    color: barColor,
                    borderRadius: const pw.BorderRadius.horizontal(
                        left: pw.Radius.circular(3)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLanguageItem(Language lang, pw.Font font) {
    double progress = 0.6;
    switch (lang.level.trim().toLowerCase()) {
      case 'basic':
        progress = 0.2;
        break;
      case 'intermediate':
        progress = 0.45;
        break;
      case 'advanced':
        progress = 0.7;
        break;
      case 'fluent':
        progress = 0.9;
        break;
      case 'native':
        progress = 1.0;
        break;
    }

    PdfColor barColor = PdfColors.white;

    const double barWidth = 160;
    const double barHeight = 6;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            lang.language,
            style:
                pw.TextStyle(font: font, fontSize: 10, color: PdfColors.white),
          ),
          pw.SizedBox(height: 4),
          pw.Stack(
            children: [
              pw.Container(
                width: barWidth, // Adjusted width
                height: barHeight,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey,
                  borderRadius:
                      pw.BorderRadius.horizontal(left: pw.Radius.circular(3)),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Container(
                  width: barWidth * progress,
                  height: barHeight,
                  decoration: pw.BoxDecoration(
                    color: barColor,
                    borderRadius: const pw.BorderRadius.horizontal(
                        left: pw.Radius.circular(3)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildQualityItem(String quality, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, right: 8),
            width: 4,
            height: 4,
            color: PdfColors.white,
          ),
          pw.Expanded(
            child: pw.Text(
              quality,
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.white),
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildExperienceItem(
      WorkExperience exp, pw.Font font, pw.Font fontBold) {
    return [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(right: 20),
              child: pw.Text(
                exp.jobTitle,
                style: pw.TextStyle(
                    font: fontBold, fontSize: 12, color: PdfColors.black),
              ),
            ),
          ),
          pw.Text(
            '${exp.startDate} - ${exp.isCurrent ? 'Present' : (exp.endDate ?? '')}',
            style: pw.TextStyle(
                font: fontBold,
                fontSize: 10,
                color: PdfColors.black), // Bold date
          ),
        ],
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        '${exp.employer}, ${exp.cityState}', // Employer, Location
        style: pw.TextStyle(
            font: font,
            fontSize: 10,
            color: PdfColor.fromHex('#2079C3')), // Blue color for company
      ),
      if (exp.description != null && exp.description!.isNotEmpty) ...[
        pw.SizedBox(height: 5),
        ..._buildDetailedDescription(exp.description ?? '', font),
      ],
      pw.SizedBox(height: 10),
    ];
  }

  static List<pw.Widget> _buildEducationItem(
      Education edu, pw.Font font, pw.Font fontBold) {
    return [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(right: 20),
              child: pw.Text(
                edu.degree,
                style: pw.TextStyle(
                    font: fontBold, fontSize: 12, color: PdfColors.black),
              ),
            ),
          ),
          pw.Text(
            '${edu.startDate} - ${edu.isCurrent ? 'Present' : (edu.endDate ?? '')}',
            style: pw.TextStyle(
                font: fontBold, fontSize: 10, color: PdfColors.black),
          ),
        ],
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        '${edu.school}, ${edu.cityState}',
        style: pw.TextStyle(
            font: font,
            fontSize: 10,
            color: PdfColor.fromHex('#2079C3')), // Blue color
      ),
      pw.SizedBox(height: 10),
    ];
  }

  static List<pw.Widget> _buildProjectItem(
      Project project, pw.Font font, pw.Font fontBold) {
    return [
      pw.Text(
        project.title,
        style:
            pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.black),
      ),
      if (project.technologies.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Text(
          project.technologies,
          style: pw.TextStyle(
              font: font, fontSize: 10, color: PdfColor.fromHex('#2079C3')),
        ),
      ],
      pw.SizedBox(height: 5),
      ..._buildDetailedDescription(project.description, font),
      if (project.githubLink.isNotEmpty) ...[
        pw.SizedBox(height: 3),
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: 'Githubrepo: ',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 10, color: PdfColors.black),
              ),
              pw.TextSpan(
                text: project.githubLink,
                style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColor.fromHex('#374151')),
              ),
            ],
          ),
        ),
      ],
      if (project.liveLink.isNotEmpty) ...[
        pw.SizedBox(height: 3),
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: 'Live Link: ',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 10, color: PdfColors.black),
              ),
              pw.TextSpan(
                text: project.liveLink,
                style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColor.fromHex('#374151')),
              ),
            ],
          ),
        ),
      ],
      if (project.playStoreLink.isNotEmpty) ...[
        pw.SizedBox(height: 3),
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: 'Google Play: ',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 10, color: PdfColors.black),
              ),
              pw.TextSpan(
                text: project.playStoreLink,
                style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColor.fromHex('#374151')),
              ),
            ],
          ),
        ),
      ],
      if (project.appStoreLink.isNotEmpty) ...[
        pw.SizedBox(height: 3),
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: 'App Store: ',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 10, color: PdfColors.black),
              ),
              pw.TextSpan(
                text: project.appStoreLink,
                style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColor.fromHex('#374151')),
              ),
            ],
          ),
        ),
      ],
      pw.SizedBox(height: 10),
    ];
  }

  static List<pw.Widget> _buildCertificateItem(
      Certificate cert, pw.Font font, pw.Font fontBold) {
    return [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              cert.title,
              style: pw.TextStyle(
                  font: fontBold, fontSize: 12, color: PdfColors.black),
            ),
          ),
          pw.Text(
            cert.date,
            style: pw.TextStyle(
                font: fontBold, fontSize: 10, color: PdfColors.black),
          ),
        ],
      ),
      pw.SizedBox(height: 5),
      ..._buildDetailedDescription(cert.description, font),
      pw.SizedBox(height: 10),
    ];
  }

  static List<pw.Widget> _buildReferenceItem(
      Reference ref, pw.Font font, pw.Font fontBold) {
    return [
      pw.Text(
        ref.name,
        style:
            pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.black),
      ),
      if (ref.role.isNotEmpty || ref.company.isNotEmpty)
        pw.Text(
          '${ref.role}${ref.role.isNotEmpty && ref.company.isNotEmpty ? ', ' : ''}${ref.company}',
          style: pw.TextStyle(
              font: font, fontSize: 10, color: PdfColor.fromHex('#2079C3')),
        ),
      if (ref.phone.isNotEmpty)
        pw.Text(
          ref.phone,
          style: pw.TextStyle(
              font: fontBold, fontSize: 10, color: PdfColors.black),
        ),
      if (ref.email.isNotEmpty)
        pw.Text(
          ref.email,
          style: pw.TextStyle(
              font: fontBold, fontSize: 10, color: PdfColors.black),
        ),
      pw.SizedBox(height: 10),
    ];
  }
}
