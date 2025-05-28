import 'package:fastfood/layers/presentation/pages/home_page.dart';
import 'package:fastfood/layers/presentation/pages/screens/order_lis_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hive/hive.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  //
  void _saveworkType(String workType) async {
    var auth = Hive.box("workType");
    auth.put("workType", workType);
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.amber,
    body: SafeArea(
      child: Center( // Bu yerda Center qo‘shildi
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min, // faqat kerakli balandlikda bo‘ladi
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Kim bo'lib ishlashingizni tanlang",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Gap(20.h),
              SizedBox(
                width: MediaQuery.of(context).size.width >= 600
                    ? 350.w
                    : double.infinity,
                height: 55.h,
                child: ElevatedButton(
                  onPressed: () {
                    _saveworkType('admin');
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => HomePage()),
                        (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white),
                  child: Text(
                    "Admin",
                    style: TextStyle(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber),
                  ),
                ),
              ),
              Gap(10.h),
              SizedBox(
                width: MediaQuery.of(context).size.width >= 600
                    ? 350.w
                    : double.infinity,
                height: 55.h,
                child: ElevatedButton(
                  onPressed: () {
                    _saveworkType('shef');
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => OrderListPage()),
                        (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white),
                  child: Text(
                    "Oshpaz",
                    style: TextStyle(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

}
