import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPermissionHandler {
  /// Requests gallery permission and returns true if granted, false otherwise.
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    // Request photos permission (gallery access)
    PermissionStatus status = await Permission.photos.request();

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // Show SnackBar for denied permission
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gallery access denied. Please allow permission to pick images.',
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16.w),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => requestGalleryPermission(context),
          ),
        ),
      );
      return false;
    } else if (status.isPermanentlyDenied) {
      // Show SnackBar for permanently denied permission
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gallery access permanently denied. Please enable it in settings.',
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16.w),
          action: SnackBarAction(
            label: 'Open Settings',
            textColor: Colors.white,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return false;
    }
    return false;
  }
}
