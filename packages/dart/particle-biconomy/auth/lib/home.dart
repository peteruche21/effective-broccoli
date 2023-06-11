import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          // backgroundColor: Colors.red,
          body: Center(
        child: Text(
          'COMING SOON...',
          style: TextStyle(
              color: Colors.black,
              fontFamily: "Solomon's Key True Type",
              fontSize: 20.sp),
        ),
      )),
    );
  }
}

class GreenCard extends StatelessWidget {
  const GreenCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20).w,
            color: const Color(0xffB2FF57)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '\$53464,12',
              style: TextStyle(
                  fontFamily: "Solomon's Key True Type",
                  fontSize: 35.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              'My Balance',
              style: TextStyle(
                  fontFamily: 'Aunchanted Xspace',
                  fontSize: 15.sp,
                  color: Color(0xff78B52F)
                  // color: Colors.grey
                  ),
            )
          ],
        ),
      ),
    );
  }
}

// Solomon's Key Font