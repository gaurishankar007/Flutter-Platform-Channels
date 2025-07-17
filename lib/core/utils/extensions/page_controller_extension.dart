import 'package:flutter/material.dart';

extension PageControllerExtension on PageController {
  int? getCurrentPage() {
    if (hasClients) return page?.round() ?? 0;
    return null;
  }

  Future previous() async => await previousPage(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );

  Future next() async => await nextPage(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );

  Future moveToPage(int page) async => await animateToPage(
    page,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );
}
