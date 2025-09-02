import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../themes/app_theme.dart';
import '../provider/join_expert_provider.dart';

class JoinExpertFilesStep extends StatelessWidget {
  const JoinExpertFilesStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JoinExpertProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload_file_rounded,
                  size: 64.sp,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: 16.h),
                Text(
                  "Upload Files Step",
                  style: GoogleFonts.raleway(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Coming soon...",
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => provider.previousStep(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryColor),
                          foregroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          "Back",
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Application Submitted Successfully!",
                                style: GoogleFonts.raleway(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: AppTheme.primaryColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          "Submit Application",
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
