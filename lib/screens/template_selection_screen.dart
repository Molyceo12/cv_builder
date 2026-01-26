import 'package:flutter/material.dart';
import 'cv_preview_screen.dart';

class TemplateSelectionScreen extends StatelessWidget {
  const TemplateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/images/cv_icon.jpeg',
                height: 24,
                width: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Choose Template',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Select a template for your resume',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildTemplateCard(
                    context,
                    title: 'Professional',
                    description: 'Modern design with a sidebar',
                    color: const Color(0xFF004D40), // Teal/Dark Green
                    templateType: 'modern',
                    isPromoted: true,
                  ),
                  _buildTemplateCard(
                    context,
                    title: 'Prime ATS',
                    description: 'Clean, classic layout',
                    color: Colors.white,
                    templateType: 'classic',
                    borderColor: const Color(0xFF1E4F8A),
                    textColor: Colors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color color,
    required String templateType,
    bool isPromoted = false,
    Color borderColor = Colors.transparent,
    Color textColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CVPreviewScreen(initialTemplate: templateType),
          ),
        );
      },
      child: Container(
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: isPromoted
              ? Border.all(color: const Color(0xFF0056D2), width: 3)
              : Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header / Title Area
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            // Preview Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: templateType == 'modern'
                      ? _buildModernPreview()
                      : _buildClassicPreview(),
                ),
              ),
            ),
            // Button Area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CVPreviewScreen(initialTemplate: templateType),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPromoted ? const Color(0xFF0056D2) : Colors.white,
                  foregroundColor:
                      isPromoted ? Colors.white : const Color(0xFF0056D2),
                  side: isPromoted
                      ? null
                      : const BorderSide(color: Color(0xFF0056D2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Use This Template',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mockup for Modern Template
  Widget _buildModernPreview() {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 80, // roughly 1/3
          color: const Color(0xFF004D40), // Dark Green
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(height: 8),
              _line(Colors.white54, width: 40),
              _line(Colors.white54, width: 30),
              const SizedBox(height: 12),
              _line(Colors.white54, width: 50),
              _line(Colors.white54, width: 50),
              _line(Colors.white54, width: 50),
            ],
          ),
        ),
        // Main Content
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(Colors.black87, height: 6, width: 100),
                const SizedBox(height: 4),
                _line(Colors.grey, height: 3, width: 80),
                const SizedBox(height: 12),
                _line(Colors.black54, width: double.infinity),
                const SizedBox(height: 2),
                _line(Colors.black54, width: double.infinity),
                const SizedBox(height: 2),
                _line(Colors.black54, width: 120),
                const SizedBox(height: 8),
                _line(Colors.black87, height: 4, width: 60), // Section Title
                const SizedBox(height: 4),
                _line(Colors.black54, width: double.infinity),
                const SizedBox(height: 2),
                _line(Colors.black54, width: double.infinity),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Mockup for Classic Template
  Widget _buildClassicPreview() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HERMAN WALTON',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'FINANCIAL ANALYST',
                      style: TextStyle(
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                color: Colors.grey[300],
                child: const Icon(Icons.person, size: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _line(Colors.blue[800]!, height: 1), // Divider
          const SizedBox(height: 4),
          _line(Colors.black87, height: 3, width: 40), // Section Header
          const SizedBox(height: 2),
          _line(Colors.black54, width: double.infinity),
          const SizedBox(height: 2),
          _line(Colors.black54, width: double.infinity),
          const SizedBox(height: 6),
          _line(Colors.blue[800]!, height: 1), // Divider
          const SizedBox(height: 4),
          _line(Colors.black87, height: 3, width: 50), // Section Header
          const SizedBox(height: 2),
          _line(Colors.black54, width: double.infinity),
          const SizedBox(height: 2),
          _line(Colors.black54, width: double.infinity),
        ],
      ),
    );
  }

  Widget _line(Color color, {double height = 2, double width = 20}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
