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

class ClassicTemplate {
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
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final fontIcons = await PdfGoogleFonts.materialIcons();

    // Blue colors from screenshot
    final darkBlue = PdfColor.fromHex('#1E4F8A'); // Top header blue
    final sidebarBg = PdfColor.fromHex('#F3F6F8'); // Light gray-blue sidebar
    final sectionHeaderBlue = PdfColor.fromHex('#1E4F8A'); // Section titles
    final textBlue = PdfColor.fromHex('#1E4F8A'); // Name in sidebar headers

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          buildBackground: (context) {
            return pw.Row(
              children: [
                pw.Container(
                  width: 200,
                  height: context.page.pageFormat.height,
                  color: sidebarBg,
                ),
                pw.Expanded(
                  child: pw.Container(
                    color: PdfColors.white,
                  ),
                ),
              ],
            );
          },
        ),
        build: (context) {
          return [
            pw.Partitions(
              children: [
                // LEFT SIDEBAR
                pw.Partition(
                  width: 200,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header Shape with Name - Custom Curved Paint
                      pw.Container(
                        height: 110, // Reduced height for tighter fit
                        child: pw.Stack(
                          children: [
                            pw.CustomPaint(
                              size: const PdfPoint(200, 110),
                              painter: (canvas, size) {
                                canvas.setFillColor(darkBlue);
                                // Start Top-Left
                                canvas.moveTo(0, size.y);
                                // Top-Right
                                canvas.lineTo(size.x, size.y);
                                // Bottom-Right (baseline for curve)
                                canvas.lineTo(size.x, 20); // Moved down
                                // Curve to Bottom-Left (convex/smile, dipping down)
                                canvas.curveTo(
                                    size.x * 2 / 3,
                                    0, // C1 (dip to 0)
                                    size.x / 3,
                                    0, // C2 (dip to 0)
                                    0,
                                    20 // End (Bottom-Left baseline)
                                    );
                                // Close to Top-Left
                                canvas.lineTo(0, size.y);
                                canvas.fillPath();
                              },
                            ),
                            pw.Center(
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.only(
                                    bottom: 10, left: 10, right: 10),
                                child: pw.Text(
                                  '${personalDetails.firstName}\n${personalDetails.lastName}',
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 22,
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Personal Details
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(
                            left: 20, right: 20, top: 0),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildSidebarDetail(personalDetails.email, 0xe0be,
                                fontRegular, fontIcons),
                            _buildSidebarDetail(personalDetails.phone, 0xe0cd,
                                fontRegular, fontIcons),
                            if (personalDetails.cityState.isNotEmpty)
                              _buildSidebarDetail(
                                  '${personalDetails.cityState} ${personalDetails.country}',
                                  0xe88a,
                                  fontRegular,
                                  fontIcons),
                            if (personalDetails.dateOfBirth.isNotEmpty)
                              _buildSidebarDetail(personalDetails.dateOfBirth,
                                  0xe935, fontRegular, fontIcons),
                            if (personalDetails.placeOfBirth.isNotEmpty)
                              _buildSidebarDetail(personalDetails.placeOfBirth,
                                  0xe0c8, fontRegular, fontIcons),
                            if (personalDetails.gender.isNotEmpty)
                              _buildSidebarDetail(
                                  personalDetails.gender,
                                  0xe63d,
                                  fontRegular,
                                  fontIcons), // male/female icon?
                            if (personalDetails.nationality.isNotEmpty)
                              _buildSidebarDetail(personalDetails.nationality,
                                  0xe153, fontRegular, fontIcons), // flag

                            if (personalDetails.github.isNotEmpty)
                              _buildSidebarDetail(
                                  'github.com/${personalDetails.github.replaceAll("https://github.com/", "")}',
                                  0xe86f,
                                  fontRegular,
                                  fontIcons),
                            if (personalDetails.linkedin.isNotEmpty)
                              _buildSidebarDetail(
                                  'linkedin.com/in/${personalDetails.linkedin.replaceAll("https://linkedin.com/in/", "").replaceAll("https://www.linkedin.com/in/", "")}',
                                  0xe157,
                                  fontRegular,
                                  fontIcons),

                            pw.SizedBox(height: 30),

                            // Skills
                            if (skills.isNotEmpty) ...[
                              pw.Text(
                                'Skills',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 18,
                                  color: textBlue,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Divider(
                                  color: PdfColors.grey400, thickness: 0.5),
                              pw.SizedBox(height: 10),
                              ...skills.map(
                                  (s) => _buildSkillWithDots(s, fontRegular)),
                            ],

                            // Languages (optional, assuming similar style)
                            if (languages.isNotEmpty) ...[
                              pw.SizedBox(height: 30),
                              pw.Text(
                                'Languages',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 18,
                                  color: textBlue,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Divider(
                                  color: PdfColors.grey400, thickness: 0.5),
                              pw.SizedBox(height: 10),
                              ...languages.map((l) =>
                                  _buildLanguageWithDots(l, fontRegular)),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // RIGHT CONTENT
                pw.Partition(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(
                        left: 30, right: 30, top: 40, bottom: 30),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Objective
                        if (personalDetails.summary.isNotEmpty) ...[
                          _buildMainHeader(
                              'Objective', fontBold, sectionHeaderBlue),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            personalDetails.summary,
                            textAlign: pw.TextAlign.justify,
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 10,
                              lineSpacing: 1.4,
                            ),
                          ),
                          pw.SizedBox(height: 25),
                        ],

                        // Education
                        if (educationList.isNotEmpty) ...[
                          _buildMainHeader(
                              'Education', fontBold, sectionHeaderBlue),
                          pw.SizedBox(height: 10),
                          ...educationList.map((e) => _buildEducationItem(
                              e, fontRegular, fontBold, sectionHeaderBlue)),
                          pw.SizedBox(height: 15),
                        ],

                        // Experience
                        if (experiences.isNotEmpty) ...[
                          _buildMainHeader(
                              'Experience', fontBold, sectionHeaderBlue),
                          pw.SizedBox(height: 10),
                          ...experiences.map((e) => _buildExperienceItem(
                              e, fontRegular, fontBold, sectionHeaderBlue)),
                          pw.SizedBox(height: 15),
                        ],

                        // Projects
                        if (projects.isNotEmpty) ...[
                          _buildMainHeader(
                              'Projects', fontBold, sectionHeaderBlue),
                          pw.SizedBox(height: 10),
                          ...projects.map((p) => _buildProjectItem(
                              p, fontRegular, fontBold, sectionHeaderBlue)),
                          pw.SizedBox(height: 15),
                        ],

                        // Certificates / References if needed (omitted in screenshot but present in data)
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

  static pw.Widget _buildSidebarDetail(
      String text, int iconCode, pw.Font font, pw.Font iconFont) {
    if (text.isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Icon(pw.IconData(iconCode),
              color: PdfColor.fromHex('#1E4F8A'), size: 14, font: iconFont),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSkillWithDots(Skill skill, pw.Font font) {
    int level = 1;
    switch (skill.level.trim().toLowerCase()) {
      case 'novice':
        level = 1;
        break;
      case 'beginner':
        level = 2;
        break;
      case 'skillful':
        level = 3;
        break;
      case 'experienced':
        level = 4;
        break;
      case 'expert':
        level = 5;
        break;
      default:
        level = 3;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(skill.skillName,
                style: pw.TextStyle(font: font, fontSize: 10)),
          ),
          pw.Row(
            children: List.generate(5, (index) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(left: 2),
                child: pw.Container(
                  width: 6,
                  height: 6,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: index < level
                        ? PdfColor.fromHex('#1E4F8A')
                        : PdfColors.grey300,
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  static pw.Widget _buildLanguageWithDots(Language lang, pw.Font font) {
    int level = 1;
    switch (lang.level.trim().toLowerCase()) {
      case 'basic':
        level = 2;
        break;
      case 'intermediate':
        level = 3;
        break;
      case 'advanced':
        level = 4;
        break;
      case 'fluent':
        level = 5;
        break;
      case 'native':
        level = 5;
        break;
      default:
        level = 3;
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(lang.language,
                style: pw.TextStyle(font: font, fontSize: 10)),
          ),
          pw.Row(
            children: List.generate(5, (index) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(left: 2),
                child: pw.Container(
                  width: 6,
                  height: 6,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: index < level
                        ? PdfColor.fromHex('#1E4F8A')
                        : PdfColors.grey300,
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  static pw.Widget _buildMainHeader(
      String title, pw.Font font, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: 22,
            color: color,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Divider(color: PdfColors.grey300, thickness: 1),
      ],
    );
  }

  static pw.Widget _buildEducationItem(
      Education edu, pw.Font font, pw.Font fontBold, PdfColor linkColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 20),
                  child: pw.Text(
                    edu.degree,
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                  ),
                ),
              ),
              pw.Text(
                '${edu.startDate} - ${edu.isCurrent ? 'Present' : (edu.endDate ?? '')}',
                style: pw.TextStyle(font: fontBold, fontSize: 10),
              ),
            ],
          ),
          pw.Text(
            '${edu.school} ${edu.cityState}',
            style: pw.TextStyle(font: font, fontSize: 10, color: linkColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildExperienceItem(
      WorkExperience exp, pw.Font font, pw.Font fontBold, PdfColor linkColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 20),
                  child: pw.Text(
                    exp.jobTitle,
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                  ),
                ),
              ),
              pw.Text(
                '${exp.startDate} - ${exp.isCurrent ? 'Present' : (exp.endDate ?? '')}',
                style: pw.TextStyle(font: fontBold, fontSize: 10),
              ),
            ],
          ),
          pw.Text(
            exp.employer, // + location?
            style: pw.TextStyle(font: font, fontSize: 10, color: linkColor),
          ),
          if (exp.description != null && exp.description!.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: _buildDescriptionSpans(exp.description!, font)
                  .map((span) => pw.RichText(text: span))
                  .toList(),
            )
          ]
        ],
      ),
    );
  }

  static pw.Widget _buildProjectItem(
      Project proj, pw.Font font, pw.Font fontBold, PdfColor linkColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            proj.title,
            style: pw.TextStyle(font: fontBold, fontSize: 12),
          ),
          if (proj.technologies.isNotEmpty)
            pw.Text(
              proj.technologies,
              style: pw.TextStyle(font: font, fontSize: 10, color: linkColor),
            ),
          pw.SizedBox(height: 3),
          pw.Text(
            proj.description,
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
          // Links
          if (proj.githubLink.isNotEmpty)
            pw.Text('Github: ${proj.githubLink}',
                style: pw.TextStyle(font: fontBold, fontSize: 9)),
          if (proj.playStoreLink.isNotEmpty)
            pw.Text('Play Store: ${proj.playStoreLink}',
                style: pw.TextStyle(font: fontBold, fontSize: 9)),
          if (proj.appStoreLink.isNotEmpty)
            pw.Text('App Store: ${proj.appStoreLink}',
                style: pw.TextStyle(font: fontBold, fontSize: 9)),
          if (proj.liveLink.isNotEmpty)
            pw.Text('Live Demo: ${proj.liveLink}',
                style: pw.TextStyle(font: fontBold, fontSize: 9)),
        ],
      ),
    );
  }

  static List<pw.InlineSpan> _buildDescriptionSpans(
      String description, pw.Font font) {
    final List<pw.InlineSpan> spans = [];
    final lines = description.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      if (line.startsWith('•') ||
          line.trim().startsWith('-') ||
          RegExp(r'^\d+\.').hasMatch(line.trim())) {
        spans.add(
          pw.WidgetSpan(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(width: 4),
                pw.Text('•', style: pw.TextStyle(font: font, fontSize: 10)),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Text(
                    line.replaceFirst(RegExp(r'^[\s\d\.\-\•]+'), '').trim(),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      lineSpacing: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        spans.add(
          pw.TextSpan(
            text: '$line\n',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              lineSpacing: 1.4,
            ),
          ),
        );
      }
    }
    return spans;
  }
}
