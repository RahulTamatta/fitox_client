import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../themes/app_theme.dart';
import '../provider/join_expert_provider.dart';

class JoinExpertPersonalStep extends StatelessWidget {
  const JoinExpertPersonalStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JoinExpertProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 28.sp,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Personal Information",
                    style: GoogleFonts.raleway(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Full Name
              TextField(
                decoration: _inputDecoration("Full Name"),
                onChanged: provider.updateFullName,
              ),
              SizedBox(height: 12.h),

              // Email
              TextField(
                decoration: _inputDecoration("Email"),
                keyboardType: TextInputType.emailAddress,
                onChanged: provider.updateEmail,
              ),
              SizedBox(height: 12.h),

              // Password
              _PasswordField(
                onChanged: provider.updatePassword,
              ),
              SizedBox(height: 12.h),

              // Contact Number
              TextField(
                decoration: _inputDecoration("Contact Number (+91XXXXXXXXXX)"),
                keyboardType: TextInputType.phone,
                onChanged: provider.updateContactNumber,
              ),
              SizedBox(height: 12.h),

              // Age
              TextField(
                decoration: _inputDecoration("Age"),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null) provider.updateAge(n);
                },
              ),
              SizedBox(height: 12.h),

              // Gender
              _GenderPicker(
                selected: provider.gender,
                onChanged: provider.updateGender,
              ),
              SizedBox(height: 16.h),

              // Languages
              Text(
                "Languages you speak",
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: provider.availableLanguages.map((lang) {
                  final selected = provider.selectedLanguages.contains(lang);
                  return ChoiceChip(
                    label: Text(lang),
                    selected: selected,
                    onSelected: (_) => provider.toggleLanguage(lang),
                    selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                    labelStyle: GoogleFonts.raleway(
                      color: selected ? AppTheme.primaryColor : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 24.h),
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
                        final error = provider.validatePersonalInfo();
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                          return;
                        }
                        provider.nextStep();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        "Continue",
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
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.raleway(),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
    );
  }
}
class _GenderPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;
  const _GenderPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final genders = const ["Male", "Female", "Other"];
    return InputDecorator(
      decoration: InputDecoration(
        labelText: "Gender",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          items: genders
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _PasswordField({required this.onChanged});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: "Password",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      obscureText: _obscure,
      onChanged: widget.onChanged,
    );
  }
}
