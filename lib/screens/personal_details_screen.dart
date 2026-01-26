import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../database/database_helper.dart';
import '../models/personal_details.dart';
import 'employment_history_screen.dart';
import 'template_selection_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final String? cvId;
  const PersonalDetailsScreen({super.key, this.cvId});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper.instance;
  final _apiClient = ApiClient();
  int? _currentDetailsId;
  PersonalDetails? _details; // Keep the full object
  bool _isLoading = true;
  bool _isSavingRemote = false;

  // Controllers
  final _summaryController = TextEditingController();
  final _jobTargetController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityStateController = TextEditingController();
  final _countryController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _drivingLicenseController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  final _genderController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _githubController = TextEditingController();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadPersonalDetails();
    _setupAutoSave();
  }

  Future<void> _loadPersonalDetails() async {
    setState(() => _isLoading = true);

    try {
      // 1. Load from local DB first (if any)
      final personalDetails = await _dbHelper.getLatestPersonalDetails();
      
      // Get ID from SharedPreferences if missing from widget
      String? activeCvId = widget.cvId;
      if (activeCvId == null) {
        final prefs = await SharedPreferences.getInstance();
        activeCvId = prefs.getString('active_cv_id');
      }

      // 2. If we have a remote ID, try to fetch from server
      if (activeCvId != null) {
        await _loadRemotePersonalDetails(activeCvId);
      } else if (personalDetails != null) {
        _currentDetailsId = personalDetails.id;
        _details = personalDetails;
        _jobTargetController.text = personalDetails.jobTarget;
        _firstNameController.text = personalDetails.firstName;
        _lastNameController.text = personalDetails.lastName;
        _emailController.text = personalDetails.email;
        _phoneController.text = personalDetails.phone;
        _addressController.text = personalDetails.address;
        _cityStateController.text = personalDetails.cityState;
        _countryController.text = personalDetails.country;
        _postalCodeController.text = personalDetails.postalCode;
        _drivingLicenseController.text = personalDetails.drivingLicense;
        _linkedinController.text = personalDetails.linkedin;
        _dateOfBirthController.text = personalDetails.dateOfBirth;
        _placeOfBirthController.text = personalDetails.placeOfBirth;
        _genderController.text = personalDetails.gender;
        _nationalityController.text = personalDetails.nationality;
        _githubController.text = personalDetails.github;
      }
    } catch (e) {
      debugPrint('Error loading personal details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading data: $e'),
              backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadRemotePersonalDetails(String activeCvId) async {
    try {
      final response = await _apiClient.dio.get(
        'api/personal-details/',
        queryParameters: {'cv': activeCvId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (data.isNotEmpty) {
          final remoteData = data[0]; // Take the first item as advised
          
          // Split full name back into first and last if possible
          String fullName = remoteData['full_name'] ?? "";
          List<String> nameParts = fullName.split(' ');
          
          _firstNameController.text = nameParts.length > 0 ? nameParts[0] : "";
          _lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";
          
          _emailController.text = remoteData['email'] ?? "";
          _phoneController.text = remoteData['phone'] ?? "";
          _addressController.text = remoteData['address'] ?? "";
          _summaryController.text = remoteData['summary'] ?? "";
          
          debugPrint('✅ [FETCH] Successfully loaded remote data for CV: $activeCvId');
        }
      }
    } catch (e) {
      debugPrint('❌ [FETCH] Error loading remote data: $e');
    }
  }

  void _setupAutoSave() {
    // Add listeners to auto-save on text change (debounced)
    // using a helper to avoid repetitive code
    void addListener(TextEditingController controller) {
      controller.addListener(_autoSave);
    }

    addListener(_jobTargetController);
    addListener(_firstNameController);
    addListener(_lastNameController);
    addListener(_emailController);
    addListener(_phoneController);
    addListener(_addressController);
    addListener(_cityStateController);
    addListener(_countryController);
    addListener(_postalCodeController);
    addListener(_drivingLicenseController);
    addListener(_linkedinController);
    addListener(_dateOfBirthController);
    addListener(_placeOfBirthController);
    addListener(_genderController);
    addListener(_nationalityController);
    addListener(_githubController);
    addListener(_summaryController);
  }

  void _autoSave() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      _savePersonalDetails();
    });
  }

  Future<void> _savePersonalDetails() async {
    if (_isLoading) return;

    final details = (_details ??
            PersonalDetails(
              jobTarget: '',
              firstName: '',
              lastName: '',
              email: '',
              phone: '',
              address: '',
              cityState: '',
              country: '',
              postalCode: '',
              drivingLicense: '',
              linkedin: '',
            ))
        .copyWith(
      id: _currentDetailsId,
      jobTarget: _jobTargetController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      cityState: _cityStateController.text,
      country: _countryController.text,
      postalCode: _postalCodeController.text,
      drivingLicense: _drivingLicenseController.text,
      linkedin: _linkedinController.text,
      dateOfBirth: _dateOfBirthController.text,
      placeOfBirth: _placeOfBirthController.text,
      gender: _genderController.text,
      nationality: _nationalityController.text,
      github: _githubController.text,
    );

    try {
      if (_currentDetailsId == null) {
        _currentDetailsId = await _dbHelper.insertPersonalDetails(details);
        _details = details.copyWith(id: _currentDetailsId);
      } else {
        await _dbHelper.updatePersonalDetails(details);
        _details = details;
      }

      // Remote Sync
      if (widget.cvId != null) {
        await _saveRemoteDetails();
      } else {
        debugPrint('⚠️ [SYNC] Skipping remote sync: No CV ID provided to this screen.');
      }
    } catch (e) {
      debugPrint('Error saving personal details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving data: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveRemoteDetails() async {
    if (_isSavingRemote) return;
    debugPrint('🚀 [SYNC] Initiating remote sync for CV ID: ${widget.cvId}');
    setState(() => _isSavingRemote = true);

    try {
      final data = {
        "cv": widget.cvId,
        "full_name": "${_firstNameController.text} ${_lastNameController.text}",
        "email": _emailController.text,
        "phone": _phoneController.text,
        "address": _addressController.text,
        "summary": _summaryController.text,
      };

      await _apiClient.dio.post(
        'api/personal-details/',
        data: data,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      debugPrint('🆕 [SYNC] Remote record saved via POST');
    } catch (e) {
      debugPrint('Error syncing remote details: $e');
    } finally {
      if (mounted) setState(() => _isSavingRemote = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _jobTargetController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityStateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _drivingLicenseController.dispose();
    _linkedinController.dispose();
    _dateOfBirthController.dispose();
    _placeOfBirthController.dispose();
    _genderController.dispose();
    _nationalityController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/cv_icon.jpeg',
            height: 32,
            width: 32,
            fit: BoxFit.cover,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TemplateSelectionScreen(),
                ),
              );
            },
            tooltip: 'Preview CV',
            icon: const Icon(
              Icons.remove_red_eye_outlined,
              color: Color(0xFF1F2937),
              size: 22,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () async {
                await _savePersonalDetails();
                if (mounted) {
                  final status = widget.cvId != null ? 'Synced to cloud' : 'Saved locally';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Personal details saved! ($status)'),
                      backgroundColor: const Color(0xFF10B981),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '10%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Your resume score',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          '+10%',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Complete details',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Container(
              height: 4,
              color: const Color(0xFFF3F4F6),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.1,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                    ),
                  ),
                ),
              ),
            ),

            // Form content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Users who added phone number and email received 64% more positive feedback from recruiters.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // First Name and Last Name
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'First Name',
                            controller: _firstNameController,
                            hint: 'e.g. John',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFormField(
                            label: 'Last Name',
                            controller: _lastNameController,
                            hint: 'e.g. Doe',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Email and Phone
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Email*',
                            controller: _emailController,
                            hint: 'e.g. john.doe@example.com',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFormField(
                            label: 'Phone',
                            controller: _phoneController,
                            hint: 'e.g. +1 234 567 890',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address
                    _buildFormField(
                      label: 'Address',
                      controller: _addressController,
                      hint: 'e.g. 123 Main St',
                    ),
                    const SizedBox(height: 16),

                    // City, State and Country
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'City, State',
                            controller: _cityStateController,
                            hint: 'e.g. New York, NY',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFormField(
                            label: 'Country',
                            controller: _countryController,
                            hint: 'e.g. United States',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth and Place of Birth
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Date of Birth',
                            controller: _dateOfBirthController,
                            hint: 'e.g. 1990-01-01',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFormField(
                            label: 'Place of Birth',
                            controller: _placeOfBirthController,
                            hint: 'e.g. New York',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gender and Nationality
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Gender',
                            controller: _genderController,
                            hint: 'e.g. Male/Female',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFormField(
                            label: 'Nationality',
                            controller: _nationalityController,
                            hint: 'e.g. American',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // LinkedIn Profile
                    _buildFormField(
                      label: 'LinkedIn Profile',
                      controller: _linkedinController,
                      hint: 'e.g. linkedin.com/in/johndoe',
                    ),
                    const SizedBox(height: 16),
                    // GitHub Profile
                    _buildFormField(
                      label: 'GitHub Profile',
                      controller: _githubController,
                      hint: 'e.g. github.com/johndoe',
                    ),
                    // Professional Summary
                    _buildFormField(
                      label: 'Professional Summary',
                      controller: _summaryController,
                      hint: 'e.g. Focused and detail-oriented professional...',
                    ),
                    const SizedBox(height: 32),

                    // Next button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _savePersonalDetails();
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EmploymentHistoryScreen(cvId: widget.cvId),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF6366F1), // Modern Indigo
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Next: Employment History',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool hasInfo = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasInfo) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.blue[400],
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        _buildTextField(controller: controller, hint: hint),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 13.5,
        color: Color(0xFF1F2937),
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 12.5,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
    );
  }
}
