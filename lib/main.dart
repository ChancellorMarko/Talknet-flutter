import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_talknet_app/ui/features/login/loginScreen.dart';
import 'package:flutter_talknet_app/ui/features/register/register_screen.dart';
import 'package:flutter_talknet_app/utils/routes_enum.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await dotenv.load();

  final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'supabaseurl';
  final String supabaseKey = dotenv.env['SUPABASE_KEY'] ?? 'supabasekey';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        RoutesEnum.login.route: (context) => LoginScreen(),
        RoutesEnum.register.route: (context) => RegisterScreen(),
      },
      initialRoute: RoutesEnum.login.route,
    );
  }
}
