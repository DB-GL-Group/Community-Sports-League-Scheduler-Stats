import 'package:community_sports_league_scheduler/authprovider.dart';
import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/widgets/template.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LogInPage extends StatelessWidget {

  const LogInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: Center(
        child: Column(
          children: [
            const Text(
              'Log in Page',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            LogInForm()
          ],
        )
      )
    );
  }
  
}

class LogInForm extends StatefulWidget {
  const LogInForm({super.key});

  @override
  State<StatefulWidget> createState() => _LogInFormState();
}

class _LogInFormState extends State<LogInForm> {
  final GlobalKey<FormState> _logInFormKey = GlobalKey<FormState>();
  bool _isLocked = false;
  String _formMessage = '';

  String? email;
  String? password;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _logInFormKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom:0),
            child: SizedBox(
              width: 400,
              child: TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                  hintText: 'Enter valid email'
                ),
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email is required';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
                  return null;
                },
                onSaved: (value) => email = value,
              ),
            )
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 20),
            child: SizedBox(
              width: 400,
              child: TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  hintText: 'Enter your password'
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password is required';
                  return null;
                },
                onSaved: (value) => password = value,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 0, bottom: 20),
            child: Center(child: Text(
              _formMessage,
              style: TextStyle(
                color: _formMessage.startsWith("Wrong credentials") ? Colors.red : Colors.black
              )
            ))
          ),
          ElevatedButton(
            onPressed: _isLocked ? null : () async {
              if (_logInFormKey.currentState!.validate()) {
                _logInFormKey.currentState!.save();
                try {
                  final data = await context.read<ApiRouter>().fetchData('auth/login', method: 'POST', body: {
                    "email":email!,
                    "password":password!
                  });
                  final user_json = data['user'];
                  final user = User.fromJson(user_json);
                  context.read<AuthProvider>().login(user);
                  context.go('/');
                  
                } catch (e) { // wrong credentials
                  setState(() {
                    _formMessage = 'Please wait while we check your login...';
                    _isLocked = true;
                  });
                  Future.delayed(Duration(seconds: 3), () {
                    setState(() {
                      _formMessage = 'Wrong credentials, please try again';
                      _isLocked = false;
                    });
                  });
                }
              }
            },
            child: const Text('Log In')
          )
        ],
      )
    );
  }
  
}