import 'package:auth/new_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? imageName;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Usernames',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Erica One'),
                ),
                SizedBox(
                  height: 25.h,
                ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 30.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      height: 1.2.h,
                      fontFamily: 'Aunchanted Xspace',
                      wordSpacing: 1,
                    ),
                    children: const [
                      TextSpan(text: 'Access dApps,\n'),
                      TextSpan(
                        text: 'do transactions',
                      ),
                    ],
                  ),
                ),
                Text(
                  'with',
                  style: TextStyle(
                      fontSize: 30.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      // height: 1.2.h,
                      fontFamily: 'Aunchanted Xspace'),
                ),
                Text(
                  'usernames',
                  style: TextStyle(
                      fontSize: 35.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      // height: 1.2.h,
                      fontFamily: 'Aunchanted Xspace'),
                ),
                SizedBox(
                  height: 5.h,
                ),
                Text(
                  'This NFT market is the perfect',
                  style: TextStyle(
                      fontFamily: 'Aunchanted Xspace',
                      fontSize: 15.sp,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400),
                ),
                Text(
                  "fit for you to trade NFT's",
                  style: TextStyle(
                      fontFamily: 'Aunchanted Xspace',
                      fontSize: 15.sp,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 125.h,
                      width: 120.w,
                      margin: EdgeInsets.only(right: 55.r, top: 20.r),
                      child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) {
                              return const NewLoginScreen();
                            }));
                          },
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(0).w,
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(80).w,
                              )),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Aunchanted Xspace',
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Started',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Aunchanted Xspace',
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
