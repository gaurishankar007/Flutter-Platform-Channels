// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:platform_channel/config/pigeon/generated/android_camera_api.dart'
    as _i602;
import 'package:platform_channel/config/pigeon/generated/ios_camera_api.dart'
    as _i156;
import 'package:platform_channel/core/services/android_camera_service.dart'
    as _i469;
import 'package:platform_channel/core/services/ios_camera_service.dart'
    as _i746;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt initialize({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final iOSCameraHostApiModule = _$IOSCameraHostApiModule();
    final androidCameraHostApiModule = _$AndroidCameraHostApiModule();
    gh.lazySingleton<_i156.IOSCameraHostApi>(
      () => iOSCameraHostApiModule.cameraHostApi,
    );
    gh.lazySingleton<_i602.AndroidCameraHostApi>(
      () => androidCameraHostApiModule.cameraHostApi,
    );
    gh.lazySingleton<_i746.IOSCameraService>(
      () => _i746.IOSCameraServiceImpl(
        cameraHostApi: gh<_i156.IOSCameraHostApi>(),
      ),
    );
    gh.lazySingleton<_i469.AndroidCameraService>(
      () => _i469.AndroidCameraServiceImpl(
        cameraHostApi: gh<_i602.AndroidCameraHostApi>(),
      ),
    );
    return this;
  }
}

class _$IOSCameraHostApiModule extends _i746.IOSCameraHostApiModule {}

class _$AndroidCameraHostApiModule extends _i469.AndroidCameraHostApiModule {}
