part of 'ios_camera_notifier.dart';

class IOSCameraState extends BaseState {
  final bool permissionDenied;
  final int textureId;
  final double previewWidth;
  final double previewHeight;
  final int quarterTurns;

  const IOSCameraState({
    super.stateStatus,
    super.stateMessage,
    required this.permissionDenied,
    required this.textureId,
    required this.previewWidth,
    required this.previewHeight,
    required this.quarterTurns,
  });

  const IOSCameraState.initial()
    : permissionDenied = false,
      textureId = -1,
      previewWidth = 0,
      previewHeight = 0,
      quarterTurns = 0,
      super(stateStatus: StateStatus.loading);

  IOSCameraState copyWith({
    StateStatus? stateStatus,
    bool? permissionDenied,
    int? textureId,
    double? previewWidth,
    double? previewHeight,
    int? quarterTurns,
  }) {
    return IOSCameraState(
      stateStatus: stateStatus ?? this.stateStatus,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      textureId: textureId ?? this.textureId,
      previewWidth: previewWidth ?? this.previewWidth,
      previewHeight: previewHeight ?? this.previewHeight,
      quarterTurns: quarterTurns ?? this.quarterTurns,
    );
  }

  @override
  List<Object?> get props => [
    stateStatus,
    stateMessage,
    permissionDenied,
    textureId,
    previewWidth,
    previewHeight,
    quarterTurns,
  ];
}
