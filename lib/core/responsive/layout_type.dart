/// Layout breakpoints and a [LayoutType] classifier.
///
/// One source of truth used by the shell (nav bar vs nav rail) and by any
/// adaptive feature layout. Thresholds follow Material 3 window-size guidance.
enum LayoutType { phone, tablet, desktop }

class LayoutBreakpoints {
  const LayoutBreakpoints._();

  static const double tablet = 600;
  static const double desktop = 840;

  static LayoutType classify(double width) {
    if (width >= desktop) return LayoutType.desktop;
    if (width >= tablet) return LayoutType.tablet;
    return LayoutType.phone;
  }
}
