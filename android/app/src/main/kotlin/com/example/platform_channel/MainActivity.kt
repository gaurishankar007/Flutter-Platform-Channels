package com.platform.channel

import AndroidAudioStreamRequest
import AndroidCameraData
import AndroidCameraFlutterApi
import AndroidCameraHostApi
import AndroidCameraImageData
import AndroidCameraRequest
import AndroidImagePlaneData
import AndroidImageStreamRequest
import AndroidOrientationData
import AndroidSize
import AndroidVideoRecordRequest
import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.hardware.camera2.*
import android.hardware.camera2.params.OutputConfiguration
import android.hardware.camera2.params.SessionConfiguration
import android.media.*
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.util.Range
import android.util.Size
import android.view.Surface
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.view.TextureRegistry
import java.nio.ByteBuffer
import java.util.concurrent.Executors

class MainActivity : FlutterActivity(), AndroidCameraHostApi {
    private lateinit var androidCameraFlutterApi: AndroidCameraFlutterApi
    private var cameraDevice: CameraDevice? = null
    private var cameraCharacteristics: CameraCharacteristics? = null
    private var cameraCaptureSession: CameraCaptureSession? = null

    private var handlerThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null

    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var previewSurface: Surface? = null
    private var imageReader: ImageReader? = null
    private var audioRecord: AudioRecord? = null
    private var audioRunnable: Runnable? = null
    private var mediaRecorder: MediaRecorder? = null

    private var supportedSizes: List<Size> = mutableListOf()
    private var supportedFps: List<Int> = mutableListOf()
    private var frameRate: Int = 30
    private var isImageStreaming: Boolean = false
    private var isVideoRecording: Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val binaryMessenger = flutterEngine.dartExecutor.binaryMessenger
        AndroidCameraHostApi.setUp(binaryMessenger, this)
        androidCameraFlutterApi = AndroidCameraFlutterApi(binaryMessenger)
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
            cameraCharacteristics = cameraManager.getCameraCharacteristics(cameraId)
            frameRate = request.cameraFrameRate.toInt()

            /// Update camera details
            updateCameraDetails()

            // Start a background thread for camera operations
            handlerThread = HandlerThread("CameraThread").apply { start() }
            backgroundHandler = Handler(handlerThread!!.looper)

            // Create a SurfaceTexture and update the preview surface size
            textureEntry = flutterEngine!!.renderer.createSurfaceTexture()
            val surfaceSize = getSupportedResolution(request.previewSize)
            val surfaceTexture = textureEntry!!.surfaceTexture()
            surfaceTexture.setDefaultBufferSize(
                surfaceSize.width,
                surfaceSize.height
            )
            previewSurface = Surface(surfaceTexture)

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
                                    frameRate = frameRate.toLong(),
                                    textureId = textureEntry!!.id(),
                                    previewSize = AndroidSize(
                                        surfaceSize.width.toDouble(),
                                        surfaceSize.height.toDouble()
                                    ),
                                    supportedSizes = supportedSizes.map {
                                        AndroidSize(it.width.toDouble(), it.height.toDouble())
                                    },
                                    supportedFps = supportedFps.map { it.toLong() }
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
            val orientationData = getOrientationData()
            callback(Result.success(orientationData))
        } catch (e: Exception) {
            callback(getFailureResult("ERROR: Failed to get orientation data.", e))
        }
    }

    override fun startImageStream(
        request: AndroidImageStreamRequest,
        callback: (Result<Unit>) -> Unit
    ) {
        if (isImageStreaming || imageReader != null) {
            callback(getFailureResult("IMAGE_READER_ERROR: Image streaming already started."))
            return
        }

        isImageStreaming = true
        var imageReaderFrameCounter = 0
        val supportedSize = getSupportedResolution(request.imageSize)
        imageReader = ImageReader.newInstance(
            supportedSize.width, supportedSize.height,
            ImageFormat.YUV_420_888, 2
        )

        // Configures the ImageReader to listen for new camera frames on a background thread.
        // When a frame is available and image streaming is active, it converts the frame data
        // (YUV_420_888) into [CameraImageData] and sends it to Flutter.
        // Acquired images are always closed to free up buffers and prevent camera stalling.
        imageReader?.setOnImageAvailableListener({ reader ->
            val image = reader.acquireLatestImage()
            if (image != null) {
                imageReaderFrameCounter++
                // Send image data to Flutter every imageReaderFrameInterval frames
                if (imageReaderFrameCounter % request.frameSkipInterval.toInt() == 0) {
                    try {
                        val planesData = mutableListOf<AndroidImagePlaneData>()
                        for (plane in image.planes) {
                            val buffer: ByteBuffer = plane.buffer
                            val bytes = ByteArray(buffer.remaining())
                            buffer.get(bytes)
                            planesData.add(
                                AndroidImagePlaneData(
                                    bytes = bytes,
                                    rowStride = plane.rowStride.toLong(),
                                    pixelStride = plane.pixelStride.toLong()
                                )
                            )
                        }

                        val rotationDegrees = getOrientationData().rotationDegrees
                        val imageData = AndroidCameraImageData(
                            width = image.width.toLong(),
                            height = image.height.toLong(),
                            format = image.format.toLong(),
                            planes = planesData,
                            rotationDegrees = rotationDegrees,
                        )

                        runOnUiThread {
                            androidCameraFlutterApi.onImageReceived(imageData) { }
                        }
                    } catch (e: Exception) {
                        Log.d("ImageReader", "IMAGE_CONVERSION_ERROR: ${e.message}.")
                    }
                }

            }

            image?.close()
        }, backgroundHandler)

        updateCaptureSession()
        callback(Result.success(Unit))
    }

    override fun stopImageStream(callback: (Result<Unit>) -> Unit) {
        try {
            if (!isImageStreaming || imageReader == null) {
                callback(Result.success(Unit))
                return
            }

            stopImageReader()
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
            if (audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                callback(getFailureResult("AUDIO_RECORD_ERROR: Audio streaming already started."))
                return
            }

            // Check for permission
            val recordAudioPermission = checkSelfPermission(Manifest.permission.RECORD_AUDIO)
            if (recordAudioPermission != PackageManager.PERMISSION_GRANTED) {
                callback(getFailureResult("Camera permission not granted."))
                return
            }

            // Setup audio record
            val sampleRate = request.sampleRate.toInt()
            val channelConfig = AudioFormat.CHANNEL_IN_MONO
            val format = AudioFormat.ENCODING_PCM_16BIT
            val minBufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, format)
            val readBufferSize = request.bufferSizeKB.toInt() * 1024 // Bytes
            val bufferSize = maxOf(minBufferSize * 2, readBufferSize)
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                channelConfig,
                format,
                bufferSize
            )
            // Start recording audio
            audioRecord?.startRecording()

            // Define the Runnable that will read and send audio data
            audioRunnable = object : Runnable {
                override fun run() {
                    if (audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                        val audioBuffer = ByteArray(bufferSize)
                        val bytesRead = audioRecord!!.read(audioBuffer, 0, bufferSize)
                        if (bytesRead > 0) {
                            val audioBytesToSend = audioBuffer.copyOf(bytesRead)
                            runOnUiThread {
                                androidCameraFlutterApi.onAudioReceived(audioBytesToSend) {}
                            }
                        }
                        // Reschedule the runnable to run again
                        backgroundHandler?.post(this)
                    }
                }
            }
            // Start the repeating task
            backgroundHandler?.post(audioRunnable!!)

            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(getFailureResult("AUDIO_RECORD_ERROR: Failed to start audio stream.", e))
        }
    }

    override fun stopAudioStream(callback: (Result<Unit>) -> Unit) {
        try {
            if (audioRecord == null) {
                callback(Result.success(Unit))
                return
            }

            stopAudioRecord()
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
            if (isVideoRecording || mediaRecorder != null) {
                callback(getFailureResult("MEDIA_RECORDER_ERROR: Recording already started."))
                return
            }

            // Set up media recorder
            isVideoRecording = true
            val videoSize = getSupportedResolution(request.resolution)
            val orientationData = getOrientationData()

            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }

            backgroundHandler?.post {
                mediaRecorder?.apply {
                    setAudioSource(MediaRecorder.AudioSource.CAMCORDER)
                    setVideoSource(MediaRecorder.VideoSource.SURFACE)
                    setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                    setOutputFile(request.filePath)

                    // Video settings
                    setVideoEncoder(MediaRecorder.VideoEncoder.H264)
                    setVideoEncodingBitRate(request.encodingBitRate.toInt())
                    setVideoFrameRate(frameRate)
                    setVideoSize(videoSize.width, videoSize.height)
                    setOrientationHint(orientationData.rotationDegrees.toInt())

                    // Audio settings for potentially better quality
                    setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                    setAudioChannels(request.audioChannels.toInt())
                    setAudioSamplingRate(request.audioSampleRate.toInt())
                    setAudioEncodingBitRate(request.audioEncodingBitRate.toInt())

                    prepare()
                }

                updateCaptureSession()
                mediaRecorder?.start()

                runOnUiThread {
                    callback(Result.success(Unit))
                }
            }
        } catch (e: Exception) {
            callback(getFailureResult("MEDIA_RECORD_ERROR: Failed to start media recorder.", e))
        }
    }

    override fun stopVideoRecording(callback: (Result<Unit>) -> Unit) {
        try {
            if (!isVideoRecording || mediaRecorder == null) {
                callback(Result.success(Unit))
                return
            }

            backgroundHandler?.post {
                stopMediaRecorder()
                runOnUiThread {
                    callback(Result.success(Unit))
                }
            }
        } catch (e: Exception) {
            callback(getFailureResult("MEDIA_RECORD_ERROR: Failed to stop media recorder.", e))
        }
    }

    override fun closeCamera(callback: (Result<Unit>) -> Unit) {
        try {
            cameraCharacteristics = null

            removeCaptureSession()

            stopCameraPreview()

            stopImageReader(false)

            stopMediaRecorder(false)

            stopAudioRecord()

            cameraDevice?.close()
            cameraDevice = null

            handlerThread?.quitSafely()
            handlerThread = null
            backgroundHandler = null

            supportedSizes = emptyList()
            supportedFps = emptyList()
            frameRate = 30

            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(getFailureResult("DISPOSE_ERROR: Failed to dispose camera", e))
        }
    }

    /**
     * Updates camera details with the provided camera request
     */
    private fun updateCameraDetails() {
        // Common sizes
        val commonSizes =
            arrayOf(
                Size(1280, 720),
                Size(1920, 1080),
                Size(2560, 1440),
                Size(3840, 2160)
            )
        val map = cameraCharacteristics?.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
        val sizes = map?.getOutputSizes(ImageFormat.YUV_420_888) ?: emptyArray()
        supportedSizes = sizes.filter { commonSizes.contains(it) }.toList()

        // Get supported frame rates up to 60 fps
        val fpsRanges =
            cameraCharacteristics?.get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES)
        supportedFps = fpsRanges?.map { it.upper }?.filter { it <= 60 }?.distinct()?.sorted()
            ?: emptyList()
        // Get the last frame rate if the requested frame rate is not supported
        if (!supportedFps.contains(frameRate)) {
            frameRate = supportedFps.last()
        }
    }

    /**
     * Returns the supported resolution based on the provided resolution and format
     */
    private fun getSupportedResolution(size: AndroidSize): Size {
        val requestedSize = Size(size.width.toInt(), size.height.toInt())
        val isSupported = supportedSizes.contains(requestedSize)
        return if (isSupported) requestedSize else Size(1280, 720)
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
            previewSurface?.let { surfaces.add(it) }
            if (isImageStreaming && imageReader != null) {
                surfaces.add(imageReader!!.surface)
            }
            if (isVideoRecording && mediaRecorder != null) {
                surfaces.add(mediaRecorder!!.surface)
            }

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
                    backgroundHandler,
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
            val captureRequestBuilder =
                cameraDevice!!.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)

            // Add active surfaces
            previewSurface?.let { captureRequestBuilder.addTarget(it) }
            if (isImageStreaming && imageReader != null) {
                captureRequestBuilder.addTarget(imageReader!!.surface)
            }
            if (isVideoRecording && mediaRecorder != null) {
                captureRequestBuilder.addTarget(mediaRecorder!!.surface)
            }

            // Capture request settings
            captureRequestBuilder.set(
                CaptureRequest.CONTROL_AE_MODE,
                CaptureRequest.CONTROL_AE_MODE_ON
            )
            captureRequestBuilder.set(
                CaptureRequest.CONTROL_AWB_MODE,
                CaptureRequest.CONTROL_AWB_MODE_AUTO
            )
            captureRequestBuilder.set(
                CaptureRequest.CONTROL_MODE,
                CaptureRequest.CONTROL_MODE_AUTO
            )
            captureRequestBuilder.set(
                CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE,
                Range(frameRate, frameRate)
            )

            val captureRequest = captureRequestBuilder.build()
            cameraCaptureSession?.setRepeatingRequest(captureRequest, null, backgroundHandler)
        } catch (e: Exception) {
            Log.d("Camera Capture", "CAPTURE_REQUEST_ERROR: ${e.message}.")
        }
    }

    /**
     * Gets all rotation degree needs to be applied for correct image orientation
     */
    private fun getOrientationData(): AndroidOrientationData {
        try {

            // Get Lens facing type
            val lensFacing = cameraCharacteristics?.get(CameraCharacteristics.LENS_FACING)
            val isFrontFacing = lensFacing == CameraCharacteristics.LENS_FACING_FRONT

            // Gets the current device orientation in DEGREES (clockwise from natural portrait).
            val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val deviceRotation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                context.display.rotation
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
                cameraCharacteristics?.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 0

            // Get image rotation
            val sign = if (lensFacing == CameraCharacteristics.LENS_FACING_FRONT) 1 else -1
            val rotation = (sensorOrientationDegrees - displayRotationDegrees * sign + 360) % 360

            return AndroidOrientationData(
                isFrontCamera = isFrontFacing,
                sensorOrientationDegrees = sensorOrientationDegrees.toLong(),
                deviceOrientationDegrees = deviceRotationDegrees.toLong(),
                displayOrientationDegrees = displayRotationDegrees.toLong(),
                rotationDegrees = rotation.toLong()
            )
        } catch (e: Exception) {
            throw RuntimeException("CAMERA_ERROR: Failed to get image rotation.")
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

    /**
     * Stops the camera preview and releases texture entry resources
     */
    private fun stopCameraPreview() {
        textureEntry?.release()
        textureEntry = null
        previewSurface = null
    }

    /**
     * Stops the image reader and releases it's resources
     */
    private fun stopImageReader(shouldUpdateCameraSession: Boolean = true) {
        if (!isImageStreaming) return

        isImageStreaming = false
        if (shouldUpdateCameraSession) {
            updateCaptureSession()
        }
        imageReader?.setOnImageAvailableListener(null, null)
        imageReader?.close()
        imageReader = null
    }

    /**
     * Stops the audio record and releases it's resources
     */
    private fun stopAudioRecord() {
        if (audioRunnable != null) {
            backgroundHandler?.removeCallbacks(audioRunnable!!)
            audioRunnable = null
        }
        if (audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
            audioRecord?.stop()
        }
        audioRecord?.release()
        audioRecord = null
    }

    /**
     * Stops the media recorder and releases it's resources
     */
    private fun stopMediaRecorder(shouldUpdateCameraSession: Boolean = true) {
        if (!isVideoRecording) return

        isVideoRecording = false
        if (shouldUpdateCameraSession) {
            updateCaptureSession()
        }
        mediaRecorder?.stop()
        mediaRecorder?.reset()
        mediaRecorder?.release()
        mediaRecorder = null
    }

    private fun <T> getFailureResult(message: String, error: Exception? = null): Result<T> {
        return Result.failure(RuntimeException(message, error))
    }
}