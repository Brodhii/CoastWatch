import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class AdminResponsive {
  static const double mobileBreakpoint = 700;
  static const double desktopBreakpoint = 1024;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < desktopBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static bool isMobileWidth(double width) => width < mobileBreakpoint;
  static bool isTabletWidth(double width) =>
      width >= mobileBreakpoint && width < desktopBreakpoint;
  static bool isDesktopWidth(double width) => width >= desktopBreakpoint;

  static T value<T>(BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return mobile;
    if (width < desktopBreakpoint) return tablet ?? mobile;
    return desktop;
  }
}
