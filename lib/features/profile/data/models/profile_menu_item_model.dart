import 'package:flutter/material.dart';

/// Model untuk item menu pada Halaman Profile
class ProfileMenuItemModel {
  final String id;
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Color? textColor;
  final bool isDestructive;
  final String? route;

  const ProfileMenuItemModel({
    required this.id,
    required this.title,
    required this.icon,
    this.iconColor,
    this.textColor,
    this.isDestructive = false,
    this.route,
  });

  /// Daftar 8 menu profile standar sesuai Scope Pekerjaan
  static const List<ProfileMenuItemModel> defaultMenus = [
    ProfileMenuItemModel(
      id: 'your_profile',
      title: 'Your profile',
      icon: Icons.person_outline_rounded,
      route: '/complete-profile',
    ),
    ProfileMenuItemModel(
      id: 'payment_methods',
      title: 'Payment Methods',
      icon: Icons.credit_card_outlined,
    ),
    ProfileMenuItemModel(
      id: 'my_orders',
      title: 'My Orders',
      icon: Icons.shopping_bag_outlined,
    ),
    ProfileMenuItemModel(
      id: 'settings',
      title: 'Settings',
      icon: Icons.settings_outlined,
      route: '/settings',
    ),
    ProfileMenuItemModel(
      id: 'help_center',
      title: 'Help Center',
      icon: Icons.help_outline_rounded,
    ),
    ProfileMenuItemModel(
      id: 'privacy_policy',
      title: 'Privacy Policy',
      icon: Icons.lock_outline_rounded,
    ),
    ProfileMenuItemModel(
      id: 'invites_friends',
      title: 'Invites Friends',
      icon: Icons.person_add_alt_1_outlined,
    ),
    ProfileMenuItemModel(
      id: 'log_out',
      title: 'Log out',
      icon: Icons.logout_rounded,
      isDestructive: true,
      textColor: Color(0xFFEF4444),
      iconColor: Color(0xFFEF4444),
    ),
  ];
}
