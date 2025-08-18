package com.platform.channel

import AndroidOrientationData
import android.content.Context
import android.graphics.ImageFormat
import android.hardware.camera2.CameraCharacteristics
import android.os.Build
import android.util.Size
import android.view.Surface
import android.view.WindowManager
import kotlin.collections.map

class CameraUtil {
    private val commonSizes =
        arrayOf(
            Size(1280, 720),
            Size(1920, 1080),
            Size(2560, 1440),
            Size(3840, 2160)
        )
    private var context: Context? = null
    private var cameraCharacteristics: CameraCharacteristics? = null
    var supportedSizes: List<Size> = mutableListOf()
    var supportedFps: List<Int> = mutableListOf()
    var frameSize: Size = Size(1280, 720)
    var frameRate: Int = 30

    /**
     * Updates camera details with the provided camera request
     */
    fun updateCameraDetails(
        context: Context,
        cameraCharacteristics: CameraCharacteristics,
        requestedFrameSize: Size,
        frameRate: Int,
    ) {
        this.context = context
        this.cameraCharacteristics = cameraCharacteristics
        this.frameRate = frameRate

        val map = cameraCharacteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
        val sizes = map?.getOutputSizes(ImageFormat.YUV_420_888) ?: emptyArray()
        supportedSizes = sizes.filter { commonSizes.contains(it) }.toList()
        if (supportedSizes.contains(requestedFrameSize)) {
            frameSize = requestedFrameSize
        }

        // Get supported frame rates up to 60 fps
        val fpsRanges =
            cameraCharacteristics.get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES)
        supportedFps = fpsRanges?.map { it.upper }?.filter { it <= 60 }?.distinct()?.sorted()
            ?: emptyList()
        // Get the last frame rate if the requested frame rate is not supported
        this.frameRate = if (supportedFps.contains(frameRate)) frameRate else supportedFps.last()
    }

    /**
     * Gets all rotation degree needs to be applied for correct image orientation
     */
    fun getOrientationData(): AndroidOrientationData {
        try {
            if (cameraCharacteristics == null || context == null) {
                throw RuntimeException("CAMERA_ERROR: Camera characteristics not initialized.")
            }

            // Get Lens facing type
            val lensFacing = cameraCharacteristics!!.get(CameraCharacteristics.LENS_FACING)
            val isFrontFacing = lensFacing == CameraCharacteristics.LENS_FACING_FRONT

            // Gets the current device orientation in DEGREES (clockwise from natural portrait).
            val windowManager = context!!.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val deviceRotation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                context!!.display.rotation
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay.rotation
            }
            val deviceRotationDegrees = when (deviceRotation) {
                Surface.ROTATION_0 -> 0
                Surface.ROTATION_90 -> 90
                Surface.ROTATION_180 -> 180
                Surface.ROTATION_270 -> 270
                else -> 0
            }

            // Converts clockwise rotation to counter-clockwise rotation in degrees.
            val displayRotationDegrees = when (deviceRotationDegrees) {
                0 -> 0
                90 -> 270 // Clockwise 90 degrees is Counter-Clockwise 270 degrees
                180 -> 180
                270 -> 90  // Clockwise 270 degrees is Counter-Clockwise 90 degrees
                else -> 0
            }

            // Get camera sensor orientation degrees
            val sensorOrientationDegrees =
                cameraCharacteristics!!.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 0

            // Get image rotation
            val sign = if (lensFacing == CameraCharacteristics.LENS_FACING_FRONT) 1 else -1
            val rotation = (sensorOrientationDegrees - displayRotationDegrees * sign + 360) % 360

            return AndroidOrientationData(
                sensorOrientationDegrees = sensorOrientationDegrees.toLong(),
                deviceOrientationDegrees = deviceRotationDegrees.toLong(),
                displayOrientationDegrees = displayRotationDegrees.toLong(),
                rotationDegrees = rotation.toLong()
            )
        } catch (_: Exception) {
            throw RuntimeException("CAMERA_ERROR: Failed to get image rotation.")
        }
    }

    /**
     * Gets the failure result dynamically.
     */
    fun <T> getFailureResult(message: String, error: Exception? = null): Result<T> {
        return Result.failure(RuntimeException(message, error))
    }

    /**
     * Removes camera device information like resolutions, frame rates.
     */
    fun clearCameraDetails() {
        context = null
        cameraCharacteristics = null
        supportedSizes = mutableListOf()
        supportedFps = mutableListOf()
        frameRate = 30
    }
}