// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/forgot_password_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/admin_user_list_screen.dart';
import 'presentation/screens/admin_user_detail_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'domain/entities/user_entity.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/ticket_provider.dart';

/// Global key on the root [Navigator]. Held as a top-level so
/// [MyApp] can route the user to `/login` even if the screen-level
/// [BuildContext] is unmounted (which can happen during the brief
/// window between `logout()` setting `state = null` and the
/// Stream-side listener firing). Bug fix 2026-06-24: prior to
/// this key the redirect was a no-op in some flows because the
/// `ProfileScreen` context was stale by the time we tried to
/// call `Navigator.pushNamedAndRemoveUntil` from inside the
/// Sign-Out dialog.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (SUPABASE_URL, SUPABASE_ANON_KEY)
  await dotenv.load(fileName: '.env');

  // Initialise date formatting for the locales used in the app
  // (the redesigned ticket detail / tracking sheets use
  // `DateFormat('d MMMM y, HH:mm', 'id_ID')` etc. — without this
  // call, `intl` throws `LocaleDataException` on the first build
  // that hits a localised date).
  await initializeDateFormatting('id_ID');
  await initializeDateFormatting('en_US');

  // Initialize Supabase. Anonymous key is safe in client apps because
  // Row Level Security in the database enforces who can do what.
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 2026-06-25 fix: make the OS status bar transparent and let
  // the app paint under it. Without this, Flutter draws a solid
  // black bar on Android 11+ where the gesture pill / cutout
  // lives, making the top of every screen feel "mepet" to the
  // status bar. The per-screen `SafeArea(top: true, bottom: false)`
  // wrappers handle the actual inset; this only configures
  // the bar's appearance so it stays transparent.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF8FAFF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  /// Guards against re-entering the Sign-Out → /login redirect.
  /// Set to `true` the moment a logout is detected and reset
  /// to `false` once the navigator successfully lands on /login.
  /// Prevents the Navigator from being navigated multiple times
  /// in the same logout event when `currentUserProvider`
  /// transitions null→non-null→null across rebuilds (which would
  /// otherwise hit `assert(_history.isNotEmpty)` inside the
  /// Flutter framework — see lib/main.dart top-of-file note).
  static bool _redirecting = false;

  Future<void> _redirectToLogin() async {
    if (_redirecting) return;
    _redirecting = true;
    try {
      // 500ms pre-wait + 2x endOfFrame. This is the most
      // generous pre-wait we've tried — it lets every part
      // of the sign-out pipeline fully settle (dialog exit
      // animation, Supabase stream event, Riverpod setState
      // chain, profile-provider re-resolution) before we
      // touch the Navigator. Past attempts at 50/100/300ms
      // either still hit the `assert(_history.isEmpty)`
      // assertion or left the screen blank with the URL on
      // `/#/login` — the route was pushed but its overlay
      // entry never made it past the `push` lifecycle state.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final navigator = rootNavigatorKey.currentState;
      if (navigator == null || !navigator.mounted) return;

      // Defer the Navigator push to the next post-frame callback.
      // Without this, the Navigator transition races against the
      // `ticketInvalidatorProvider` re-fetch chain (which fires
      // when `currentUserProvider` becomes null and triggers
      // `ref.invalidate(...)` on every ticket-related provider).
      // The re-fetch runs while the route push is mid-animation,
      // leaving the previous screen's surface visible behind
      // `/login` for ~1 frame. On real Android devices that
      // manifests as: `/login` flashes briefly → blank hitam
      // (previous screen's surface, usually `c.surface` in dark
      // mode = `#121926`) on top.
      //
      // `addPostFrameCallback` ensures the Navigator swap happens
      // AFTER Flutter has settled the current frame, including
      // any side effects from `ref.watch(ticketInvalidatorProvider)`
      // in the root `MyApp.build`.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = rootNavigatorKey.currentState;
        if (nav == null || !nav.mounted) return;
        nav.pushNamedAndRemoveUntil('/login', (route) => false);
      });
    } catch (e, st) {
      debugPrint('[Auth] redirect-to-login failed: $e\n$st');
    } finally {
      Future.microtask(() => _redirecting = false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    // Activate the side-effect provider that invalidates ticket
    // providers on every Supabase auth event. This is what makes a
    // cold start with a restored session show fresh data instead of
    // a stale in-memory list.
    ref.watch(ticketInvalidatorProvider);

    // Bug fix 2026-06-24: route the user to /login automatically
    // whenever `currentUserProvider` transitions from a non-null
    // value to `null` (i.e. after the Sign-Out dialog calls
    // `currentUserProvider.notifier.logout()`). Doing this at the
    // root via `ref.listen` means:
    //   1. The redirect happens regardless of whether the screen-
    //      level `BuildContext` is still mounted by the time the
    //      auth state actually goes null (which it wasn't, on the
    //      previous implementation — the dialog's lambda raced
    //      against the stream listener that nulled the state).
    //   2. We can't accidentally route on cold start (the initial
    //      `prev` is also null, so the `prev != null` guard
    //      short-circuits).
    // The `rootNavigatorKey` is used because it isn't tied to a
    // screen-level context and is always valid as long as the
    // [MaterialApp] is mounted.
    ref.listen<UserEntity?>(currentUserProvider, (UserEntity? prev, UserEntity? next) {
      if (prev != null && next == null) {
        _redirectToLogin();
      }
    });

    return MaterialApp(
      title: 'HelpDesk E-Ticketing',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // 2026-06-25 fix: wrap every route in AnnotatedRegion so
      // the OS status-bar icons (clock, network, battery…) flip
      // between dark icons on the light surface and light icons
      // on the dark surface. Pairs with the
      // `Colors.transparent` statusBarColor we set in `main()`.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFFF8FAFF),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/home': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/admin/users': (_) => const AdminUserListScreen(),
        '/admin/user-detail': (ctx) {
          final user =
              ModalRoute.of(ctx)!.settings.arguments as UserEntity;
          return AdminUserDetailScreen(user: user);
        },
      },
    );
  }
}
