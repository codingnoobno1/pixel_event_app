import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:crypto/crypto.dart';
import '../models/models.dart';
import '../utils/constants.dart';

/// Service for QR code generation and validation
/// Handles QR payload creation, signature validation, and image generation
class QRService {
  // Secret key for HMAC-SHA256 signature (should match backend)
  // In production, this should be securely stored or fetched from backend
  static const String _secretKey = AppConstants.qrSecretKey;

  /// Generate QR code widget for display
  Widget generateQRWidget({
    required EventPass pass,
    double size = 200,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) {
    final payload = pass.qrPayload;

    return QrImageView(
      data: payload,
      version: QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
      padding: const EdgeInsets.all(0),
    );
  }

  /// Generate QR code as image (for saving/sharing)
  Future<Uint8List> generateQRImage({
    required EventPass pass,
    double size = 512,
  }) async {
    final payload = pass.qrPayload;

    // Create QR painter
    final qrCode = QrCode.fromData(
      data: payload,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );

    final qrImage = QrImage(qrCode);

    // Create canvas and paint QR code
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Paint white background
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), paint);

    // Paint QR code
    final qrPainter = QrPainter.withQr(
      qr: qrCode,
      color: Colors.black,
      emptyColor: Colors.white,
      gapless: true,
    );

    qrPainter.paint(canvas, Size(size, size));

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// Validate QR signature using HMAC-SHA256
  /// Returns true if signature is valid
  bool validateQRSignature(String payload, String signature) {
    try {
      final expectedSignature = _generateSignature(payload);
      return expectedSignature == signature;
    } catch (e) {
      return false;
    }
  }

  /// Generate HMAC-SHA256 signature for payload
  String _generateSignature(String payload) {
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// Parse QR payload JSON and extract fields
  /// Returns null if payload is invalid
  Map<String, dynamic>? parseQRPayload(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;

      // Validate required fields
      if (!data.containsKey('passId') ||
          !data.containsKey('eventId') ||
          !data.containsKey('registrationId') ||
          !data.containsKey('userId') ||
          !data.containsKey('timestamp') ||
          !data.containsKey('signature')) {
        return null;
      }

      return data;
    } catch (e) {
      return null;
    }
  }

  /// Validate complete QR code data
  /// Checks payload structure and signature
  QRValidationResult validateQRCode(String qrData) {
    // Parse payload
    final parsed = parseQRPayload(qrData);
    if (parsed == null) {
      return QRValidationResult(
        isValid: false,
        error: 'Invalid QR code format',
      );
    }

    // Extract signature
    final signature = parsed['signature'] as String;

    // Create payload without signature for validation
    final payloadData = Map<String, dynamic>.from(parsed);
    payloadData.remove('signature');
    final payloadString = jsonEncode(payloadData);

    // Validate signature
    if (!validateQRSignature(payloadString, signature)) {
      return QRValidationResult(
        isValid: false,
        error: 'Invalid QR code signature - possible tampering detected',
      );
    }

    // All validations passed
    return QRValidationResult(
      isValid: true,
      data: parsed,
    );
  }

  /// Create EventPass from QR code data
  /// Returns null if data is invalid
  EventPass? createPassFromQRData(String qrData) {
    final validation = validateQRCode(qrData);
    if (!validation.isValid || validation.data == null) {
      return null;
    }

    try {
      final data = validation.data!;

      // Parse registration type
      RegistrationType regType = RegistrationType.solo;
      if (data.containsKey('registrationType')) {
        final typeStr = data['registrationType'] as String;
        regType = typeStr == 'team' ? RegistrationType.team : RegistrationType.solo;
      }

      // Parse team members if present
      List<TeamMember>? teamMembers;
      if (data.containsKey('teamMembers') && data['teamMembers'] is List) {
        teamMembers = (data['teamMembers'] as List)
            .map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
            .toList();
      }

      return EventPass(
        passId: data['passId'] as String,
        eventId: data['eventId'] as String,
        registrationId: data['registrationId'] as String,
        userId: data['userId'] as String,
        timestamp: DateTime.parse(data['timestamp'] as String),
        qrSignature: data['signature'] as String,
        registrationType: regType,
        teamId: data['teamId'] as String?,
        teamName: data['teamName'] as String?,
        teamMembers: teamMembers,
        event: Event.fromJson({}), // Placeholder if needed, or better, fetch this later
        user: User.fromJson({}),  // Placeholder
      );
    } catch (e) {
      return null;
    }
  }

  /// Generate signature for an EventPass
  /// Used when creating new passes
  String generatePassSignature(EventPass pass) {
    // Create payload without signature
    final payload = {
      'passId': pass.passId,
      'eventId': pass.eventId,
      'registrationId': pass.registrationId,
      'userId': pass.userId,
      'timestamp': pass.timestamp.toIso8601String(),
      if (pass.registrationType == RegistrationType.team) ...{
        'registrationType': 'team',
        'teamId': pass.teamId,
        'teamName': pass.teamName,
        'teamMembers': pass.teamMembers?.map((m) => m.toJson()).toList(),
      } else
        'registrationType': 'solo',
    };

    final payloadString = jsonEncode(payload);
    return _generateSignature(payloadString);
  }

  /// Verify QR code matches expected event
  bool verifyEventMatch(String qrData, String expectedEventId) {
    final parsed = parseQRPayload(qrData);
    if (parsed == null) return false;

    return parsed['eventId'] == expectedEventId;
  }

  /// Check if QR code is for team registration
  bool isTeamPass(String qrData) {
    final parsed = parseQRPayload(qrData);
    if (parsed == null) return false;

    return parsed['registrationType'] == 'team';
  }

  /// Get team member count from QR code
  int getTeamMemberCount(String qrData) {
    final parsed = parseQRPayload(qrData);
    if (parsed == null) return 0;

    if (parsed['teamMembers'] is List) {
      return (parsed['teamMembers'] as List).length;
    }

    return 0;
  }
}

/// Result of QR code validation
class QRValidationResult {
  final bool isValid;
  final String? error;
  final Map<String, dynamic>? data;

  QRValidationResult({
    required this.isValid,
    this.error,
    this.data,
  });
}
