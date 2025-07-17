import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show StateNotifier;

import '../service_mixin.dart';

part 'base_state.dart';

/// State Notifier along with handy services functionality
abstract class BaseStateNotifier<T> extends StateNotifier<T> with ServiceMixin {
  BaseStateNotifier(super.initialState);
}