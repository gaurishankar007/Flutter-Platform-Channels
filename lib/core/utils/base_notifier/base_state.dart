part of 'base_state_notifier.dart';

/// Base State for Notifiers.
/// Extend this for your feature states to inherit status handling.
abstract class BaseState extends Equatable {
  /// The current status of the state (e.g., loading, loaded, etc.).
  final StateStatus stateStatus;

  /// The message to be shown in the UI.
  /// This should be always null if the state is updating the UI only, not delivering message.
  final StateMessage? stateMessage;

  const BaseState({this.stateStatus = StateStatus.initial, this.stateMessage});

  @override
  List<Object?> get props => [stateStatus, stateMessage];
}

/// The status of a bloc/state when there is only a single state.
/// * [initial] - The initial state.
/// * [loading] - The state when loading is in progress.
/// * [loaded] - The state when loading is complete.
/// * [noInternet] - The state when there is no internet connection.
enum StateStatus { initial, loading, loaded, noInternet }

/// Represents a message to be shown in the UI.
/// Extend this for different message types (success, error, etc.).
sealed class StateMessage {
  /// The message text.
  final String text;
  const StateMessage(this.text);
}

/// Represents a success message to be shown in the UI.
class SuccessMessage extends StateMessage {
  const SuccessMessage(super.text);
}

/// Represents an error message to be shown in the UI.
class ErrorMessage extends StateMessage {
  const ErrorMessage(super.text);
}