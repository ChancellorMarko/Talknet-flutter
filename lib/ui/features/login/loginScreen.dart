import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_button.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_input.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_text_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_talknet_app/utils/routes_enum.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: SizedBox(
                  width: constraints.maxWidth > 768
                      ? 768
                      : constraints.maxWidth,
                  child: Column(
                    children: [
                      Image(
                        image: AssetImage('assets/logos/logo_login.png'),
                        height: 280,
                      ),
                      SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: Text('Login', style: TextStyle(fontSize: 20)),
                      ),
                      SizedBox(height: 18),
                      CustomInput(
                        hint: 'Digite seu email',
                        label: 'Email',
                        controller: emailController,
                      ),
                      SizedBox(height: 18),
                      CustomInput(
                        hint: 'Digite sua senha',
                        label: 'Senha',
                        controller: passwordController,
                      ),
                      Align(
                        alignment: AlignmentGeometry.centerRight,
                        child: CustomTextButton(
                          buttonText: 'Esqueci minha senha',
                          buttonAction: () {},
                        ),
                      ),
                      SizedBox(height: 18),
                      CustomButton(
                        buttonText: 'Entrar',
                        backgroundColor: Color(0xFF03A9F4),
                        buttonAction: () async {
                          final supabase = Supabase.instance.client;

                          final response = await supabase.auth
                              .signInWithPassword(
                                password: passwordController.text,
                                email: emailController.text,
                              );

                          print(response);
                        },
                      ),
                      SizedBox(height: 18),
                      CustomTextButton(
                        buttonText: 'Não tem uma conta? Cadastre-se',
                        buttonAction: () {
                          Navigator.pushNamed(
                            context,
                            RoutesEnum.register.route,
                          ); // Named route
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
