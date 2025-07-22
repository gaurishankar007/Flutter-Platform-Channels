part of 'web_camera_notifier.dart';

class WebCameraState extends BaseState {
  final bool permissionDenied;
  final String htmlElementType;

  const WebCameraState({
    super.stateStatus,
    super.stateMessage,
    required this.permissionDenied,
    required this.htmlElementType,
  });

  const WebCameraState.initial()
    : permissionDenied = false,
      htmlElementType = "",
      super(stateStatus: StateStatus.loading);

  WebCameraState copyWith({
    StateStatus? stateStatus,
    bool? permissionDenied,
    String? htmlElementType,
  }) {
    return WebCameraState(
      stateStatus: stateStatus ?? this.stateStatus,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      htmlElementType: htmlElementType ?? this.htmlElementType,
    );
  }

  @override
  List<Object?> get props => [
    stateStatus,
    stateMessage,
    permissionDenied,
    htmlElementType,
  ];
}
