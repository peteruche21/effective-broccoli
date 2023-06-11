import 'dart:developer';

import 'package:auth/biconomy_auth_logic.dart';
import 'package:auth/home.dart';
import 'package:auth/user_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:particle_auth/model/chain_info.dart';
import 'package:particle_auth/model/login_info.dart';
import 'package:particle_auth/particle_auth.dart';

class NewLoginScreen extends StatefulWidget {
  const NewLoginScreen({
    super.key,
  });

  @override
  State<NewLoginScreen> createState() => _NewLoginScreenState();
}

String assetName = 'assets/icons/logo-google.svg';
final Widget svg = SvgPicture.asset(
  assetName,
);

class _NewLoginScreenState extends State<NewLoginScreen> {
  final TextEditingController? textEditingController = TextEditingController();
  bool isUsernameValid = true;
  bool validate = false;
  final currName = MockEthNames();
  final GlobalKey<FormState> formKey = GlobalKey();

  Future<void> createBlockchainAccount() async {
    ParticleAuth.init(EthereumChain.goerli(), Env.dev);
    List<SupportAuthType> supportAuthType = <SupportAuthType>[];
    supportAuthType.add(SupportAuthType.all);

    final result = await ParticleAuth.login(
      LoginType.email,
      "",
      supportAuthType,
    );
    log(result);
  }

  @override
  void dispose() {
    textEditingController?.dispose();
    super.dispose();
  }

  // bool _isUsernameAvailable(String username) {
  //   return !widget.MockEthNames.doesExist(username);
  // }

// final String currentValue = us
  String checkUsername() {
    String? username = textEditingController!.text;
    if (!username.contains('.usernames.bit')) {
      username = username + '.usernames.bit';
    }
    return username;
  }

  @override
  void initState() {
    textEditingController?.addListener(() {
      checkUsername();
    });
    BiconomyAuthlogic.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String username = checkUsername();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          stops: [0.0, 0.8],
          colors: [
            Color(0xFFE2ECE9), // #E2ECE9
            Color(0xFFF2F3EC), // #F2F3EC
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'usernames',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Erica One'),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 35,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        fontFamily: 'Aunchanted Xspace',
                        wordSpacing: 1,
                      ),
                      children: [
                        TextSpan(text: 'Login'),
                        TextSpan(
                          text: ' with Web3 ',
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'usernames',
                    style: TextStyle(
                        fontSize: 35,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        fontFamily: 'Aunchanted Xspace'),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Container(
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
                        const SizedBox(height: 16.0),
                        UserNameInput(
                            textEditingController: textEditingController,
                            hintText: 'Enter UserName',
                            color: isUsernameValid ? Colors.green : Colors.red,
                            borderSiderColor: /* isUsernameValid ? */
                                Colors.green /* : Colors.red, */
                            // errorText: textEditingController!.text.isEmpty
                            //     ? 'field cannot be empty'
                            //     : null,
                            // formKey: formKey,
                            ),
                        SizedBox(height: 16.0.h),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final username = checkUsername();
                      bool isTrue = MockEthNames.doesExist(username);
                      if (isTrue) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) {
                              return const HomeScreen();
                            },
                          ),
                        );
                      } else if (!MockEthNames.doesExist(username)) {
                        Fluttertoast.showToast(
                            msg:
                                "Username does not exist\n please create an account",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM_RIGHT,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            fontSize: 16.0);
                      }
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                          fontFamily: 'Aunchanted Xspace',
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (username.isEmpty ||
                          !MockEthNames.doesExist(username)) ...[
                        TextButton(
                          onPressed: () {
                            BiconomyAuthlogic.loginParticle();
                          },
                          child: const Text(
                            'Create account',
                            style: TextStyle(
                                fontFamily: 'Aunchanted Xspace',
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                      ]
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Row createAccountAndLogin() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [

  //       const SizedBox(
  //         width: 30,
  //       ),
  //       TextButton(
  //           onPressed: () {},
  //           child: const Text(
  //             'Login/Link',
  //             style: TextStyle(
  //                 fontFamily: 'Aunchanted Xspace',
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.black),
  //           )),
  //     ],
  //   );
  // }
}

class UserNameInput extends StatefulWidget {
  final String hintText;
  final TextEditingController? textEditingController;
  final String? errorText;
  final Color color;
  final Color borderSiderColor;
  final String? Function(String?)? validator;

  const UserNameInput(
      {required this.textEditingController,
      required this.hintText,
      this.errorText,
      required this.color,
      required this.borderSiderColor,
      this.validator,
      Key? key})
      : super(key: key);

  @override
  State<UserNameInput> createState() => _UserNameInputState();
}

class _UserNameInputState extends State<UserNameInput> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60.h,
      child: TextFormField(
          style: const TextStyle(
              color: Colors.black, fontFamily: 'Aunchanted Xspace'),
          controller: widget.textEditingController,
          // obscureText: !pwdVisibility,god
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixText: '.usernames.bit',
            helperStyle: const TextStyle(color: Colors.black),
            helperText: ' ',
            errorText: widget.errorText,
            hintStyle: const TextStyle(fontFamily: 'Aunchanted Xspace'),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: widget.color,
                width: 1.w,
              ),
              borderRadius: BorderRadius.circular(25.0).r,
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: widget.borderSiderColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(25.0).r,
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(25.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: widget.borderSiderColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
          validator: widget.validator),
    );
  }
}

//  Fluttertoast.showToast(
//         msg: "This username does not exist",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.CENTER,
//         timeInSecForIosWeb: 1,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//         fontSize: 16.0);

// submit without using button
  // void _submitForm() {
  //   if (_formKey.currentState?.validate() == true) {
  //     _formKey.currentState?.save();
  //     // String domain = '.eth';
  //     String? username = textEditingController!.text;

  //     if (!username.contains('.eth')) {
  //       final name = username + '.eth';
  //       log(name);
  //       bool works = MockEthNames.doesExist(name);
  //       if (works) {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(
  //             builder: (BuildContext context) {
  //               return const HomeScreen();
  //             },
  //           ),
  //         );
  //       } else {
  //         if (MockEthNames.doesExist(name)) {
  //           Fluttertoast.showToast(
  //               msg: "This username does not exist",
  //               toastLength: Toast.LENGTH_SHORT,
  //               gravity: ToastGravity.CENTER,
  //               timeInSecForIosWeb: 1,
  //               backgroundColor: Colors.red,
  //               textColor: Colors.white,
  //               fontSize: 16.0);
  //         }
  //       }
  //     }
  //     log('Form submitted!');
  //   }
  // }
