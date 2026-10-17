import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/onboarding_item.dart';
import '../widgets/onboarding_page_indicator.dart';
import '../widgets/phone_mockup_widget.dart';

/// Halaman 2, 3, 4: Onboarding Flow (Shopping, Wishlist, Order Tracking)
class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setOnboardingCompleted(true);

    if (mounted) {
      context.go('/login');
    }
  }

  void _nextPage() {
    if (_currentIndex < OnboardingItem.items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentIndex == OnboardingItem.items.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ),

            // PageView: Mockup & Description
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: OnboardingItem.items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = OnboardingItem.items[index];
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),

                          // Smartphone Mockup
                          PhoneMockupWidget(type: item.mockupType),

                          const SizedBox(height: 28),

                          // Headline Title
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              height: 1.25,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Description
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              item.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF64748B),
                                height: 1.45,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Control Button (Back)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _previousPage,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Previous',
                    ),
                  ),

                  // Center Dots Indicator
                  OnboardingPageIndicator(
                    count: OnboardingItem.items.length,
                    currentIndex: _currentIndex,
                  ),

                  // Right Control Button (Next / Get Started)
                  if (isLastPage)
                    ElevatedButton(
                      onPressed: _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _nextPage,
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        tooltip: 'Next',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
