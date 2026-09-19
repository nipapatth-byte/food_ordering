import 'package:flutter/material.dart';

// ตัวช่วยตัดสินใจ layout ตามความกว้างจอ
// ใช้แบบ: ResponsiveLayout(mobile: ..., tablet: ...)
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  static const double tabletBreakpoint = 700;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
  });

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= tabletBreakpoint) {
          return tablet;
        }
        return mobile;
      },
    );
  }
}
