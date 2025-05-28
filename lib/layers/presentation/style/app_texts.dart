import 'package:fastfood/layers/presentation/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyle {
  static TextStyle textSize12 = GoogleFonts.outfit(
    fontWeight: FontWeight.w400,
    fontSize: 12.sp,
    height: (16.94 / 12).h,
    color: AppColors.primaryColor,
  );
  static TextStyle textSize14 = GoogleFonts.outfit(
    fontWeight: FontWeight.w400,
    fontSize: 14.sp,
    height: (16.94 / 14).h,
    color: AppColors.primaryColor,
  );

  static TextStyle textSize15 = GoogleFonts.outfit(
    fontWeight: FontWeight.w400,
    fontSize: 15.sp,
    color: AppColors.primaryColor,
    height: 1.47.h,
  );

  static TextStyle textSize16 = GoogleFonts.outfit(
    fontWeight: FontWeight.w400,
    fontSize: 16.sp,
    color: AppColors.primaryColor,
    height: 1.21.h,
  );

  static TextStyle textSize18 = GoogleFonts.outfit(
    fontWeight: FontWeight.w400,
    fontSize: 18.sp,
    color: AppColors.primaryColor,
    height: 1.21.h,
  );



  static TextStyle textSize20 = GoogleFonts.outfit(
    fontWeight: FontWeight.w600,
    fontSize: 20.sp,
    height: 1.21.h,
    color: AppColors.primaryColor,
  );

  static TextStyle textSize30 = GoogleFonts.outfit(
    fontWeight: FontWeight.w600,
    fontSize: 30.sp,
    height: 1.21.h,
    color: AppColors.primaryColor,
  );
}
