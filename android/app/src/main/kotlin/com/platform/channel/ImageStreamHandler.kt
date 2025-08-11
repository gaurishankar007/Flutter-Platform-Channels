package com.platform.channel

import AndroidCameraImageData
import AndroidImagePlaneData
import android.graphics.ImageFormat
import android.media.ImageReader
import android.os.Handler
import android.util.Log
import android.util.Size
import android.view.Surface
import java.nio.ByteBuffer

class ImageStreamHandler {
    private var imageReader: ImageReader? = null
    private var isImageStreaming: Boolean = false

    val isImageStreamActive: Boolean get() = isImageStreaming

    /**
     * The image reader's surface
     */
    val surface: Surface? get() = imageReader?.surface

    /**
     * Initializes the image reader for streaming images
     **/
    fun initialize(
        surfaceSize: Size,
        imageFormat: String = "YUV_420_888",
        maxImages: Int = 2
    ) {
        val imageFormats = mapOf(
            "YUV_420_888" to ImageFormat.YUV_420_888,
            "RGB_565" to ImageFormat.RGB_565,
            "JPEG" to ImageFormat.JPEG,
        )
        val format = imageFormats[imageFormat] ?: ImageFormat.YUV_420_888

        imageReader = ImageReader.newInstance(
            surfaceSize.width,
            surfaceSize.height,
            format,
            maxImages
        )
    }

    /**
     * Starts streaming images, and calls the provided callback when the image reader receives the image
     */
    fun startStream(
        frameSkipInterval: Int = 0,
        handler: Handler,
        onImageReceived: (AndroidCameraImageData) -> Unit
    ) {
        if (imageReader == null) {
            throw RuntimeException("IMAGE_READER_ERROR: Image reader not initialized yet.")
        } else if (isImageStreaming) {
            throw RuntimeException("IMAGE_READER_ERROR: Image streaming already started.")
        }

        var imageReaderFrameCounter = 0

        imageReader?.setOnImageAvailableListener({ reader ->
            val image = reader.acquireLatestImage()
            if (image != null) {
                imageReaderFrameCounter++
                // Send image data to Flutter every imageReaderFrameInterval frames
                if (imageReaderFrameCounter % frameSkipInterval == 0) {
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

                        val imageData = AndroidCameraImageData(
                            width = image.width.toLong(),
                            height = image.height.toLong(),
                            format = image.format.toLong(),
                            planes = planesData,
                            rotationDegrees = 0,
                        )

                        onImageReceived(imageData)
                    } catch (e: Exception) {
                        Log.d("ImageReader", "IMAGE_CONVERSION_ERROR: ${e.message}.")
                    }
                }
            }
            // images are always closed to free up buffers and prevent camera stalling
            image?.close()
        }, handler)

        isImageStreaming = true
    }

    /**
     * Stops streaming images and releases the image reader resources
     */
    fun stopStream() {
        try {
            if (isImageStreaming) {
                imageReader?.setOnImageAvailableListener(null, null)
                isImageStreaming = false
            }
        } catch (e: Exception) {
            throw RuntimeException("IMAGE_READER_ERROR: Failed to stop image stream.", e)
        }
    }

    /**
     * Releases the image reader resources
     */
    fun deinitialize() {
        try {
            stopStream()
            imageReader?.close()
            imageReader = null
        } catch (e: Exception) {
            Log.e(
                "IMAGE_READER_ERROR",
                "IMAGE_READER_ERROR: Failed to release image reader resources.",
                e
            )
        }
    }
}