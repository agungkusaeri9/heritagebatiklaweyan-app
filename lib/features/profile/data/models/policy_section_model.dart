import 'package:flutter/material.dart';
import '../../../store/data/models/store_setting_model.dart';

/// Model untuk merepresentasikan bagian kebijakan pada halaman Privacy Policy
class PolicySectionModel {
  final String id;
  final String title;
  final String content;
  final IconData? icon;
  final String? badgeText;

  const PolicySectionModel({
    required this.id,
    required this.title,
    required this.content,
    this.icon,
    this.badgeText,
  });

  /// Factory untuk memecah dan menyusun daftar kebijakan dari StoreSettingModel
  /// sesuai urutan: Cancellation Policy, Terms & Conditions, Privacy Policy
  static List<PolicySectionModel> fromStoreSetting(StoreSettingModel setting) {
    final List<PolicySectionModel> sections = [];

    final String cancellationDirect = (setting.cancellationPolicy ?? '').trim();
    final String policyRaw = (setting.policy ?? '').trim();
    final String privacyRaw = (setting.privacyPolicy ?? '').trim();

    String? cancellationContent;
    String? termsContent;

    // 1. Ambil Cancellation Policy dari kolom baru cancellation_policy
    if (cancellationDirect.isNotEmpty) {
      cancellationContent = cancellationDirect;
      termsContent = policyRaw.isNotEmpty ? policyRaw : null;
    } else if (policyRaw.isNotEmpty) {
      // Fallback: Ekstrak dari teks policy jika kolom baru belum terisi
      final lines = policyRaw.split('\n');
      final List<String> cancellationLines = [];
      final List<String> termsLines = [];
      bool capturingCancellation = false;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();

        final isCancellationHeader = RegExp(
          r'^(?:\d+[\.\)]\s*)?.*(?:PEMBATALAN|CANCELLATION)',
          caseSensitive: false,
        ).hasMatch(trimmed);

        if (isCancellationHeader) {
          capturingCancellation = true;
          continue;
        }

        final isNextNumberedHeader = RegExp(
          r'^\d+[\.\)]\s+[A-Z]',
        ).hasMatch(trimmed);

        if (capturingCancellation && isNextNumberedHeader) {
          capturingCancellation = false;
        }

        if (capturingCancellation) {
          cancellationLines.add(line);
        } else {
          termsLines.add(line);
        }
      }

      final String parsedCancellation = cancellationLines.join('\n').trim();
      final String parsedTerms = termsLines.join('\n').trim();

      if (parsedCancellation.isNotEmpty) {
        cancellationContent = parsedCancellation;
      }
      if (parsedTerms.isNotEmpty) {
        termsContent = parsedTerms;
      } else if (cancellationContent == null) {
        termsContent = policyRaw;
      }
    }

    // Bagian 1: Cancellation Policy
    if (cancellationContent != null && cancellationContent.isNotEmpty) {
      sections.add(
        PolicySectionModel(
          id: 'cancellation_policy',
          title: 'Cancellation Policy',
          content: cancellationContent,
          icon: Icons.assignment_return_outlined,
          badgeText: 'Pembatalan',
        ),
      );
    }

    // Bagian 2: Terms & Conditions
    if (termsContent != null && termsContent.isNotEmpty) {
      sections.add(
        PolicySectionModel(
          id: 'terms_conditions',
          title: 'Terms & Conditions',
          content: termsContent,
          icon: Icons.gavel_outlined,
          badgeText: 'Syarat & Ketentuan',
        ),
      );
    }

    // Bagian 3: Privacy Policy
    if (privacyRaw.isNotEmpty) {
      sections.add(
        PolicySectionModel(
          id: 'privacy_policy',
          title: 'Privacy Policy',
          content: privacyRaw,
          icon: Icons.shield_outlined,
          badgeText: 'Privasi & Data',
        ),
      );
    }

    return sections;
  }
}
