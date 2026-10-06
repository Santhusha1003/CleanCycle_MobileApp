import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/primary_button.dart';
import '../profile_controller.dart';
import '../widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileController>().user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _address = TextEditingController(text: user?.addressZone ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final profile = context.read<ProfileController>();
    final ok = await profile.updateProfile(
      name: _name.text,
      phone: _phone.text,
      addressZone: _address.text,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(profile.errorMessage ?? 'Could not save profile.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final user = profile.user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.editProfile)),
      body: user == null
          ? const AppStateMessage(message: 'No profile loaded.')
          : LoadingOverlay(
              visible: profile.busy,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: AppTheme.screenPadding,
                  children: [
                    Center(
                      child: ProfileAvatar(
                        user: user,
                        onEdit: () async {
                          await profile.pickAndSaveAvatar();
                          if (!context.mounted) return;
                          if (profile.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(profile.errorMessage!)),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      label: AppStrings.fullName,
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: AppStrings.emailAddress,
                      controller: _email,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: AppStrings.phoneNumber,
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: AppStrings.addressZone,
                      controller: _address,
                      validator: Validators.addressZone,
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(label: 'Save changes', onPressed: _save),
                  ],
                ),
              ),
            ),
    );
  }
}
