import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/personal_details.dart';
import '../models/work_experience.dart';
import '../models/education.dart';
import '../models/skill.dart';
import '../models/language.dart';
import '../models/project.dart';
import '../models/certificate.dart';
import '../models/quality.dart';
import '../models/reference.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cv_builder.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 18,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Self-healing migration: check for all required columns in personal_details
    if (oldVersion < 6) {
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='personal_details'");
      if (tables.isNotEmpty) {
        final tableInfo =
            await db.rawQuery('PRAGMA table_info(personal_details)');
        final existingColumns =
            tableInfo.map((c) => c['name'] as String).toSet();

        final requiredColumns = {
          'jobTarget': 'TEXT NOT NULL DEFAULT ""',
          'firstName': 'TEXT NOT NULL DEFAULT ""',
          'lastName': 'TEXT NOT NULL DEFAULT ""',
          'email': 'TEXT NOT NULL DEFAULT ""',
          'phone': 'TEXT NOT NULL DEFAULT ""',
          'address': 'TEXT NOT NULL DEFAULT ""',
          'cityState': 'TEXT NOT NULL DEFAULT ""',
          'country': 'TEXT NOT NULL DEFAULT ""',
          'postalCode': 'TEXT NOT NULL DEFAULT ""',
          'drivingLicense': 'TEXT NOT NULL DEFAULT ""',
          'linkedin': 'TEXT NOT NULL DEFAULT ""',
          'dateOfBirth': 'TEXT DEFAULT ""',
          'placeOfBirth': 'TEXT DEFAULT ""',
          'gender': 'TEXT DEFAULT ""',
          'nationality': 'TEXT DEFAULT ""',
          'github': 'TEXT DEFAULT ""',
          'summary': 'TEXT DEFAULT ""',
          'photoPath': 'TEXT',
          'createdAt': 'TEXT NOT NULL DEFAULT ""',
          'updatedAt': 'TEXT NOT NULL DEFAULT ""',
        };

        for (var entry in requiredColumns.entries) {
          if (!existingColumns.contains(entry.key)) {
            await db.execute(
                'ALTER TABLE personal_details ADD COLUMN ${entry.key} ${entry.value}');
          }
        }
      }
    }

    // Previous migrations (kept for complete path for new installs that might have been at lower versions)
    if (oldVersion < 3) {
      // Check if column exists first to avoid errors if partially migrated
      var tableInfo = await db.rawQuery('PRAGMA table_info(personal_details)');
      bool columnExists =
          tableInfo.any((column) => column['name'] == 'linkedin');

      if (!columnExists) {
        await db.execute(
            'ALTER TABLE personal_details ADD COLUMN linkedin TEXT DEFAULT ""');
      }
    }

    if (oldVersion < 4) {
      // Migration for version 4: city -> cityState
      // In personal_details
      var pdInfo = await db.rawQuery('PRAGMA table_info(personal_details)');
      bool pdCityExists = pdInfo.any((column) => column['name'] == 'city');
      bool pdCityStateExists =
          pdInfo.any((column) => column['name'] == 'cityState');

      if (pdCityExists && !pdCityStateExists) {
        await db.execute(
            'ALTER TABLE personal_details RENAME COLUMN city TO cityState');
      } else if (!pdCityStateExists) {
        await db.execute(
            'ALTER TABLE personal_details ADD COLUMN cityState TEXT DEFAULT ""');
      }

      // In work_experience
      var weInfo = await db.rawQuery('PRAGMA table_info(work_experience)');
      bool weCityExists = weInfo.any((column) => column['name'] == 'city');
      bool weCityStateExists =
          weInfo.any((column) => column['name'] == 'cityState');

      if (weCityExists && !weCityStateExists) {
        await db.execute(
            'ALTER TABLE work_experience RENAME COLUMN city TO cityState');
      } else if (!weCityStateExists) {
        await db.execute(
            'ALTER TABLE work_experience ADD COLUMN cityState TEXT DEFAULT ""');
      }

      // In education
      var edInfo = await db.rawQuery('PRAGMA table_info(education)');
      bool edCityExists = edInfo.any((column) => column['name'] == 'city');
      bool edCityStateExists =
          edInfo.any((column) => column['name'] == 'cityState');

      if (edCityExists && !edCityStateExists) {
        await db
            .execute('ALTER TABLE education RENAME COLUMN city TO cityState');
      } else if (!edCityStateExists) {
        await db.execute(
            'ALTER TABLE education ADD COLUMN cityState TEXT DEFAULT ""');
      }
    }

    if (oldVersion < 5) {
      var pdInfo = await db.rawQuery('PRAGMA table_info(personal_details)');
      bool pdSummaryExists =
          pdInfo.any((column) => column['name'] == 'summary');

      if (!pdSummaryExists) {
        await db.execute(
            'ALTER TABLE personal_details ADD COLUMN summary TEXT DEFAULT ""');
      }
    }
    // Ensure projects table exists regardless of version number
    var projectsTable = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='projects'");
    if (projectsTable.isEmpty) {
      await db.execute('''
        CREATE TABLE projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          personalDetailsId INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          githubLink TEXT,
          liveLink TEXT,
          playStoreLink TEXT,
          appStoreLink TEXT,
          FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
        )
      ''');
    } else {
      // Migration for adding link columns if they don't exist
      var pInfo = await db.rawQuery('PRAGMA table_info(projects)');
      var pColumns = pInfo.map((c) => c['name'] as String).toSet();
      if (!pColumns.contains('liveLink')) {
        await db.execute('ALTER TABLE projects ADD COLUMN liveLink TEXT');
      }
      if (!pColumns.contains('appStoreLink')) {
        await db.execute('ALTER TABLE projects ADD COLUMN appStoreLink TEXT');
      }
      if (!pColumns.contains('technologies')) {
        await db.execute('ALTER TABLE projects ADD COLUMN technologies TEXT');
      }
    }

    // Migration for version 11: Qualities table
    var qualitiesTable = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='qualities'");
    if (qualitiesTable.isEmpty) {
      await db.execute('''
        CREATE TABLE qualities (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          personalDetailsId INTEGER NOT NULL,
          quality TEXT NOT NULL,
          FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
        )
      ''');
    }

    // Migration for version 13: Certificates table
    if (oldVersion < 13) {
      await db.execute('''
        CREATE TABLE certificates(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          personalDetailsId INTEGER NOT NULL,
          title TEXT NOT NULL,
          date TEXT NOT NULL,
          description TEXT NOT NULL,
          FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
        )
      ''');
    }

    // Migration for version 14: References table
    if (oldVersion < 14) {
      await db.execute('''
        CREATE TABLE user_references(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          personalDetailsId INTEGER NOT NULL,
          name TEXT NOT NULL,
          role TEXT NOT NULL,
          company TEXT NOT NULL,
          phone TEXT NOT NULL,
          email TEXT NOT NULL,
          FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
        )
      ''');
    }

    // Self-healing check for certificates and references (fixes issue where v14 might miss them)
    var certificatesTable = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='certificates'");
    if (certificatesTable.isEmpty) {
      await db.execute('''
        CREATE TABLE certificates(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          personalDetailsId INTEGER NOT NULL,
          title TEXT NOT NULL,
          date TEXT NOT NULL,
          description TEXT NOT NULL,
          FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
        )
      ''');
    }

    var referencesTable = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='user_references'");
    if (referencesTable.isEmpty) {
      await db.execute('''
        CREATE TABLE user_references(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          personalDetailsId INTEGER NOT NULL,
          name TEXT NOT NULL,
          role TEXT NOT NULL,
          company TEXT NOT NULL,
          phone TEXT NOT NULL,
          email TEXT NOT NULL,
          FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
        )
      ''');
    }

    // Migration for version 16: isCurrent column in work_experience
    if (oldVersion < 16) {
      final tableInfo = await db.rawQuery('PRAGMA table_info(work_experience)');
      final existingColumns = tableInfo.map((c) => c['name'] as String).toSet();
      if (!existingColumns.contains('isCurrent')) {
        await db.execute(
            'ALTER TABLE work_experience ADD COLUMN isCurrent INTEGER DEFAULT 0');
      }
    }

    // Migration for version 17: isCurrent column in education
    if (oldVersion < 17) {
      final tableInfo = await db.rawQuery('PRAGMA table_info(education)');
      final existingColumns = tableInfo.map((c) => c['name'] as String).toSet();
      if (!existingColumns.contains('isCurrent')) {
        await db.execute(
            'ALTER TABLE education ADD COLUMN isCurrent INTEGER DEFAULT 0');
      }
    }
    
    // Migration for version 18: remoteCvId column in personal_details
    if (oldVersion < 18) {
      final tableInfo = await db.rawQuery('PRAGMA table_info(personal_details)');
      final existingColumns = tableInfo.map((c) => c['name'] as String).toSet();
      if (!existingColumns.contains('remoteCvId')) {
        await db.execute('ALTER TABLE personal_details ADD COLUMN remoteCvId TEXT');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';

    // Create personal_details table
    await db.execute('''
      CREATE TABLE personal_details (
        id $idType,
        jobTarget $textType,
        firstName $textType,
        lastName $textType,
        email $textType,
        phone $textType,
        address $textType,
        cityState $textType,
        country $textType,
        postalCode $textType,
        drivingLicense $textType,
        linkedin $textType,
        dateOfBirth $textNullableType DEFAULT "",
        placeOfBirth $textNullableType DEFAULT "",
        gender $textNullableType DEFAULT "",
        nationality $textNullableType DEFAULT "",
        github $textNullableType DEFAULT "",
        summary $textNullableType DEFAULT "",
        photoPath $textNullableType,
        remoteCvId $textNullableType,
        createdAt $textType,
        updatedAt $textType
      )
    ''');

    // Create education table
    await db.execute('''
      CREATE TABLE education (
        id $idType,
        personalDetailsId INTEGER NOT NULL,
        school $textType,
        degree $textType,
        startDate $textType,
        endDate $textNullableType,
        isCurrent INTEGER DEFAULT 0,
        cityState $textType,
        description $textNullableType,
        FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
      )
    ''');

    // Create work_experience table
    await db.execute('''
      CREATE TABLE work_experience (
        id $idType,
        personalDetailsId INTEGER NOT NULL,
        jobTitle $textType,
        employer $textType,
        startDate $textType,
        endDate $textNullableType,
        isCurrent INTEGER DEFAULT 0,
        cityState $textType,
        description $textNullableType,
        FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
      )
    ''');

    // Create skills table
    await db.execute('''
      CREATE TABLE skills (
        id $idType,
        personalDetailsId INTEGER NOT NULL,
        skillName $textType,
        level $textType,
        FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
      )
    ''');

    // Create languages table
    await db.execute('''
      CREATE TABLE languages (
        id $idType,
        personalDetailsId INTEGER NOT NULL,
        language $textType,
        level $textType,
        FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
      )
    ''');

    // Create qualities table
    await db.execute('''
      CREATE TABLE qualities (
        id $idType,
        personalDetailsId INTEGER NOT NULL,
        quality $textType,
        FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
      )
    ''');

    // Create projects table
    await db.execute('''
      CREATE TABLE projects (
        id $idType,
        personalDetailsId INTEGER NOT NULL,
        title $textType,
        description $textType,
        githubLink $textNullableType,
        liveLink $textNullableType,
        playStoreLink $textNullableType,
        appStoreLink $textNullableType,
        technologies $textNullableType,
        FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
      )
    ''');

    // Create certificates table
    await db.execute('''
      CREATE TABLE certificates (
        id $idType,
        personalDetailsId INTEGER NOT NULL,
        title $textType,
        date $textType,
        description $textType,
        FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
      )
    ''');

    // Create user_references table
    await db.execute('''
      CREATE TABLE user_references (
        id $idType,
        personalDetailsId INTEGER NOT NULL,
        name $textType,
        role $textType,
        company $textType,
        phone $textType,
        email $textType,
        FOREIGN KEY (personalDetailsId) REFERENCES personal_details (id) ON DELETE CASCADE
      )
    ''');
  }

  // ============ Personal Details CRUD Operations ============

  Future<int> insertPersonalDetails(PersonalDetails details) async {
    final db = await database;
    return await db.insert(
      'personal_details',
      details.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PersonalDetails?> getPersonalDetails(int id) async {
    final db = await database;
    final maps = await db.query(
      'personal_details',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return PersonalDetails.fromMap(maps.first);
  }

  Future<List<PersonalDetails>> getAllPersonalDetails() async {
    final db = await database;
    final result = await db.query(
      'personal_details',
      orderBy: 'updatedAt DESC',
    );

    return result.map((map) => PersonalDetails.fromMap(map)).toList();
  }

  Future<PersonalDetails?> getLatestPersonalDetails() async {
    final db = await database;
    final result = await db.query(
      'personal_details',
      orderBy: 'updatedAt DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return PersonalDetails.fromMap(result.first);
  }

  Future<int> updatePersonalDetails(PersonalDetails details) async {
    final db = await database;
    final map = details.copyWith(updatedAt: DateTime.now()).toMap();
    // Remove id from the update map to avoid updating the primary key
    map.remove('id');

    return await db.update(
      'personal_details',
      map,
      where: 'id = ?',
      whereArgs: [details.id],
    );
  }

  Future<int> deletePersonalDetails(int id) async {
    final db = await database;
    return await db.delete(
      'personal_details',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ Work Experience Methods ============

  Future<List<WorkExperience>> getWorkExperiences(int personalDetailsId) async {
    final db = await database;
    final result = await db.query(
      'work_experience',
      where: 'personalDetailsId = ?',
      whereArgs: [personalDetailsId],
    );

    return result.map((map) => WorkExperience.fromMap(map)).toList();
  }

  Future<void> saveWorkExperiences(
      int personalDetailsId, List<WorkExperience> experiences) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete existing ones for this personalDetailsId
      await txn.delete(
        'work_experience',
        where: 'personalDetailsId = ?',
        whereArgs: [personalDetailsId],
      );

      // Insert new ones
      for (var exp in experiences) {
        await txn.insert(
          'work_experience',
          exp.copyWith(personalDetailsId: personalDetailsId).toMap(),
        );
      }
    });
  }

  // ============ Education Methods ============

  Future<List<Education>> getEducation(int personalDetailsId) async {
    final db = await database;
    final result = await db.query(
      'education',
      where: 'personalDetailsId = ?',
      whereArgs: [personalDetailsId],
    );

    return result.map((map) => Education.fromMap(map)).toList();
  }

  Future<void> saveEducation(
      int personalDetailsId, List<Education> educationList) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete existing ones for this personalDetailsId
      await txn.delete(
        'education',
        where: 'personalDetailsId = ?',
        whereArgs: [personalDetailsId],
      );

      // Insert new ones
      for (var edu in educationList) {
        await txn.insert(
          'education',
          edu.copyWith(personalDetailsId: personalDetailsId).toMap(),
        );
      }
    });
  }

  // ============ Skills Methods ============

  Future<List<Skill>> getSkills(int personalDetailsId) async {
    final db = await database;
    final result = await db.query(
      'skills',
      where: 'personalDetailsId = ?',
      whereArgs: [personalDetailsId],
    );

    return result.map((map) => Skill.fromMap(map)).toList();
  }

  Future<void> saveSkills(int personalDetailsId, List<Skill> skills) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete existing ones for this personalDetailsId
      await txn.delete(
        'skills',
        where: 'personalDetailsId = ?',
        whereArgs: [personalDetailsId],
      );

      // Insert new ones
      for (var skill in skills) {
        await txn.insert(
          'skills',
          skill.copyWith(personalDetailsId: personalDetailsId).toMap(),
        );
      }
    });
  }

  // ============ Languages Methods ============

  Future<List<Language>> getLanguages(int personalDetailsId) async {
    final db = await database;
    final result = await db.query(
      'languages',
      where: 'personalDetailsId = ?',
      whereArgs: [personalDetailsId],
    );

    return result.map((map) => Language.fromMap(map)).toList();
  }

  Future<void> saveLanguages(
      int personalDetailsId, List<Language> languages) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'languages',
        where: 'personalDetailsId = ?',
        whereArgs: [personalDetailsId],
      );

      for (var lang in languages) {
        await txn.insert(
          'languages',
          lang.copyWith(personalDetailsId: personalDetailsId).toMap(),
        );
      }
    });
  }

  // ============ Qualities Methods ============

  Future<List<Quality>> getQualities(int personalDetailsId) async {
    final db = await database;
    final result = await db.query(
      'qualities',
      where: 'personalDetailsId = ?',
      whereArgs: [personalDetailsId],
    );

    return result.map((map) => Quality.fromMap(map)).toList();
  }

  Future<void> saveQualities(
      int personalDetailsId, List<Quality> qualities) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'qualities',
        where: 'personalDetailsId = ?',
        whereArgs: [personalDetailsId],
      );

      for (var q in qualities) {
        await txn.insert(
          'qualities',
          q.copyWith(personalDetailsId: personalDetailsId).toMap(),
        );
      }
    });
  }

  // ============ Projects Methods ============

  Future<List<Project>> getProjects(int personalDetailsId) async {
    final db = await database;
    final result = await db.query(
      'projects',
      where: 'personalDetailsId = ?',
      whereArgs: [personalDetailsId],
    );

    return result.map((map) => Project.fromMap(map)).toList();
  }

  Future<void> saveProjects(
      int personalDetailsId, List<Project> projects) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'projects',
        where: 'personalDetailsId = ?',
        whereArgs: [personalDetailsId],
      );

      for (var project in projects) {
        await txn.insert(
          'projects',
          project.copyWith(personalDetailsId: personalDetailsId).toMap(),
        );
      }
    });
  }

  // ============ Certificates Methods ============

  Future<List<Certificate>> getCertificates(int personalDetailsId) async {
    final db = await database;
    final result = await db.query(
      'certificates',
      where: 'personalDetailsId = ?',
      whereArgs: [personalDetailsId],
    );

    return result.map((map) => Certificate.fromMap(map)).toList();
  }

  Future<void> saveCertificates(
      int personalDetailsId, List<Certificate> certificates) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'certificates',
        where: 'personalDetailsId = ?',
        whereArgs: [personalDetailsId],
      );

      for (var cert in certificates) {
        await txn.insert(
          'certificates',
          cert.copyWith(personalDetailsId: personalDetailsId).toMap(),
        );
      }
    });
  }

  // ============ References Methods ============

  Future<List<Reference>> getReferences(int personalDetailsId) async {
    final db = await database;
    final result = await db.query(
      'user_references',
      where: 'personalDetailsId = ?',
      whereArgs: [personalDetailsId],
    );

    return result.map((map) => Reference.fromMap(map)).toList();
  }

  Future<void> saveReferences(
      int personalDetailsId, List<Reference> references) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'user_references',
        where: 'personalDetailsId = ?',
        whereArgs: [personalDetailsId],
      );

      for (var ref in references) {
        await txn.insert(
          'user_references',
          ref.copyWith(personalDetailsId: personalDetailsId).toMap(),
        );
      }
    });
  }

  // ============ Utility Methods ============

  Future<int> getPersonalDetailsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM personal_details');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('personal_details');
    await db.delete('education');
    await db.delete('work_experience');
    await db.delete('skills');
    await db.delete('projects');
    await db.delete('languages');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Reset database (for development/testing)
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cv_builder.db');
    await deleteDatabase(path);
    _database = null;
  }
}
