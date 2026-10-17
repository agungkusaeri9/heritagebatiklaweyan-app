/// Tipe mockup smartphone yang ditampilkan di setiap slide onboarding
enum OnboardingMockupType {
  shopping,
  wishlist,
  orderTracking,
}

/// Model data untuk setiap slide onboarding
class OnboardingItem {
  final int step;
  final String title;
  final String description;
  final OnboardingMockupType mockupType;

  const OnboardingItem({
    required this.step,
    required this.title,
    required this.description,
    required this.mockupType,
  });

  /// Daftar 3 slide onboarding fashion shopping sesuai kebutuhan tugas
  static const List<OnboardingItem> items = [
    OnboardingItem(
      step: 0,
      title: 'Seamless Shopping Experience',
      description:
          'Explore hundreds of authentic handcrafted batik collections with ease, smart category filters, and real-time stock availability.',
      mockupType: OnboardingMockupType.shopping,
    ),
    OnboardingItem(
      step: 1,
      title: 'Wishlist: Where Fashion Dreams Begin',
      description:
          'Save your favorite traditional and modern batik pieces to your personal wishlist and purchase them whenever you are ready.',
      mockupType: OnboardingMockupType.wishlist,
    ),
    OnboardingItem(
      step: 2,
      title: 'Swift and Reliable Delivery',
      description:
          'Track your authentic batik packages in real-time from our Solo workshops directly to your doorstep with guaranteed safety and care.',
      mockupType: OnboardingMockupType.orderTracking,
    ),
  ];
}
