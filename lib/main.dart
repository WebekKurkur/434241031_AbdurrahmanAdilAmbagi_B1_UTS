// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/ticket_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (SUPABASE_URL, SUPABASE_ANON_KEY)
  await dotenv.load(fileName: '.env');

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

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    // Activate the side-effect provider that invalidates ticket
    // providers on every Supabase auth event. This is what makes a
    // cold start with a restored session show fresh data instead of
    // a stale in-memory list.
    ref.watch(ticketInvalidatorProvider);

    return MaterialApp(
      title: 'HelpDesk E-Ticketing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
