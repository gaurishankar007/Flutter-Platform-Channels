package com.platform.channel

import AndroidAudioStreamRequest
import AndroidCameraData
import AndroidCameraFlutterApi
import AndroidCameraHostApi
import AndroidCameraRequest
import AndroidImageStreamRequest
import AndroidOrientationData
import AndroidSize
import AndroidVideoRecordRequest
import android.Manifest
import android.content.pm.PackageManager
import android.hardware.camera2.*
import android.hardware.camera2.params.OutputConfiguration
import android.hardware.camera2.params.SessionConfiguration
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.util.Range
import android.util.Size
import android.view.Surface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.view.TextureRegistry
import java.util.concurrent.Executors

class MainActivity : FlutterActivity(), AndroidCameraHostApi {
    private lateinit var androidCameraFlutterApi: AndroidCameraFlutterApi
    private lateinit var cameraUtil: CameraUtil
    private lateinit var imageStreamHandler: ImageStreamHandler
    private lateinit var audioStreamHandler: AudioStreamHandler
    private lateinit var videoRecordHandler: VideoRecordHandler
    private var cameraDevice: CameraDevice? = null
    private var cameraCaptureSession: CameraCaptureSession? = null
    private var handlerThread: HandlerThread? = null
    private var handler: Handler? = null

    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val binaryMessenger = flutterEngine.dartExecutor.binaryMessenger
        AndroidCameraHostApi.setUp(binaryMessenger, this)
        androidCameraFlutterApi = AndroidCameraFlutterApi(binaryMessenger)

        cameraUtil = CameraUtil()
        imageStreamHandler = ImageStreamHandler()
        audioStreamHandler = AudioStreamHandler()
        videoRecordHandler = VideoRecordHandler()
    }

    override fun openCamera(
        request: AndroidCameraRequest,
        callback: (Result<AndroidCameraData>) -> Unit
    ) {
        try {
            val cameraPermission = checkSelfPermission(Manifest.permission.CAMERA)
            if (cameraPermission != PackageManager.PERMISSION_GRANTED) {
                callback(Result.failure(RuntimeException("Camera permission not granted.")))
                return
            }

            // Gets the camera based on the provided index
            val cameraManager = getSystemService(CAMERA_SERVICE) as CameraManager
            val cameraId = cameraManager.cameraIdList[request.cameraIndex.toInt()]
            val cameraCharacteristics = cameraManager.getCameraCharacteristics(cameraId)

            /// Update camera details
            val videoSize = Size(request.videoSize.width.toInt(), request.videoSize.height.toInt())
            cameraUtil.updateCameraDetails(
                context,
                cameraCharacteristics,
                videoSize,
                request.videoFrameRate.toInt()
            )

            // Create a surface texture for previewing camera frames
            textureEntry = flutterEngine!!.renderer.createSurfaceTexture()
            textureEntry!!.surfaceTexture().setDefaultBufferSize(
                cameraUtil.frameSize.width,
                cameraUtil.frameSize.height
            )
            // Initialize surfaces for detecting pose with media pipe, streaming image with image reader
            imageStreamHandler.initialize(cameraUtil.frameSize, request.imageStreamFormat)

            // Start a background thread for camera operations
            handlerThread = HandlerThread("CameraThread").apply { start() }
            handler = Handler(handlerThread!!.looper)

            // Opens the camera asynchronously
            cameraManager.openCamera(
                cameraId,
                object : CameraDevice.StateCallback() {
                    override fun onOpened(device: CameraDevice) {
                        cameraDevice = device

                        // Capture camera sessions once the camera is available
                        updateCaptureSession()

                        // Return the camera data to Flutter
                        callback.invoke(
                            Result.success(
                                AndroidCameraData(
                                    textureId = textureEntry!!.id(),
                                    videoSize = AndroidSize(
                                        cameraUtil.frameSize.width.toDouble(),
                                        cameraUtil.frameSize.height.toDouble()
                                    ),
                                    videoFrameRate = cameraUtil.frameRate.toLong(),
                                    supportedSizes = cameraUtil.supportedSizes.map {
                                        AndroidSize(it.width.toDouble(), it.height.toDouble())
                                    },
                                    supportedFps = cameraUtil.supportedFps.map { it.toLong() }
                                )
                            )
                        )
                    }

                    override fun onDisconnected(device: CameraDevice) {
                        Log.d("Camera", "CAMERA_DISCONNECTED: Camera was disconnected.")
                    }

                    override fun onError(device: CameraDevice, error: Int) {
                        Log.d("Camera", "CAMERA_ERROR: Camera error code: $error.")
                    }
                },
                null
            )
        } catch (e: Exception) {
            callback(getFailureResult("CAMERA_ERROR: Failed to configure camera.", e))
        }
    }

    override fun getOrientationData(callback: (Result<AndroidOrientationData>) -> Unit) {
        try {
            val orientationData = cameraUtil.getOrientationData()
            callback(Result.success(orientationData))
        } catch (e: Exception) {
            callback(getFailureResult("ERROR: Failed to get orientation data.", e))
        }
    }

    override fun startImageStream(
        request: AndroidImageStreamRequest,
        callback: (Result<Unit>) -> Unit
    ) {
        try {
            imageStreamHandler.startStream(
                request.frameSkipInterval.toInt(),
                handler!!,
            ) { imageData ->
                runOnUiThread {
                    androidCameraFlutterApi.onImageReceived(imageData) {}
                }
            }
            updateCaptureRequest()

            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(getFailureResult("IMAGE_READER_ERROR: Failed to start image stream.", e))
        }
    }

    override fun stopImageStream(callback: (Result<Unit>) -> Unit) {
        try {
            imageStreamHandler.stopStream()
            updateCaptureRequest()

            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(getFailureResult("IMAGE_READER_ERROR: Failed to stop image stream.", e))
        }
    }

    override fun startAudioStream(
        request: AndroidAudioStreamRequest,
        callback: (Result<Unit>) -> Unit
    ) {
        try {
            // Check for permission
            val recordAudioPermission = checkSelfPermission(Manifest.permission.RECORD_AUDIO)
            if (recordAudioPermission != PackageManager.PERMISSION_GRANTED) {
                callback(getFailureResult("Camera permission not granted."))
                return
            }

            audioStreamHandler.startStream(
                request,
                handler!!
            ) { audioData ->
                runOnUiThread {
                    androidCameraFlutterApi.onAudioReceived(audioData) {}
                }
            }

            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(getFailureResult("AUDIO_RECORD_ERROR: Failed to start audio stream.", e))
        }
    }

    override fun stopAudioStream(callback: (Result<Unit>) -> Unit) {
        try {
            audioStreamHandler.stopStream(handler!!)
            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(getFailureResult("AUDIO_RECORD_ERROR: Failed to stop audio stream.", e))
        }
    }

    override fun startVideoRecording(
        request: AndroidVideoRecordRequest,
        callback: (Result<Unit>) -> Unit
    ) {
        try {
            handler?.post {
                val rotationDegrees = cameraUtil.getOrientationData().rotationDegrees.toInt()
                videoRecordHandler.prepareMediaRecorder(
                    context,
                    cameraUtil.frameSize,
                    cameraUtil.frameRate,
                    rotationDegrees,
                    request
                )
                videoRecordHandler.startVideoRecording()

                runOnUiThread {
                    updateCaptureSession()
                    callback(Result.success(Unit))
                }
            }
        } catch (e: Exception) {
            callback(getFailureResult("MEDIA_RECORD_ERROR: Failed to start media recorder.", e))
        }
    }

    override fun stopVideoRecording(callback: (Result<Unit>) -> Unit) {
        try {
            handler?.post {
                videoRecordHandler.stopVideoRecording()

                runOnUiThread {
                    updateCaptureSession()
                    callback(Result.success(Unit))
                }
            }
        } catch (e: Exception) {
            callback(getFailureResult("MEDIA_RECORD_ERROR: Failed to stop media recorder.", e))
        }
    }

    override fun closeCamera(callback: (Result<Unit>) -> Unit) {
        try {
            removeCaptureSession()

            textureEntry?.release()
            textureEntry = null

            imageStreamHandler.deinitialize()
            audioStreamHandler.stopStream(handler!!)
            videoRecordHandler.stopVideoRecording()

            cameraDevice?.close()
            cameraDevice = null

            handlerThread?.quitSafely()
            handlerThread = null
            handler = null

            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(getFailureResult("DISPOSE_ERROR: Failed to dispose camera", e))
        }
    }

    /**
     * Removes the old capture session, re-creates a new capture session with the active surfaces
     */
    private fun updateCaptureSession() {
        try {
            removeCaptureSession()

            // Callback for new camera session state
            val stateCallback = object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    cameraCaptureSession = session
                    // Capture request once the session is configured
                    updateCaptureRequest()
                }

                override fun onConfigureFailed(session: CameraCaptureSession) {
                    Log.d("Camera Session", "SESSION_ERROR: Failed to configure session.")
                }
            }

            // Collect active surfaces
            val surfaces = mutableListOf<Surface>()
            textureEntry?.let { surfaces.add(Surface(it.surfaceTexture())) }
            imageStreamHandler.surface?.let { surfaces.add(it) }
            videoRecordHandler.surface?.let { surfaces.add(it) }

            // Create the camera capture session
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                cameraDevice!!.createCaptureSession(
                    SessionConfiguration(
                        SessionConfiguration.SESSION_REGULAR,
                        surfaces.map { OutputConfiguration(it) },
                        Executors.newSingleThreadExecutor(),
                        stateCallback
                    )
                )
            } else {
                @Suppress("DEPRECATION")
                cameraDevice!!.createCaptureSession(
                    surfaces,
                    stateCallback,
                    handler,
                )
            }
        } catch (e: Exception) {
            Log.d("Camera Session", "SESSION_ERROR: ${e.message}.")
        }
    }

    /**
     * Creates a new session capture request and adds the active surface as target
     * Also adds other camera settings if they are provided
     */
    private fun updateCaptureRequest() {
        try {
            val requestBuilder =
                cameraDevice!!.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)

            // Add active surfaces
            textureEntry?.let { requestBuilder.addTarget(Surface(it.surfaceTexture())) }
            if (imageStreamHandler.isImageStreamActive) {
                imageStreamHandler.surface?.let { requestBuilder.addTarget(it) }
            }
            videoRecordHandler.surface?.let { requestBuilder.addTarget(it) }

            // Capture request settings
            requestBuilder.set(
                CaptureRequest.CONTROL_AE_MODE,
                CaptureRequest.CONTROL_AE_MODE_ON
            )
            requestBuilder.set(
                CaptureRequest.CONTROL_AWB_MODE,
                CaptureRequest.CONTROL_AWB_MODE_AUTO
            )
            requestBuilder.set(
                CaptureRequest.CONTROL_MODE,
                CaptureRequest.CONTROL_MODE_AUTO
            )
            requestBuilder.set(
                CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE,
                Range(cameraUtil.frameRate, cameraUtil.frameRate)
            )

            val captureRequest = requestBuilder.build()
            cameraCaptureSession?.setRepeatingRequest(captureRequest, null, handler)
        } catch (e: Exception) {
            Log.d("Camera Capture", "CAPTURE_REQUEST_ERROR: ${e.message}.")
        }
    }

    /**
     * Removes the camera capture session and releases it's resources
     */
    private fun removeCaptureSession() {
        cameraCaptureSession?.stopRepeating()
        cameraCaptureSession?.abortCaptures()
        cameraCaptureSession?.close()
        cameraCaptureSession = null
    }

    private fun <T> getFailureResult(message: String, error: Exception? = null): Result<T> {
        return Result.failure(RuntimeException(message, error))
    }
}