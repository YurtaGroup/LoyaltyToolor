import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/store_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';
import 'services/analytics_service.dart';
import 'services/api_service.dart';

const _sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await ApiService.init();
  await ApiService.bootstrapGuest();

  if (_sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        options.tracesSampleRate = 0.3;
        options.environment = 'production';
      },
      appRunner: () => runApp(const ToolorApp()),
    );
  } else {
    runApp(const ToolorApp());
  }
}

class ToolorApp extends StatelessWidget {
  const ToolorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) => MaterialApp(
          title: 'TOOLOR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProv.themeMode,
          builder: (context, child) {
            final bright = Theme.of(context).brightness;
            AppColors.applyBrightness(bright);
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: bright == Brightness.dark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: AppColors.surface,
              systemNavigationBarIconBrightness: bright == Brightness.dark ? Brightness.light : Brightness.dark,
            ));
            return child!;
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru'),
            Locale('en'),
          ],
          locale: const Locale('ru'),
          home: const MainShell(),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  bool _notificationsStarted = false;
  bool _sessionChecked = false;
  bool _storeInitialized = false;
  bool _favoritesSynced = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Try to restore session on first build
    if (!_sessionChecked) {
      _sessionChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        auth.tryRestoreSession();
      });
    }

    // Initialize store provider once
    if (!_storeInitialized) {
      _storeInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<StoreProvider>().init();
      });
    }

    // Start notification polling once the user logs in
    if (auth.isLoggedIn && !_notificationsStarted) {
      _notificationsStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<NotificationProvider>().startPolling();
      });
    } else if (!auth.isLoggedIn && _notificationsStarted) {
      _notificationsStarted = false;
      context.read<NotificationProvider>().stopPolling();
    }

    // Sync favorites from the server on login, clear cache on logout.
    if (auth.isLoggedIn && !_favoritesSynced) {
      _favoritesSynced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FavoritesProvider>().syncFromServer();
      });
    } else if (!auth.isLoggedIn && _favoritesSynced) {
      _favoritesSynced = false;
      context.read<FavoritesProvider>().clearOnLogout();
    }

    final screens = [
      const HomeScreen(),
      const CatalogScreen(),
      const LoyaltyQrScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider, width: 0.5))),
        child: Consumer<CartProvider>(
          builder: (context, cart, _) => BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) async {
              HapticFeedback.selectionClick();
              // QR tab requires a real customer account — push AuthScreen
              // and only switch to the tab after a successful login.
              if (i == 2 && !auth.isLoggedIn) {
                AnalyticsService.track('open_qr_gate', payload: {});
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
                if (ok == true && mounted) {
                  setState(() => _tab = 2);
                }
                return;
              }
              setState(() => _tab = i);
            },
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 22),
                activeIcon: Icon(Icons.home_rounded, size: 22),
                label: 'Главная',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined, size: 22),
                activeIcon: Icon(Icons.grid_view_rounded, size: 22),
                label: 'Каталог',
              ),
              // ── Center tab: "Моя карта" — bigger icon, stands out ──
              BottomNavigationBarItem(
                icon: Transform.translate(
                  offset: const Offset(0, 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.qr_code_2_outlined, size: 28, color: AppColors.accent),
                  ),
                ),
                activeIcon: Transform.translate(
                  offset: const Offset(0, 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.qr_code_2_rounded, size: 28, color: AppColors.accent),
                  ),
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: cart.itemCount > 0,
                  backgroundColor: AppColors.accent,
                  label: Text('${cart.itemCount}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                  child: const Icon(Icons.shopping_bag_outlined, size: 22),
                ),
                activeIcon: Badge(
                  isLabelVisible: cart.itemCount > 0,
                  backgroundColor: AppColors.accent,
                  label: Text('${cart.itemCount}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                  child: const Icon(Icons.shopping_bag_rounded, size: 22),
                ),
                label: 'Корзина',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline, size: 22),
                activeIcon: Icon(Icons.person_rounded, size: 22),
                label: 'Профиль',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
