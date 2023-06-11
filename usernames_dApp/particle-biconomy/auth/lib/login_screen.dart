import 'dart:developer';
import 'package:auth/home.dart';
import 'package:flutter/material.dart';
import 'package:particle_auth/model/chain_info.dart';
import 'package:particle_auth/model/login_info.dart';
import 'package:particle_auth/particle_auth.dart';

class LoginPage extends StatefulWidget {
  final String? title;

  const LoginPage({Key? key, this.title}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController usernameController = TextEditingController();
  bool isValidUsername = false;
  

  Future<void> particleStuff() async {
    ParticleAuth.init(EthereumChain.goerli(), Env.dev);
    List<SupportAuthType> supportAuthType = <SupportAuthType>[];
    supportAuthType.add(SupportAuthType.all);
    String result =
        await ParticleAuth.login(LoginType.phone, "", supportAuthType);
    log(result);
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  void checkUsername() {
    String username = usernameController.text;

    bool isValid = (username == username);

    setState(() {
      isValidUsername = isValid;
    });

    if (isValid) {
      Navigator.push(context,
          MaterialPageRoute(builder: (BuildContext context) {
        return const HomeScreen();
      }));
      log('Valid username: $username');
    } else if (!isValid) {
      particleStuff();
      log('Invalid username');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return SingleChildScrollView(
                        child: Container(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                            left: 16.0,
                            right: 16.0,
                            top: 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Enter username',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              TextField(
                                controller: usernameController,
                                decoration: const InputDecoration(
                                  hintText: 'Username',
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              ElevatedButton(
                                onPressed: checkUsername,
                                child: const Text('Check Username'),
                              ),
                              const SizedBox(height: 8.0),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: const Text('LOGIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///
