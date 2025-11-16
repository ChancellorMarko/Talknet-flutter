import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_talknet_app/ui/features/home/home_screen.dart';
import 'package:flutter_talknet_app/ui/features/login/forgot_password_screen.dart';
import 'package:flutter_talknet_app/ui/features/login/login_screen.dart';
import 'package:flutter_talknet_app/ui/features/register/register_screen.dart';
import 'package:flutter_talknet_app/utils/routes_enum.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await dotenv.load();

  final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'supabaseurl';
  final String supabaseKey = dotenv.env['SUPABASE_KEY'] ?? 'supabasekey';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(MainApp());
}

/// Aplicação principal
class MainApp extends StatelessWidget {
  /// Constructor da classe [MainApp]
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: FToastBuilder(),
      routes: {
        RoutesEnum.login.route: (context) => LoginScreen(),
        RoutesEnum.forgotPassword.route: (context) => const ForgotPasswordScreen(),
        RoutesEnum.register.route: (context) => const RegisterScreen(),
        RoutesEnum.home.route: (context) => const HomeScreen(),
      },
      initialRoute: RoutesEnum.login.route,
    );
  }
}
