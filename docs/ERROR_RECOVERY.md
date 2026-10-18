# IDE error recovery

Work remained on `feature/admin-web`. The 1,004 initial analyzer issues were primarily cascading syntax errors from 17 unresolved stash conflicts. The restored screens also required auth/profile, tracking, assets, driver identity and common widget APIs absent from this branch. Existing repository versions were used to reconcile these dependencies; no new authentication bypass was added.

Original conflicted files, Git stages and replaced versions are backed up in `/tmp/cleancycle-error-recovery`. All seven existing stashes remain intact. The 17 conflicted paths were staged solely to mark conflicts resolved; other edits remain unstaged/untracked. No commit, push, branch switch or production operation was performed.

Additional fixes: safe navigation/messenger handling after asynchronous saves, existing lint issues, meaningful auth startup testing, dashboard initialization errors rendered through its existing retryable error state, and unused web map state removed. Flutter dependency resolution regenerated platform plugin registrants.

## Verification

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 95 passed.
- Admin web `npm run lint`: passed, no lint findings.
- Admin web `npm test`: 32 passed.
- Admin web `npm run build`: passed; existing non-failing bundle-size advisory remains.
- `git diff --check`: passed. No unresolved index entries remain.
- Local demo Firestore emulator: 14 security tests passed. Live Firebase not tested or modified.

## Resolved conflict paths

- `firestore.rules`
- `lib/models/collection_schedule.dart`
- `lib/screens/municipal_dashboard_screen.dart`
- `lib/screens/schedule_management_screen.dart`
- `lib/screens/splash_screen.dart`
- `lib/services/firebase/firestore_service.dart`
- `lib/services/municipal/driver_service.dart`
- `lib/services/municipal/municipal_analytics_service.dart`
- `lib/services/municipal/schedule_service.dart`
- `lib/vishani/services/tracking_service.dart`
- `pubspec.lock`
- `test/municipal_analytics_service_test.dart`
- `test/municipal_schedule_service_test.dart`
- `test/municipal_schedule_tracking_assignment_test.dart`
- `test/schedule_management_save_test.dart`
- `test/splash_screen_test.dart`
- `test/support/tracking_firestore.dart`

## Other repaired or regenerated files

- `admin_web/src/components/FleetTrackingMap.jsx`
- `lib/app.dart`
- `lib/main.dart`
- `lib/models/driver.dart`
- `lib/navigation/app_router.dart`
- `lib/navigation/municipal_shell.dart`
- `lib/screens/driver_management_screen.dart`
- `lib/screens/vehicle_management_screen.dart`
- `lib/widgets/common/app_card.dart`
- `lib/widgets/common/app_info_card.dart`
- `lib/widgets/common/app_password_field.dart`
- `lib/widgets/common/app_primary_button.dart`
- `lib/widgets/common/app_search_field.dart`
- `lib/widgets/common/app_secondary_button.dart`
- `lib/widgets/common/app_stat_card.dart`
- `lib/widgets/common/app_status_card.dart`
- `lib/widgets/common/app_text_button.dart`
- `lib/widgets/common/app_text_field.dart`
- `linux/flutter/generated_plugin_registrant.cc`
- `linux/flutter/generated_plugins.cmake`
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `pubspec.yaml`
- `scripts/test_tracking_permissions.py`
- `test/municipal_dashboard_screen_test.dart`
- `test/widget_test.dart`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`

## Missing dependencies restored from existing main history

- `assets/images/clean_communities.jpg`
- `assets/images/driver_avatar.jpg`
- `assets/images/furniture_sofa.jpg`
- `assets/images/logo.png`
- `assets/images/missed_bins.jpg`
- `assets/images/special_pickup_truck.jpg`
- `lib/app.dart`
- `lib/collection_schedule/models/collection_schedule.dart`
- `lib/collection_schedule/models/missed_collection_report.dart`
- `lib/collection_schedule/screens/collection_calendar_screen.dart`
- `lib/collection_schedule/screens/collection_history_screen.dart`
- `lib/collection_schedule/screens/collection_schedule_details_screen.dart`
- `lib/collection_schedule/screens/collection_schedule_screen.dart`
- `lib/collection_schedule/screens/home_dashboard_screen.dart`
- `lib/collection_schedule/screens/missed_collection_report_details_screen.dart`
- `lib/collection_schedule/screens/missed_collection_report_screen.dart`
- `lib/collection_schedule/screens/missed_collection_reports_screen.dart`
- `lib/collection_schedule/screens/recycling_centre_details_screen.dart`
- `lib/collection_schedule/screens/recycling_centre_locator_screen.dart`
- `lib/collection_schedule/screens/recycling_tips_screen.dart`
- `lib/collection_schedule/screens/waste_categories_screen.dart`
- `lib/collection_schedule/screens/waste_segregation_guide_screen.dart`
- `lib/collection_schedule/services/collection_schedule_reminder_service.dart`
- `lib/collection_schedule/services/collection_schedule_service.dart`
- `lib/collection_schedule/services/missed_collection_report_service.dart`
- `lib/collection_schedule/widgets/collection_bottom_nav.dart`
- `lib/core/constants/app_roles.dart`
- `lib/core/constants/app_strings.dart`
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_text_styles.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/utils/error_mapper.dart`
- `lib/core/utils/validators.dart`
- `lib/core/widgets/app_text_field.dart`
- `lib/core/widgets/loading_overlay.dart`
- `lib/core/widgets/password_field.dart`
- `lib/core/widgets/primary_button.dart`
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/auth/data/email_otp.dart`
- `lib/features/auth/data/user_repository.dart`
- `lib/features/auth/models/app_user.dart`
- `lib/features/auth/presentation/auth_controller.dart`
- `lib/features/auth/presentation/screens/auth_gate.dart`
- `lib/features/auth/presentation/screens/create_account_screen.dart`
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/screens/reset_password_screen.dart`
- `lib/features/auth/presentation/screens/verification_screen.dart`
- `lib/features/auth/presentation/widgets/password_rules_checklist.dart`
- `lib/features/auth/presentation/widgets/password_strength_indicator.dart`
- `lib/features/auth/presentation/widgets/social_login_buttons.dart`
- `lib/features/notifications/data/fcm_service.dart`
- `lib/features/notifications/presentation/notification_settings_screen.dart`
- `lib/features/placeholders/app_shell.dart`
- `lib/features/placeholders/home_resident_placeholder.dart`
- `lib/features/placeholders/placeholders.dart`
- `lib/features/profile/presentation/profile_controller.dart`
- `lib/features/profile/presentation/screens/account_settings_screen.dart`
- `lib/features/profile/presentation/screens/edit_profile_screen.dart`
- `lib/features/profile/presentation/screens/help_support_screen.dart`
- `lib/features/profile/presentation/screens/language_screen.dart`
- `lib/features/profile/presentation/screens/privacy_security_screen.dart`
- `lib/features/profile/presentation/widgets/profile_avatar.dart`
- `lib/screens/driver_details_screen.dart`
- `lib/screens/staff_details_screen.dart`
- `lib/screens/vehicle_details_screen.dart`
- `lib/vishani/models/driver_tracking_model.dart`
- `lib/vishani/models/missed_report_model.dart`
- `lib/vishani/models/special_pickup_model.dart`
- `lib/vishani/screens/collection_status_screen.dart`
- `lib/vishani/screens/driver_profile_screen.dart`
- `lib/vishani/screens/live_tracking_screen.dart`
- `lib/vishani/screens/missed_details_screen.dart`
- `lib/vishani/screens/pickup_details_screen.dart`
- `lib/vishani/screens/report_missed_screen.dart`
- `lib/vishani/screens/request_submitted_screen.dart`
- `lib/vishani/screens/select_date_time_screen.dart`
- `lib/vishani/screens/select_waste_type_screen.dart`
- `lib/vishani/screens/special_pickup_screen.dart`
- `lib/vishani/screens/tracking_dashboard_screen.dart`
- `lib/vishani/services/missed_report_service.dart`
- `lib/vishani/services/special_pickup_service.dart`
- `lib/vishani/services/storage_service.dart`
- `lib/widgets/common/authenticated_user_greeting.dart`
- `lib/widgets/common/municipal_add_button.dart`
- `lib/widgets/common/municipal_bottom_navigation.dart`
- `lib/widgets/common/municipal_crud_actions.dart`
- `lib/widgets/common/municipal_record_details.dart`
- `lib/widgets/municipal/performance_charts.dart`
