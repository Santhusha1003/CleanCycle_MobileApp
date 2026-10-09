import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../../core/utils/error_mapper.dart';

/// 6-digit OTP emailed to the address typed on Create Account.
class EmailOtp {
  static const validFor = Duration(seconds: 90);

  static String hash(String code, String uid) =>
      sha256.convert(utf8.encode('$code:$uid')).toString();

  static String generate() =>
      Random.secure().nextInt(1000000).toString().padLeft(6, '0');

  static Future<void> send({
    required String toEmail,
    required String code,
  }) async {
    final address = toEmail.trim();
    final response = await http
        .post(
          Uri.parse('https://formsubmit.co/ajax/$address'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Origin': 'https://cleancyclemobileapp.web.app',
            'Referer': 'https://cleancyclemobileapp.web.app/',
          },
          body: jsonEncode({
            'name': 'CleanCycle',
            'email': address,
            '_replyto': address,
            '_subject': 'Your CleanCycle 6-digit verification code',
            '_captcha': 'false',
            '_template': 'box',
            'code': code,
            'message':
                'Your CleanCycle verification code is $code. It expires in 90 seconds. Type these 6 digits in the app.',
          }),
        )
        .timeout(const Duration(seconds: 20));

    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } catch (_) {}

    final success = payload?['success'] == true || payload?['success'] == 'true';
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        !success) {
      throw OtpSendException(
        'Could not deliver the 6-digit email yet. Use the code shown on this screen, then check Spam.',
      );
    }
  }
}
