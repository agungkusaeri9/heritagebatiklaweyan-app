import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/checkout_result_model.dart';
import '../viewmodels/checkout_providers.dart';
import '../viewmodels/order_list_state.dart';
import '../widgets/order_list_item_card.dart';
import '../widgets/order_list_skeleton.dart';

/// Layar Daftar Pesanan (My Orders Screen)
/// Menampilkan 3 tab status: Active, Completed, dan Cancelled
/// dengan paginasi infinite scroll, ringkasan produk utama, dan integrasi API.
class OrderListView extends ConsumerStatefulWidget {
  final OrderTabStatus? initialTab;
  final VoidCallback? onBackTap;
  final bool embedded;

  const OrderListView({
    super.key,
    this.initialTab,
    this.onBackTap,
    this.embedded = false,
  });

  @override
  ConsumerState<OrderListView> createState() => _OrderListViewState();
}

class _OrderListViewState extends ConsumerState<OrderListView> {
  final Map<OrderTabStatus, ScrollController> _scrollControllers = {
    for (final tab in OrderTabStatus.values) tab: ScrollController(),
  };

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    for (final entry in _scrollControllers.entries) {
      final tab = entry.key;
      final controller = entry.value;
      controller.addListener(() => _onScroll(tab, controller));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(orderListViewModelProvider.notifier);
      if (widget.initialTab != null) {
        notifier.selectTab(widget.initialTab!);
      } else {
        notifier.initOrders();
      }
    });
  }

  void _onScroll(OrderTabStatus tab, ScrollController controller) {
    final state = ref.read(orderListViewModelProvider);
    if (state.selectedTab != tab) return;
    if (!controller.hasClients) return;

    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.position.pixels;
    if (currentScroll >= maxScroll - 220) {
      ref.read(orderListViewModelProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleOpenOrderDetail(CheckoutResultModel order) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    try {
      final identifier = order.orderNumber.isNotEmpty
          ? order.orderNumber
          : order.id.toString();
      await context.push('/orders/$identifier', extra: order);
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  Future<void> _handleTrackOrder(CheckoutResultModel order) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    try {
      final identifier = order.orderNumber.isNotEmpty
          ? order.orderNumber
          : order.id.toString();
      await context.push('/orders/$identifier/track', extra: order);
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderListViewModelProvider);
    final selectedTab = orderState.selectedTab;

    final content = Column(
      children: [
        // 1. Header: Back Button & Title "My Orders"
        _buildHeader(context),

        // 2. Status Tabs: Active | Completed | Cancelled
        _buildStatusTabs(selectedTab),

        // 3. Daftar Pesanan Sesuai Tab (IndexedStack menjaga posisi scroll per tab)
        Expanded(
          child: IndexedStack(
            index: selectedTab.index,
            children: OrderTabStatus.values
                .map((tab) => _buildTabBody(context, tab, orderState.tabDataFor(tab)))
                .toList(),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(
        color: Colors.white,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: content,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('my_orders_back_button'),
              onTap: () {
                if (widget.onBackTap != null) {
                  widget.onBackTap!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/home');
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          Text(
            'My Orders',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 42, height: 42),
        ],
      ),
    );
  }

  Widget _buildStatusTabs(OrderTabStatus selectedTab) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: OrderTabStatus.values.map((tab) {
          final bool isSelected = selectedTab == tab;
          return Expanded(
            child: InkWell(
              key: Key('order_tab_${tab.name}'),
              onTap: () {
                ref.read(orderListViewModelProvider.notifier).selectTab(tab);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      tab.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    height: 3.5,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBody(
    BuildContext context,
    OrderTabStatus tab,
    OrderTabData tabData,
  ) {
    if (tabData.isLoading && tabData.orders.isEmpty) {
      return const OrderListSkeleton();
    }

    if (tabData.errorMessage != null && tabData.orders.isEmpty) {
      return _buildErrorState(tab, tabData.errorMessage!);
    }

    if (tabData.orders.isEmpty && tabData.hasLoaded) {
      return _buildEmptyState(context, tab);
    }

    final dateGroups = tabData.dateGroups;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref
          .read(orderListViewModelProvider.notifier)
          .fetchOrdersForTab(tab, reset: true, forceRefresh: true),
      child: ListView.builder(
        key: PageStorageKey<String>('order_list_scroll_${tab.name}'),
        controller: _scrollControllers[tab],
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          top: 6,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        itemCount: dateGroups.length + (tabData.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= dateGroups.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            );
          }

          final group = dateGroups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(group),
              ...group.items.asMap().entries.map((entry) {
                final itemIndex = entry.key;
                final order = entry.value;
                return Column(
                  children: [
                    OrderListItemCard(
                      order: order,
                      onTap: () => _handleOpenOrderDetail(order),
                      onTrackOrderTap: order.canTrackOrder
                          ? () => _handleTrackOrder(order)
                          : null,
                    ),
                    if (itemIndex < group.items.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }

  /// Header seksi kelompok tanggal pada daftar pesanan
  Widget _buildDateHeader(OrderDateGroup group) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                group.title.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${group.items.length} ${group.items.length == 1 ? "Order" : "Orders"}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, OrderTabStatus tab) {
    String title;
    String subtitle;
    IconData icon;

    switch (tab) {
      case OrderTabStatus.active:
        title = 'No Active Orders';
        subtitle =
            'You don\'t have any active orders in progress right now. Explore our authentic batik collection!';
        icon = Icons.local_shipping_outlined;
        break;
      case OrderTabStatus.completed:
        title = 'No Completed Orders';
        subtitle =
            'Orders that have been delivered and completed will appear here.';
        icon = Icons.inventory_2_outlined;
        break;
      case OrderTabStatus.cancelled:
        title = 'No Cancelled Orders';
        subtitle = 'You have no cancelled orders.';
        icon = Icons.remove_shopping_cart_outlined;
        break;
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref
          .read(orderListViewModelProvider.notifier)
          .fetchOrdersForTab(tab, reset: true, forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(OrderTabStatus tab, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Failed to Load Orders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              key: Key('retry_orders_button_${tab.name}'),
              onPressed: () {
                ref.read(orderListViewModelProvider.notifier).fetchOrdersForTab(
                      tab,
                      reset: true,
                      forceRefresh: true,
                    );
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

