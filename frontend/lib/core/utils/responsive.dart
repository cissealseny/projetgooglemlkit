import 'package:flutter/material.dart';

/// Responsive breakpoints and utilities
class Responsive {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // Check device type
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  // Get device type as enum
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    if (width < desktopBreakpoint) return DeviceType.desktop;
    return DeviceType.largeDesktop;
  }

  // Responsive value based on device
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  // Responsive padding
  static EdgeInsets padding(BuildContext context) {
    return value(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  // Responsive grid columns
  static int gridColumns(BuildContext context) {
    return value(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      largeDesktop: 4,
    );
  }

  // Safe area padding
  static EdgeInsets safeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }

  // Keyboard visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  // Screen size
  static Size screenSize(BuildContext context) => MediaQuery.of(context).size;

  // Aspect ratio helpers
  static double aspectRatio(BuildContext context) {
    final size = screenSize(context);
    return size.width / size.height;
  }

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;
}

enum DeviceType { mobile, tablet, desktop, largeDesktop }

/// Responsive Builder Widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, Responsive.getDeviceType(context));
  }
}

/// Responsive Layout Widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Responsive.value(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
}

/// Responsive Grid
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.value(
      context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

/// Swipe Detector for Mobile Navigation
class SwipeDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final double threshold;

  const SwipeDetector({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.threshold = 50,
  });

  @override
  Widget build(BuildContext context) {
    Offset? startPosition;

    return GestureDetector(
      onPanStart: (details) {
        startPosition = details.globalPosition;
      },
      onPanEnd: (details) {
        if (startPosition == null) return;

        final dx = details.velocity.pixelsPerSecond.dx;
        final dy = details.velocity.pixelsPerSecond.dy;

        if (dx.abs() > dy.abs()) {
          // Horizontal swipe
          if (dx > threshold && onSwipeRight != null) {
            onSwipeRight!();
          } else if (dx < -threshold && onSwipeLeft != null) {
            onSwipeLeft!();
          }
        } else {
          // Vertical swipe
          if (dy > threshold && onSwipeDown != null) {
            onSwipeDown!();
          } else if (dy < -threshold && onSwipeUp != null) {
            onSwipeUp!();
          }
        }
      },
      child: child,
    );
  }
}

/// Adaptive Container that changes max width based on screen size
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Alignment alignment;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final double adaptiveMaxWidth;
    if (maxWidth != null) {
      adaptiveMaxWidth = maxWidth!;
    } else {
      final type = Responsive.getDeviceType(context);
      switch (type) {
        case DeviceType.mobile:
          adaptiveMaxWidth = double.infinity;
        case DeviceType.tablet:
          adaptiveMaxWidth = 720.0;
        case DeviceType.desktop:
          adaptiveMaxWidth = 960.0;
        case DeviceType.largeDesktop:
          adaptiveMaxWidth = 1200.0;
      }
    }

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: adaptiveMaxWidth),
        padding: padding ?? Responsive.padding(context),
        child: child,
      ),
    );
  }
}

/// Hide widget on specific device types
class HideOn extends StatelessWidget {
  final Widget child;
  final bool mobile;
  final bool tablet;
  final bool desktop;

  const HideOn({
    super.key,
    required this.child,
    this.mobile = false,
    this.tablet = false,
    this.desktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);

    if (mobile && deviceType == DeviceType.mobile)
      return const SizedBox.shrink();
    if (tablet && deviceType == DeviceType.tablet)
      return const SizedBox.shrink();
    if (desktop &&
        (deviceType == DeviceType.desktop ||
            deviceType == DeviceType.largeDesktop)) {
      return const SizedBox.shrink();
    }

    return child;
  }
}

/// Show widget only on specific device types
class ShowOn extends StatelessWidget {
  final Widget child;
  final bool mobile;
  final bool tablet;
  final bool desktop;

  const ShowOn({
    super.key,
    required this.child,
    this.mobile = false,
    this.tablet = false,
    this.desktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);

    if (mobile && deviceType == DeviceType.mobile) return child;
    if (tablet && deviceType == DeviceType.tablet) return child;
    if (desktop &&
        (deviceType == DeviceType.desktop ||
            deviceType == DeviceType.largeDesktop)) {
      return child;
    }

    return const SizedBox.shrink();
  }
}
