import 'dart:io';

import 'package:flutter/material.dart';

import '../../../auth/models/app_user.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.user,
    this.radius = 40,
    this.onEdit,
  });

  final AppUser user;
  final double radius;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    final url = user.avatarUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        image = NetworkImage(url);
      } else {
        final file = File(url);
        if (file.existsSync()) image = FileImage(file);
      }
    }

    final initials = user.name.isEmpty
        ? '?'
        : user.name.trim().split(RegExp(r'\s+')).map((p) => p[0]).take(2).join().toUpperCase();

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primarySoft,
          backgroundImage: image,
          child: image == null
              ? Text(
                  initials,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: radius * 0.55,
                  ),
                )
              : null,
        ),
        if (onEdit != null)
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.camera_alt, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
