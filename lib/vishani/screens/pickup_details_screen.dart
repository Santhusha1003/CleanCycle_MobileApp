import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/special_pickup_model.dart';
import '../services/special_pickup_service.dart';
import 'request_submitted_screen.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/data/user_repository.dart';

class PickupDetailsScreen extends StatefulWidget {
  final String selectedWasteType;
  final DateTime scheduledDate;
  final String timeSlot;

  const PickupDetailsScreen({
    super.key,
    required this.selectedWasteType,
    required this.scheduledDate,
    required this.timeSlot,
  });

  @override
  State<PickupDetailsScreen> createState() => _PickupDetailsScreenState();
}

class _PickupDetailsScreenState extends State<PickupDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final SpecialPickupService _pickupService = SpecialPickupService();
  final ImagePicker _picker = ImagePicker();

  String _address = '';
  final TextEditingController _notesController = TextEditingController();
  final List<File> _selectedPhotos = [];
  final List<Uint8List> _selectedPhotosBytes = [];
  bool _isSubmitting = false;

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedPhotos.add(File(picked.path));
          _selectedPhotosBytes.add(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking photo: $e')));
      }
    }
  }

  void _changeAddressDialog() {
    final addrController = TextEditingController(text: _address);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Change Pickup Address',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: addrController,
          maxLines: 2,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            hintText: 'Enter complete street address...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (addrController.text.trim().isNotEmpty) {
                setState(() => _address = addrController.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text(
              'Save Address',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final uid = context.read<AuthController>().firebaseUser?.uid;
      final firebaseUser = context.read<AuthController>().firebaseUser;
      if (uid == null || firebaseUser == null) {
        throw StateError('Please sign in first.');
      }
      if (_address.trim().isEmpty) {
        throw StateError('Enter your pickup address.');
      }

      // Ensure the user profile document exists in Firestore with role 'resident'
      // before writing to special_pickups. The Firestore rule calls getRole()
      // which reads users/{uid}.role — if that document is missing or lacks the
      // 'resident' role, the write will be permission-denied.
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!userDoc.exists) {
        // Profile missing (can happen with Google sign-in if ensureResidentProfile
        // failed silently). Re-run the profile creation before proceeding.
        await UserRepository().ensureResidentProfile(firebaseUser);
      }

      final newPickup = SpecialPickupModel(
        requestId: '',
        userId: uid,
        wasteType: widget.selectedWasteType,
        scheduledDate: widget.scheduledDate,
        timeSlot: widget.timeSlot,
        address: _address,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        status: 'Pending',
      );

      final requestId = await _pickupService.createPickupRequest(
        newPickup,
        _selectedPhotos,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RequestSubmittedScreen(requestId: requestId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String message = 'Submission error: $e';
        if (e is FirebaseException && e.code == 'permission-denied') {
          message =
              'Permission denied. Your account does not have permission to submit pickup requests. '
              'Please verify that updated Firestore security rules have been deployed.';
        } else if (e is StateError) {
          message = e.message;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text(
          'Pickup Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Pill
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.selectedWasteType,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B3B2B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DateFormat('MMM d').format(widget.scheduledDate)} • ${widget.timeSlot}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. Pickup Address Section
                    const Text(
                      'Pickup Address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3B2B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _address,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1B3B2B),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _changeAddressDialog,
                            child: const Text(
                              'Change',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Specific Instructions / Gate Access Notes
                    const Text(
                      'Additional Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3B2B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'e.g., item size, quantity, pickup location details (Landmark, gate, etc.)',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
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
                          return 'Please provide brief instructions or item descriptions';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 3. Multi-Photo Upload Grid matching Screen 9
                    const Text(
                      'Add Photos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3B2B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Sample preview if no user photo picked yet, or display picked
                        if (_selectedPhotosBytes.isEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/furniture_sofa.jpg',
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ] else ...[
                          ...List.generate(_selectedPhotosBytes.length, (idx) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _selectedPhotosBytes[idx],
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedPhotos.removeAt(idx);
                                          _selectedPhotosBytes.removeAt(idx);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        // [+] Trigger Button
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (ctx) => SafeArea(
                                child: Wrap(
                                  children: [
                                    ListTile(
                                      leading: const Icon(
                                        Icons.camera_alt,
                                        color: Color(0xFF2E7D32),
                                      ),
                                      title: const Text(
                                        'Take Photo with Camera',
                                      ),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _pickPhoto(ImageSource.camera);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.photo_library,
                                        color: Color(0xFF2E7D32),
                                      ),
                                      title: const Text('Pick from Gallery'),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _pickPhoto(ImageSource.gallery);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                color: Colors.grey,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Primary Trigger: "Submit Request"
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
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
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
