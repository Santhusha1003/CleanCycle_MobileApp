import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/missed_report_model.dart';
import '../services/missed_report_service.dart';
import 'missed_details_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';

class ReportMissedScreen extends StatefulWidget {
  const ReportMissedScreen({super.key});

  @override
  State<ReportMissedScreen> createState() => _ReportMissedScreenState();
}

class _ReportMissedScreenState extends State<ReportMissedScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = 'Recyclable';
  DateTime _scheduledDate = DateTime.now().subtract(const Duration(days: 1));
  
  // Controllers
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Recyclable',
    'Organic',
    'Non-recyclable',
    'Hazardous / Medical',
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = File(pickedFile.path);
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 14)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1B3B2B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  // Firebase Firestore වෙත සෘජුවම දත්ත Save කිරීම
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final uid = context.read<AuthController>().firebaseUser?.uid;
      if (uid == null) throw StateError('Please sign in to submit a report.');

      final report = MissedReportModel(
        reportId: '',
        userId: uid,
        collectionType: _selectedCategory,
        scheduledDate: _scheduledDate,
        description: _descController.text.trim(),
        address: _addressController.text.trim(),
        reportedOn: DateTime.now(),
        status: 'Reported',
      );

      final reportId = await MissedReportService().createReport(report, _selectedImage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missed collection report submitted successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );

        // 2. අදාළ Report Detail Screen එක වෙත රැගෙන යාම
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MissedDetailsScreen(reportId: reportId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text(
          'Report Missed Collection',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice Card matching Screen 4
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Did we miss your collection?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC62828),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Let us know, and we'll take action as soon as possible.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB71C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 1. Collection Type Dropdown
              const Text(
                'Collection Type',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat, style: const TextStyle(fontSize: 15)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Scheduled Date Picker
              const Text(
                'Missed Scheduled Date',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_scheduledDate),
                        style: const TextStyle(fontSize: 15, color: Color(0xFF1B3B2B)),
                      ),
                      const Icon(Icons.calendar_month, color: Color(0xFF2E7D32)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 3. Location / Address Input
              const Text(
                'Pickup Location / Address',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'e.g., No. 42, Galle Road, Colombo 03',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the pickup location address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // 4. Problem Description
              const Text(
                'Describe the issue',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "e.g., Bin not collected, team didn't arrive, etc.",
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please describe the missed collection issue';
                  }
                  if (val.trim().length < 5) {
                    return 'Description must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // 5. Photo Picker matching Screen 4
              _selectedImageBytes != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _selectedImageBytes!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 16,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.white),
                              onPressed: () => setState(() {
                                _selectedImage = null;
                                _selectedImageBytes = null;
                              }),
                            ),
                          ),
                        ),
                      ],
                    )
                  : InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (ctx) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
                                  title: const Text('Take Photo from Camera'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _pickImage(ImageSource.camera);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
                                  title: const Text('Choose from Gallery'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _pickImage(ImageSource.gallery);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 54,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, color: Colors.grey.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Add Photo (Optional)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              const SizedBox(height: 32),

              // 6. Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}