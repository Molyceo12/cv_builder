import os
import re

screens_dir = "/home/maurice/Desktop/projects/cv_builder/lib/screens/"
target_screens = [
    "personal_details_screen.dart",
    "professional_summary_screen.dart",
    "employment_history_screen.dart",
    "education_history_screen.dart",
    "skills_screen.dart",
    "projects_screen.dart",
    "languages_screen.dart",
    "references_screen.dart",
    "certificates_screen.dart",
    "qualities_screen.dart"
]

import_statement = "import '../widgets/cv_navigation_menu.dart';\n"
button_code = """
          IconButton(
            onPressed: () => CvNavigationMenu.show(context),
            tooltip: 'CV Sections',
            icon: const Icon(
              Icons.menu_open_rounded,
              color: Color(0xFF1F2937),
              size: 24,
            ),
          ),
"""

for screen in target_screens:
    filepath = os.path.join(screens_dir, screen)
    if not os.path.exists(filepath):
        continue
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Check if already added
    if 'cv_navigation_menu.dart' in content and screen != "personal_details_screen.dart":
        continue

    if screen != "personal_details_screen.dart":
        # Add import after the last import
        content = re.sub(r"(import '.*?;)", r"\1\n" + import_statement, content, count=1)
        
        # We need to find the actions: [ ... ] array and insert the button before the Padding or TextButton (Save)
        # Actually, let's insert it right after the tooltip: 'Preview CV', ... ),
        content = re.sub(r"(tooltip:\s*'Preview CV',\s*\n\s*\),)", r"\1" + button_code, content)
        
        with open(filepath, 'w') as f:
            f.write(content)

print("Patching complete.")
