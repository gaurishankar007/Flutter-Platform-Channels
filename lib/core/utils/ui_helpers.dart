import 'package:flutter/material.dart';

import 'screen_util/screen_util.dart';

enum Space {
  tiny(1),
  xxxSmall(2),
  xxSmall(4),
  xSmall(8),
  small(12),
  sMedium(16),
  medium(20),
  large(24),
  lMedium(28),
  xLarge(32),
  xlMedium(36),
  xxLarge(40),
  xxxLarge(48),
  massive(64);

  const Space(this.value);
  final double value;
}

class UIHelpers {
  UIHelpers._();

  /// Shows nothing in the UI
  static const nothing = SizedBox.shrink();

  /// Get Zero padding
  static const zeroPadding = EdgeInsets.zero;

  //<========== Horizontal Spacing ==========>
  /// Horizontal Space = 2
  static final xxxSmallHSpace = SizedBox(width: Space.xxxSmall.value);

  /// Horizontal Space = 4
  static final xxSmallHSpace = SizedBox(width: Space.xxSmall.value);

  /// Horizontal Space = 8
  static final xSmallHSpace = SizedBox(width: Space.xSmall.value);

  /// Horizontal Space = 12
  static final smallHSpace = SizedBox(width: Space.small.value);

  /// Horizontal Space = 20
  static final mediumHSpace = SizedBox(width: Space.medium.value);

  /// Horizontal Space = 24
  static final largeHSpace = SizedBox(width: Space.large.value);

  /// Horizontal Space = 28
  static final lMediumHSpace = SizedBox(width: Space.lMedium.value);

  /// Horizontal Space = 36
  static final xlMediumHSpace = SizedBox(width: Space.xlMedium.value);

  /// Horizontal Space = screen padding
  static final screenHSpace = SizedBox(width: ScreenUtil.I.horizontalSpace);

  //<========== Vertical Spacing ==========>
  /// Vertical Space = 2
  static final xxxSmallVSpace = SizedBox(height: Space.xxxSmall.value);

  /// Vertical Space = 4
  static final xxSmallVSpace = SizedBox(height: Space.xxSmall.value);

  /// Vertical Space = 8
  static final xSmallVSpace = SizedBox(height: Space.xSmall.value);

  /// Vertical Space = 12
  static final smallVSpace = SizedBox(height: Space.small.value);

  /// Vertical Space = 16
  static final sMediumVSpace = SizedBox(height: Space.sMedium.value);

  /// Vertical Space = 20
  static final mediumVSpace = SizedBox(height: Space.medium.value);

  /// Vertical Space = 24
  static final largeVSpace = SizedBox(height: Space.large.value);

  /// Vertical Space = 32
  static final xLargeVSpace = SizedBox(height: Space.xLarge.value);

  /// Vertical Space = 36
  static final xlMediumVSpace = SizedBox(height: Space.xlMedium.value);

  /// Vertical Space = 40
  static final xxLargeVSpace = SizedBox(height: Space.xxLarge.value);

  /// Vertical Space = 48
  static final xxxLargeVSpace = SizedBox(height: Space.xxxLarge.value);

  /// Vertical Space = 64
  static final massiveVSpace = SizedBox(height: Space.massive.value);

  /// Vertical Space = Screen vertical padding amount
  static final screenVerticalSpace = SizedBox(
    height: ScreenUtil.I.verticalSpace,
  );

  //<========== All Padding ==========>
  /// All Padding = 4
  static final xxSmallAllPadding = EdgeInsets.all(Space.xxSmall.value);

  /// All Padding = 8
  static final xSmallAllPadding = EdgeInsets.all(Space.xSmall.value);

  /// All Padding = 12
  static final smallAllPadding = EdgeInsets.all(Space.small.value);

  /// All Padding = 16
  static final sMediumAllPadding = EdgeInsets.all(Space.sMedium.value);

  /// All Padding = 24
  static final largeAllPadding = EdgeInsets.all(Space.large.value);

  /// All Padding = 32
  static final xLargeAllPadding = EdgeInsets.all(Space.xLarge.value);

  /// All Padding = 32
  static final xlMediumAllPadding = EdgeInsets.all(Space.xlMedium.value);

  /// All Padding = screen padding
  static final screenAllPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil.I.horizontalSpace,
    vertical: ScreenUtil.I.verticalSpace,
  );

  //<========== Horizontal Padding ==========>
  /// Horizontal Padding = 8
  static final xSmallHPadding = EdgeInsets.symmetric(
    horizontal: Space.xSmall.value,
  );

  /// Horizontal Padding = 12
  static final smallHPadding = EdgeInsets.symmetric(
    horizontal: Space.small.value,
  );

  /// Horizontal Padding = 24
  static final largeHPadding = EdgeInsets.symmetric(
    horizontal: Space.large.value,
  );

  /// Horizontal Padding = screen horizontal padding
  static final screenHPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil.I.horizontalSpace,
  );

  //<========== Vertical Padding ==========>
  /// Vertical Padding = 1
  static final tinyVPadding = EdgeInsets.symmetric(vertical: Space.tiny.value);

  /// Vertical Padding = 4
  static final xxSmallVPadding = EdgeInsets.symmetric(
    vertical: Space.xxSmall.value,
  );

  /// Vertical Padding = 12
  static final smallVPadding = EdgeInsets.symmetric(
    vertical: Space.small.value,
  );

  /// Vertical Padding = 16
  static final sMediumVPadding = EdgeInsets.symmetric(
    vertical: Space.sMedium.value,
  );

  /// Vertical Padding = 20
  static final mediumVPadding = EdgeInsets.symmetric(
    vertical: Space.medium.value,
  );

  /// Vertical Padding = 32
  static final xLargeVPadding = EdgeInsets.symmetric(
    vertical: Space.xLarge.value,
  );

  //<========== Symmetric Padding ==========>
  /// Symmetric Padding = 16 horizontal, 8 vertical
  static final sMediumHxSmallVPadding = EdgeInsets.symmetric(
    horizontal: Space.sMedium.value,
    vertical: Space.xSmall.value,
  );

  /// Symmetric Padding = 16 horizontal, 12 vertical
  static final sMediumHSmallVPadding = EdgeInsets.symmetric(
    horizontal: Space.sMedium.value,
    vertical: Space.small.value,
  );

  /// Symmetric Padding = 16 horizontal, 20 vertical
  static final sMediumHMediumVPadding = EdgeInsets.symmetric(
    horizontal: Space.sMedium.value,
    vertical: Space.medium.value,
  );

  /// Symmetric Padding = 20 horizontal, 12 vertical
  static final mediumHSmallVPadding = EdgeInsets.symmetric(
    horizontal: Space.medium.value,
    vertical: Space.small.value,
  );

  /// Symmetric Padding = 24 horizontal, 16 vertical
  static final largeHsMediumVPadding = EdgeInsets.symmetric(
    horizontal: Space.large.value,
    vertical: Space.sMedium.value,
  );

  /// Symmetric Padding = 24 horizontal, 20 vertical
  static final largeHMediumVPadding = EdgeInsets.symmetric(
    horizontal: Space.large.value,
    vertical: Space.medium.value,
  );

  /// Symmetric Padding = screen horizontal padding, 16 vertical
  static final screenHsMediumVPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil.I.horizontalSpace,
    vertical: Space.sMedium.value,
  );

  //<========== Left Padding ==========>
  /// Left Padding = screen horizontal padding
  static final screenLPadding = EdgeInsets.only(
    left: ScreenUtil.I.horizontalSpace,
  );

  //<========== Top Padding ==========>
  /// Top Padding = 12
  static final smallTPadding = EdgeInsets.only(top: Space.small.value);

  /// Top Padding = 24
  static final largeTPadding = EdgeInsets.only(top: Space.large.value);

  /// Top Padding = 32
  static final xLargeTPadding = EdgeInsets.only(top: Space.xLarge.value);

  //<========== Bottom Padding ==========>
  /// Top Padding = 12
  static final smallBPadding = EdgeInsets.only(bottom: Space.small.value);

  //<========== Right Padding ==========>
  /// Right Padding = screen horizontal Padding
  static final screenRPadding = EdgeInsets.only(
    right: ScreenUtil.I.horizontalSpace,
  );

  //<========== Top Bottom Padding ==========>
  /// Top Bottom Padding = 8 Top, 4 bottom
  static final xSmallTxxSmallBPadding = EdgeInsets.only(
    top: Space.xSmall.value,
    bottom: Space.xxSmall.value,
  );

  //<========== Only Padding ==========>
  /// Only padding = left, right = screen horizontal padding, top, bottom = 16
  static EdgeInsets screenLR({double? top, double? bottom}) => EdgeInsets.only(
    top: top ?? Space.sMedium.value,
    right: ScreenUtil.I.horizontalSpace,
    bottom: bottom ?? Space.sMedium.value,
    left: ScreenUtil.I.horizontalSpace,
  );

  //<========== Border Radius ==========>
  /// Border Radius = 2 Circular
  static final xxxSmallCRadius = BorderRadius.circular(Space.xxxSmall.value);

  /// Border Radius = 4 Circular
  static final xxSmallCRadius = BorderRadius.circular(Space.xxSmall.value);

  /// Border Radius = 8 Circular
  static final xSmallCRadius = BorderRadius.circular(Space.xSmall.value);

  /// Border Radius = 12 Circular
  static final smallCRadius = BorderRadius.circular(Space.small.value);

  /// Border Radius = 24 Circular
  static final largeCRadius = BorderRadius.circular(Space.large.value);

  /// Border Radius = 4 right
  static final xxSmallRRadius = BorderRadius.only(
    topRight: Radius.circular(Space.xxSmall.value),
    bottomRight: Radius.circular(Space.xxSmall.value),
  );

  /// Border Radius = 24 Top
  static final largeTRadius = BorderRadius.only(
    topLeft: Radius.circular(Space.large.value),
    topRight: Radius.circular(Space.large.value),
  );
}
