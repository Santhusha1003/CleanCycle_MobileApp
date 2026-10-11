import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/models/app_user.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/profile/presentation/profile_controller.dart';
import '../../models/driver.dart';
import '../../services/municipal/driver_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_card.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key, this.driverService});
  final DriverService? driverService;

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  Driver? _driver;
  String? _accountKey;
  String? _message;
  bool _loading = false;
  bool _signingOut = false;
  int _request = 0;

  AppUser? _currentUser() {
    final auth = context.watch<AuthController>();
    final live = context.watch<ProfileController?>()?.user;
    return live?.uid == auth.profile?.uid ? live : auth.profile;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = _currentUser();
    final key = '${user?.uid}:${user?.email}:${user?.role}';
    if (_accountKey != key) {
      _accountKey = key;
      _loadDriver(user);
    }
  }

  Future<void> _loadDriver(AppUser? user) async {
    final request = ++_request;
    _driver = null;
    _message = null;
    _loading = false;
    if (user == null || !user.isDriver) return;
    _loading = true;
    try {
      final driver = await (widget.driverService ?? DriverService())
          .getDriverForAuthUid(authUid: user.uid);
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _driver = driver;
        if (driver == null) {
          _message = 'No driver record linked to this account.';
        }
      });
    } on DriverServiceException catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _message = error.message;
      });
    } on Exception {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _message = 'Unable to load driver details. Please try again.';
      });
    }
  }

  Future<void> _reload(AppUser user) {
    final pending = _loadDriver(user);
    setState(() {});
    return pending;
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await context.read<AuthController>().signOut();
      // AuthGate and existing route guards react to the session stream.
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Driver Profile')),
      body: user == null || !user.isDriver
          ? const Center(
              child: Text('Driver profile is unavailable for this account.'),
            )
          : RefreshIndicator(
              onRefresh: () => _reload(user),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.lightGreen,
                      child: Icon(
                        Icons.drive_eta_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _value(user.name, fallback: _driver?.fullName),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Driver',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      children: [
                        _row(
                          Icons.badge_outlined,
                          'Driver ID',
                          _value(_driver?.driverId),
                        ),
                        _row(Icons.email_outlined, 'Email', _value(user.email)),
                        _row(
                          Icons.phone_outlined,
                          'Phone number',
                          _value(user.phone, fallback: _driver?.phoneNumber),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assignment & Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_loading)
                          const LinearProgressIndicator(
                            color: AppColors.primary,
                          ),
                        if (_message != null) ...[
                          Text(
                            _message!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _reload(user),
                            child: const Text('Retry'),
                          ),
                        ],
                        _row(
                          Icons.local_shipping_outlined,
                          'Assigned vehicle',
                          _value(_driver?.assignedVehicleId),
                        ),
                        _row(
                          Icons.location_on_outlined,
                          'Assigned zone',
                          _value(_driver?.assignedZone),
                        ),
                        _row(
                          Icons.check_circle_outline,
                          'Driver status',
                          _value(_driver?.status),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _signingOut ? null : _signOut,
                    icon: const Icon(Icons.logout),
                    label: Text(_signingOut ? 'Signing Out...' : 'Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _value(String? value, {String? fallback}) =>
      (value?.trim().isNotEmpty ?? false)
      ? value!.trim()
      : (fallback?.trim().isNotEmpty ?? false)
      ? fallback!.trim()
      : 'Not available';

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
