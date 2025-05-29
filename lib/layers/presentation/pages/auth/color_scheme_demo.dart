import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Demo widget to showcase the improved color scheme for form validation
/// This demonstrates the visual hierarchy and accessibility of the new error styling
class LoginColorSchemeDemo extends StatelessWidget {
  const LoginColorSchemeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber,
      appBar: AppBar(
        title: Text('Login Color Scheme Demo'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Form Field States',
                style: GoogleFonts.outfit(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32.h),
              
              // Normal State
              _buildDemoField(
                label: 'Normal State',
                borderColor: Colors.transparent,
                fillColor: Colors.white,
                textColor: Colors.black87,
              ),
              SizedBox(height: 16.h),
              
              // Focused State
              _buildDemoField(
                label: 'Focused State',
                borderColor: Colors.amber,
                fillColor: Colors.white,
                textColor: Colors.black87,
                borderWidth: 2,
              ),
              SizedBox(height: 16.h),
              
              // Error State (Not Focused)
              _buildDemoField(
                label: 'Error State',
                borderColor: Colors.orange.shade600,
                fillColor: Colors.white,
                textColor: Colors.black87,
                borderWidth: 2,
                showError: true,
                errorText: 'This field is required',
              ),
              SizedBox(height: 16.h),
              
              // Error State (Focused)
              _buildDemoField(
                label: 'Error State (Focused)',
                borderColor: Colors.deepOrange.shade500,
                fillColor: Colors.white,
                textColor: Colors.black87,
                borderWidth: 2,
                showError: true,
                errorText: 'Please enter a valid email address',
              ),
              SizedBox(height: 32.h),
              
              // Color Accessibility Information
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color Accessibility',
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _buildColorInfo('Normal Border', 'Transparent', 'Clean, minimal appearance'),
                    _buildColorInfo('Focus Border', 'Amber (#FFC107)', 'Matches app theme'),
                    _buildColorInfo('Error Border', 'Orange (#FF9800)', 'Harmonious with amber theme'),
                    _buildColorInfo('Error Focus', 'Deep Orange (#FF5722)', 'Clear error indication'),
                    _buildColorInfo('Error Text', 'Orange 700', 'Readable and consistent'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoField({
    required String label,
    required Color borderColor,
    required Color fillColor,
    required Color textColor,
    double borderWidth = 0,
    bool showError = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(16.r),
            border: borderWidth > 0 
                ? Border.all(color: borderColor, width: borderWidth)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            enabled: false,
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: 'Sample input text',
              hintStyle: GoogleFonts.outfit(
                fontSize: 16.sp,
                color: Colors.grey.shade500,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: Colors.amber.shade700,
                size: 24.sp,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 20.h,
              ),
              filled: true,
              fillColor: fillColor,
            ),
          ),
        ),
        if (showError && errorText != null) ...[
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(left: 16.w),
            child: Text(
              errorText,
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildColorInfo(String name, String color, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(
            width: 100.w,
            child: Text(
              color,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
