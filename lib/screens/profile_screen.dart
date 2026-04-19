import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import '../models/user.dart';
import '../models/loyalty.dart';
import 'auth_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/locations_sheet.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'orders_screen.dart';
import 'promo_codes_screen.dart';
import 'transaction_history_screen.dart';

/// Profile/Loyalty screen following premium brand patterns:
/// - Stats dashboard (3 cols)
/// - QR card with tap-to-expand
/// - Tier ladder with active highlight
/// - Loyalty milestones progress
/// - Birthday reward
/// - Transaction feed
/// - Grouped menu list
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) return _loggedOut(context, auth);
        return _profile(context, auth);
      },
    );
  }

  Widget _loggedOut(BuildContext context, AuthProvider auth) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: S.x40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline_rounded, size: 36, color: AppColors.textTertiary),
              const SizedBox(height: S.x16),
              Text('Войдите для доступа', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: S.x24),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())), child: const Text('ВОЙТИ'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profile(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();
    final loyalty = auth.loyalty;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(S.x16),
              child: Column(
                children: [
                  _userRow(context, user),
                  const SizedBox(height: S.x20),
                  _birthdaySection(context, user, auth),
                  if (loyalty != null) ...[
                    _stats(loyalty),
                    const SizedBox(height: S.x20),
                  ],
                  _menu(context),
                  const SizedBox(height: S.x16),
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); auth.logout(); },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: S.x12),
                      child: Text('Выйти', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                    ),
                  ),
                  const SizedBox(height: S.x32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userRow(BuildContext context, AppUser user) {
    return Row(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.accent, Color(0xFF7AB8F5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(R.md),
          ),
          child: Center(child: Text(user.name.isNotEmpty ? user.name[0] : '?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
        ),
        const SizedBox(width: S.x12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(user.phone, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        // Notification bell
        Consumer<NotificationProvider>(
          builder: (context, notifProvider, _) {
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              },
              child: Badge(
                isLabelVisible: notifProvider.unreadCount > 0,
                backgroundColor: AppColors.sale,
                label: Text(
                  '${notifProvider.unreadCount}',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(R.sm),
                  ),
                  child: Icon(Icons.notifications_outlined, size: 20, color: AppColors.textSecondary),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Birthday Section ──────────────────────────────────────────────

  Widget _birthdaySection(BuildContext context, AppUser user, AuthProvider auth) {
    // Birthday banner if today is user's birthday
    final now = DateTime.now();
    final isBirthday = user.birthDate != null &&
        user.birthDate!.month == now.month &&
        user.birthDate!.day == now.day;

    if (isBirthday) {
      return Padding(
        padding: const EdgeInsets.only(bottom: S.x20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(S.x16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pinkAccent.withValues(alpha: 0.15), Colors.purpleAccent.withValues(alpha: 0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(R.lg),
            border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Text('\u{1F382}', style: TextStyle(fontSize: 28)),
              const SizedBox(width: S.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('С Днём рождения!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('Проверьте бонусные баллы в подарок', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Birthday prompt if not set
    if (user.birthDate == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: S.x20),
        child: GestureDetector(
          onTap: () => _pickBirthday(context, auth),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(S.x16),
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(R.lg),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.cake_rounded, size: 24, color: AppColors.gold),
                const SizedBox(width: S.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Укажите дату рождения', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('и получите 1000 баллов!', style: TextStyle(fontSize: 12, color: AppColors.gold)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      );
    }

    // Birthday is set — show it in a compact row
    final fmt = DateFormat('dd MMMM yyyy', 'ru');
    return Padding(
      padding: const EdgeInsets.only(bottom: S.x20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: S.x16, vertical: S.x12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(R.md),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, size: 18, color: AppColors.textTertiary),
            const SizedBox(width: S.x8),
            Text('Дата рождения: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(fmt.format(user.birthDate!), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  void _pickBirthday(BuildContext context, AuthProvider auth) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'ДАТА РОЖДЕНИЯ',
      cancelText: 'ОТМЕНА',
      confirmText: 'СОХРАНИТЬ',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.accent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      await ApiService.dio.patch(
        '/api/v1/users/me/birthday',
        data: {'birth_date': dateStr},
      );
      // Refresh profile and loyalty to get updated birthDate + points
      await auth.fetchProfile();
      await auth.fetchLoyalty();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Дата рождения сохранена! +1000 баллов')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить дату рождения')),
        );
      }
    }
  }

  Widget _stats(LoyaltyAccount l) {
    return Row(
      children: [
        _stat('${l.points}', 'БАЛЛОВ', AppColors.accent),
        const SizedBox(width: S.x8),
        _stat('${l.cashbackPercent}%', 'КЭШБЭК', AppColors.gold),
        const SizedBox(width: S.x8),
        _stat('${(l.totalSpent / 1000).toStringAsFixed(0)}K', 'ПОТРАЧЕНО', AppColors.textSecondary),
      ],
    );
  }

  Widget _stat(String value, String label, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: S.x16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(R.md),
          border: Border.all(color: c.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c)),
            const SizedBox(height: S.x4),
            Text(label, style: TextStyle(fontSize: 9, color: AppColors.textTertiary, letterSpacing: 1, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _menu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(R.md)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _menuRow(Icons.edit_outlined, 'Редактировать профиль', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
          }),
          _div(),
          _menuRow(Icons.favorite_outline_rounded, 'Избранное', () => _showFav(context)),
          _div(),
          _menuRow(Icons.receipt_long_outlined, 'Мои заказы', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
          }),
          _div(),
          _menuRow(Icons.history_rounded, 'История баллов', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()));
          }),
          _div(),
          _div(), _menuRow(Icons.card_giftcard_rounded, 'Box подписка', () => _showBox(context)),
          _div(), _menuRow(Icons.local_offer_outlined, 'Промокоды', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoCodesScreen()));
          }),
          _div(), _menuRow(Icons.location_on_outlined, 'Наши точки', () => showLocationsSheet(context)),
          _div(), _menuRow(Icons.notifications_outlined, 'Уведомления', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          }),
          _div(), _menuRow(Icons.info_outline_rounded, 'О Toolor', () => _showAbout(context)),
          _div(), _menuRow(Icons.brightness_6_outlined, 'Тема оформления', () => _showThemePicker(context)),
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: S.x16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: S.x12),
            Expanded(child: Text(title, style: TextStyle(fontSize: 13, color: AppColors.textPrimary))),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _div() => Padding(padding: const EdgeInsets.symmetric(horizontal: S.x16), child: Divider(color: AppColors.divider, height: 0.5));

  // ── Bottom Sheets ──────────────────────────────────────────────

  void _showFav(BuildContext context) {
    final favs = context.read<FavoritesProvider>().favorites;
    _sheet(context, 'ИЗБРАННОЕ (${favs.length})', favs.isEmpty
        ? Center(child: Text('Пусто', style: TextStyle(color: AppColors.textTertiary)))
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: S.x20),
            itemCount: favs.length,
            separatorBuilder: (_, _) => Divider(color: AppColors.divider, height: 1),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: S.x12),
              child: Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(favs[i].name, style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      Text(favs[i].formattedPrice, style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                    ],
                  )),
                  Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
    );
  }

  void _showBox(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(S.x16, 0, S.x16, S.x16),
        padding: const EdgeInsets.all(S.x24),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(R.xl)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TOOLOR BOX', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.textPrimary)),
            const SizedBox(height: S.x8),
            Text('Стилисты подберут комплект\nиз 3\u20135 вещей каждый месяц', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: S.x20),
            Row(children: [_boxCard('Basic', '4 990', '3 вещи'), const SizedBox(width: S.x12), _boxCard('Premium', '8 990', '5 вещей')]),
            const SizedBox(height: S.x20),
            SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('СКОРО'))),
          ],
        ),
      ),
    );
  }

  Widget _boxCard(String name, String price, String desc) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(S.x16),
      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: AppColors.gold.withValues(alpha: 0.15))),
      child: Column(children: [
        Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gold, letterSpacing: 0.5)),
        const SizedBox(height: S.x4),
        Text('$price сом', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(desc, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
      ]),
    ));
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(S.x16, 0, S.x16, S.x16),
        padding: const EdgeInsets.all(S.x24),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(R.xl)),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchPrimaryStore(),
          builder: (context, snap) {
            final store = snap.data;
            final address = store?['address'] as String?;
            final phone = store?['phone'] as String?;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'TOOLOR',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: S.x16),
                Text(
                  'Международный бренд функциональной верхней одежды, '
                  'вдохновленный эстетикой digital-номадов.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: S.x16),
                if (snap.connectionState == ConnectionState.waiting)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: S.x8),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                else ...[
                  if (address != null && address.isNotEmpty) ...[
                    _aboutRow(Icons.location_on_outlined, address),
                    const SizedBox(height: S.x8),
                  ],
                  if (phone != null && phone.isNotEmpty) ...[
                    _aboutRow(Icons.phone_outlined, phone),
                    const SizedBox(height: S.x8),
                  ],
                  _aboutRow(Icons.language_rounded, 'toolorkg.com'),
                ],
                const SizedBox(height: S.x16),
                Center(child: Text('v1.0.0', style: TextStyle(fontSize: 11, color: AppColors.textTertiary))),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Pick the first active storefront location as the brand's "primary"
  /// contact point. We intentionally prefer `type == 'store'` over
  /// showrooms/warehouses so the About sheet always shows a public
  /// address. Returns null if the request fails or no store is found.
  Future<Map<String, dynamic>?> _fetchPrimaryStore() async {
    try {
      final response = await ApiService.dio.get('/api/v1/locations');
      final raw = response.data;
      if (raw is! List) return null;
      Map<String, dynamic>? fallback;
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          fallback ??= item;
          if (item['type'] == 'store') {
            return item;
          }
        }
      }
      return fallback;
    } catch (_) {
      return null;
    }
  }

  Widget _aboutRow(IconData ic, String t) => Row(children: [Icon(ic, size: 16, color: AppColors.textTertiary), const SizedBox(width: S.x8), Expanded(child: Text(t, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)))]);

  void _showThemePicker(BuildContext context) {
    final themeProv = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final options = [
          (ThemePreference.system, 'Авто (по системе)', Icons.brightness_auto_outlined),
          (ThemePreference.light, 'Светлая', Icons.light_mode_outlined),
          (ThemePreference.dark, 'Тёмная', Icons.dark_mode_outlined),
        ];
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            margin: const EdgeInsets.fromLTRB(S.x16, 0, S.x16, S.x16),
            padding: const EdgeInsets.all(S.x24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(R.xl)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ТЕМА ОФОРМЛЕНИЯ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: AppColors.textSecondary)),
                const SizedBox(height: S.x16),
                ...options.map((o) {
                  final active = themeProv.pref == o.$1;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeProv.set(o.$1);
                      setSheetState(() {});
                      Navigator.pop(ctx);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: S.x12),
                      child: Row(
                        children: [
                          Icon(o.$3, size: 20, color: active ? AppColors.accent : AppColors.textSecondary),
                          const SizedBox(width: S.x12),
                          Expanded(child: Text(o.$2, style: TextStyle(fontSize: 14, color: active ? AppColors.accent : AppColors.textPrimary, fontWeight: active ? FontWeight.w600 : FontWeight.w400))),
                          if (active) Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sheet(BuildContext context, String title, Widget body) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(R.xl))),
        child: Column(children: [
          const SizedBox(height: S.x12),
          Container(width: 32, height: 3, decoration: BoxDecoration(color: AppColors.surfaceBright, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: S.x16),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: AppColors.textSecondary)),
          const SizedBox(height: S.x16),
          Expanded(child: body),
        ]),
      ),
    );
  }
}

