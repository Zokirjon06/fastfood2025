import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
/// Replaces ScreenUtil with MediaQuery-based responsive calculations
class ResponsiveUtils {
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 1024;

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < _mobileBreakpoint;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= _mobileBreakpoint && width < _tabletBreakpoint;
  }

  /// Check if the device is a desktop
  static bool isDesktop(BuildContext context) {
    final width = screenWidth(context);
    return width >= _tabletBreakpoint;
  }
  // static bool isDesktop(BuildContext context) {
  //   return screenWidth(context) >= _tabletBreakpoint;
  // }

  /// Get responsive width based on percentage of screen width
  static double width(BuildContext context, double percentage) {
    return screenWidth(context) * (percentage / 100);
  }

  /// Get responsive height based on percentage of screen height
  static double height(BuildContext context, double percentage) {
    return screenHeight(context) * (percentage / 100);
  }

  /// Get responsive font size based on screen width
  static double fontSize(BuildContext context, double baseSize) {
    final width = screenWidth(context);
    if (width < _mobileBreakpoint) {
      return baseSize * 0.9; // 90% for mobile
    } else if (width < _tabletBreakpoint) {
      return baseSize * 1.0; // 100% for tablet
    } else {
      return baseSize * 1.1; // 110% for desktop
    }
  }

  /// Get responsive padding/margin
  static double spacing(BuildContext context, double baseSpacing) {
    final width = screenWidth(context);
    if (width < _mobileBreakpoint) {
      return baseSpacing * 0.8; // 80% for mobile
    } else if (width < _tabletBreakpoint) {
      return baseSpacing * 1.0; // 100% for tablet
    } else {
      return baseSpacing * 1.2; // 120% for desktop
    }
  }

  /// Get responsive border radius
  static double borderRadius(BuildContext context, double baseRadius) {
    final width = screenWidth(context);
    if (width < _mobileBreakpoint) {
      return baseRadius * 0.8; // 80% for mobile
    } else if (width < _tabletBreakpoint) {
      return baseRadius * 1.0; // 100% for tablet
    } else {
      return baseRadius * 1.2; // 120% for desktop
    }
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context, double baseSize) {
    final width = screenWidth(context);
    if (width < _mobileBreakpoint) {
      return baseSize * 0.9; // 90% for mobile
    } else if (width < _tabletBreakpoint) {
      return baseSize * 1.0; // 100% for tablet
    } else {
      return baseSize * 1.1; // 110% for desktop
    }
  }

  /// Get grid cross axis count based on screen width
  static int getGridCrossAxisCount(BuildContext context) {
    final width = screenWidth(context);

    if (width >= _tabletBreakpoint) {
      // Desktop: 5 or more columns
      return (width / 250).floor().clamp(5, 8);
    } else if (width >= _mobileBreakpoint) {
      // Tablet: 3-4 columns
      return 4;
    } else {
      // Mobile: 2 columns
      return 2;
    }
  }

  /// Get responsive card height for product cards
  static double getCardHeight(BuildContext context) {
    final width = screenWidth(context);
    if (width < _mobileBreakpoint) {
      return 200; // Mobile card height
    } else if (width < _tabletBreakpoint) {
      return 220; // Tablet card height
    } else {
      return 240; // Desktop card height
    }
  }

  /// Get responsive image height for product images
  static double getImageHeight(BuildContext context) {
    final width = screenWidth(context);
    if (width < _mobileBreakpoint) {
      return 120; // Mobile image height
    } else if (width < _tabletBreakpoint) {
      return 130; // Tablet image height
    } else {
      return 140; // Desktop image height
    }
  }

  /// Calculate estimated scroll position for lazy loading
  static double calculateScrollThreshold(BuildContext context, int itemCount) {
    final cardHeight = getCardHeight(context);
    final crossAxisCount = getGridCrossAxisCount(context);
    final rowCount = (itemCount / crossAxisCount).ceil();
    final totalHeight = rowCount * (cardHeight + 16); // Card height + spacing
    return totalHeight * 0.8; // 80% threshold
  }

  /// Get optimal cache size based on screen size
  static int getOptimalCacheSize(BuildContext context) {
    final width = screenWidth(context);
    if (width >= _tabletBreakpoint) {
      return 150; // Desktop/Tablet can handle more cached items
    } else {
      return 60; // Mobile conservative cache
    }
  }

  /// Get preload threshold based on device type
  static int getPreloadThreshold(BuildContext context) {
    final width = screenWidth(context);
    if (width >= _tabletBreakpoint) {
      return 8; // Desktop/Tablet preload more items
    } else {
      return 4; // Mobile conservative preload
    }
  }

  /// Get batch size for lazy loading based on device type
  static int getBatchSize(BuildContext context) {
    final width = screenWidth(context);
    if (width >= _tabletBreakpoint) {
      return 30; // Desktop/Tablet load more items per batch
    } else {
      return 20; // Mobile load fewer items per batch
    }
  }
}

/// Extension on BuildContext for easier access to responsive utilities
extension ResponsiveExtension on BuildContext {
  /// Get responsive width
  double rWidth(double percentage) => ResponsiveUtils.width(this, percentage);

  /// Get responsive height
  double rHeight(double percentage) => ResponsiveUtils.height(this, percentage);

  /// Get responsive font size
  double rFontSize(double baseSize) => ResponsiveUtils.fontSize(this, baseSize);

  /// Get responsive spacing
  double rSpacing(double baseSpacing) =>
      ResponsiveUtils.spacing(this, baseSpacing);

  /// Get responsive border radius
  double rBorderRadius(double baseRadius) =>
      ResponsiveUtils.borderRadius(this, baseRadius);

  /// Get responsive icon size
  double rIconSize(double baseSize) => ResponsiveUtils.iconSize(this, baseSize);

  /// Check if mobile
  bool get isMobile => ResponsiveUtils.isMobile(this);

  /// Check if tablet
  bool get isTablet => ResponsiveUtils.isTablet(this);

  /// Check if desktop
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  /// Get screen width
  double get screenWidth => ResponsiveUtils.screenWidth(this);

  /// Get screen height
  double get screenHeight => ResponsiveUtils.screenHeight(this);
}
