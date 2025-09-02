import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../themes/app_theme.dart';
import '../provider/join_expert_provider.dart';

class JoinExpertAboutStep extends StatelessWidget {
  const JoinExpertAboutStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JoinExpertProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildAboutCard(),
              SizedBox(height: 24.h),
              _buildNextStepsCard(),
              SizedBox(height: 32.h),
              _buildContinueButton(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: AppTheme.primaryColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "About FitTalk",
                style: GoogleFonts.raleway(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            "FitTalk is a platform connecting fitness, wellness, and health experts with clients seeking personalized guidance. As a FitTalk expert, you'll have the opportunity to:",
            style: GoogleFonts.raleway(
              color: Colors.grey.shade700,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.h),
          ..._buildBenefitsList(),
        ],
      ),
    );
  }

  List<Widget> _buildBenefitsList() {
    final benefits = [
      "Build your online presence and expand your client base",
      "Set your own rates and availability",
      "Conduct virtual consultations and coaching sessions",
      "Access tools to manage your clients and track progress",
      "Join a community of like-minded professionals",
    ];

    return benefits.map((benefit) => _buildBenefit(benefit)).toList();
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 2.h),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppTheme.primaryColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.raleway(
                color: Colors.black87,
                fontSize: 14.sp,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.flash_on_rounded,
                  color: Colors.amber.shade700,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "What happens next?",
                style: GoogleFonts.raleway(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            "Complete the application below to start your journey with FitTalk. Our team will review your credentials and get back to you within 24-48 hours.",
            style: GoogleFonts.raleway(
              color: Colors.grey.shade700,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          _buildNextStep("1", "Fill out your personal information"),
          _buildNextStep("2", "Add your professional details and specializations"),
          _buildNextStep("3", "Upload profile images and certifications"),
          _buildNextStep("4", "Submit for review and approval"),
        ],
      ),
    );
  }

  Widget _buildNextStep(String number, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.raleway(
                color: Colors.black87,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, JoinExpertProvider provider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ElevatedButton(
        onPressed: () {
          // Advance to next step in the multi-step flow
          context.read<JoinExpertProvider>().nextStep();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
          shadowColor: AppTheme.primaryColor.withOpacity(0.3),
        ),
        child: Text(
          "Get Started",
          style: GoogleFonts.raleway(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
