import os, re
screens_dir = "/home/maurice/Desktop/projects/cv_builder/lib/screens/"
target_screens = [
    "employment_history_screen.dart",
    "projects_screen.dart",
    "references_screen.dart",
    "certificates_screen.dart",
    "qualities_screen.dart"
]
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
import_statement = "import '../widgets/cv_navigation_menu.dart';\n"
for screen in target_screens:
    filepath = os.path.join(screens_dir, screen)
    if not os.path.exists(filepath): continue
    with open(filepath, 'r') as f: content = f.read()
    if 'cv_navigation_menu.dart' in content: continue
    content = re.sub(r"(import '.*?;)", r"\1\n" + import_statement, content, count=1)
    content = re.sub(r"(\s*Padding\(\s*padding:\s*const EdgeInsets\.only\(right:\s*8\),)", button_code + r"\1", content)
    with open(filepath, 'w') as f: f.write(content)
print("Done")
