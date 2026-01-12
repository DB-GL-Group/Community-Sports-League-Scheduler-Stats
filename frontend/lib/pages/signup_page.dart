import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: Center(
        child: Column(
          children: const [
            Text(
              'Sign up Page',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            SignUpForm(),
          ],
        ),
      ),
    );
  }
}

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<StatefulWidget> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final GlobalKey<FormState> _signUpFormKey = GlobalKey<FormState>();
  bool _isLocked = false;
  String _formMessage = '';

  String? firstName;
  String? lastName;
  String? email;
  String? password;

  bool _wantsManager = false;
  bool _wantsReferee = false;

  final _managerKeyController = TextEditingController();
  final _refereeKeyController = TextEditingController();

  @override
  void dispose() {
    _managerKeyController.dispose();
    _refereeKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _signUpFormKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 20, bottom: 0),
            child: SizedBox(
              width: 400,
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'First Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'First name is required';
                  return null;
                },
                onSaved: (value) => firstName = value,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
            child: SizedBox(
              width: 400,
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Last Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Last name is required';
                  return null;
                },
                onSaved: (value) => lastName = value,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
            child: SizedBox(
              width: 400,
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                  hintText: 'Enter valid email',
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
            child: SizedBox(
              width: 400,
              child: TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  hintText: 'Enter your password',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password is required';
                  if (value.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
                onSaved: (value) => password = value,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 10, bottom: 0),
            child: SizedBox(
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Roles', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Fan is selected by default.'),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Manager'),
                    value: _wantsManager,
                    onChanged: (value) {
                      setState(() {
                        _wantsManager = value ?? false;
                      });
                    },
                  ),
                  if (_wantsManager)
                    TextFormField(
                      controller: _managerKeyController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Manager Key',
                      ),
                      validator: (value) {
                        if (!_wantsManager) return null;
                        if (value == null || value.isEmpty) return 'Manager key is required';
                        return null;
                      },
                    ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Referee'),
                    value: _wantsReferee,
                    onChanged: (value) {
                      setState(() {
                        _wantsReferee = value ?? false;
                      });
                    },
                  ),
                  if (_wantsReferee)
                    TextFormField(
                      controller: _refereeKeyController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Referee Key',
                      ),
                      validator: (value) {
                        if (!_wantsReferee) return null;
                        if (value == null || value.isEmpty) return 'Referee key is required';
                        return null;
                      },
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 20),
            child: Center(
              child: Text(
                _formMessage,
                style: TextStyle(
                  color: _formMessage.startsWith("Sign up") ? Colors.black : Colors.red,
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isLocked
                ? null
                : () async {
                    if (_signUpFormKey.currentState!.validate()) {
                      _signUpFormKey.currentState!.save();
                      setState(() {
                        _formMessage = 'Creating account...';
                        _isLocked = true;
                      });
                      try {
                        final roles = <String>['FAN'];
                        final roleKeys = <String, String>{};
                        if (_wantsManager) {
                          roles.add('MANAGER');
                          roleKeys['MANAGER'] = _managerKeyController.text.trim();
                        }
                        if (_wantsReferee) {
                          roles.add('REFEREE');
                          roleKeys['REFEREE'] = _refereeKeyController.text.trim();
                        }

                        await context.read<ApiRouter>().fetchData(
                          'auth/signup',
                          method: 'POST',
                          body: {
                            "first_name": firstName!,
                            "last_name": lastName!,
                            "email": email!,
                            "password": password!,
                            "roles": roles,
                            "role_keys": roleKeys.isEmpty ? null : roleKeys,
                          },
                        );

                        if (!mounted) return;
                        setState(() {
                          _formMessage = 'Account created. Redirecting to login...';
                        });
                        Future.delayed(const Duration(seconds: 1), () {
                          if (!mounted) return;
                          context.go('/login');
                        });
                      } catch (e) {
                        if (!mounted) return;
                        setState(() {
                          _formMessage = 'Sign up failed. Please check your inputs.';
                          _isLocked = false;
                        });
                      }
                    }
                  },
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}
