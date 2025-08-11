package com.platform.channel

import AndroidVideoRecordRequest
import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import android.util.Size
import android.view.Surface

class VideoRecordHandler {
    private var mediaRecorder: MediaRecorder? = null
    private var isMediaPrepared: Boolean = false
    private var isVideoRecording: Boolean = false

    /**
     * The media recorder's surface
     */
    val surface: Surface? get() = if (isMediaPrepared) mediaRecorder?.surface else null

    /**
     * Initializes the media player, and prepares the media recorder resources for video recording
     */
    fun prepareMediaRecorder(
        context: Context,
        videoSize: Size,
        videoFrameRate: Int,
        rotationDegrees: Int,
        request: AndroidVideoRecordRequest
    ) {
        try {
            if (isMediaPrepared) {
                throw RuntimeException("MEDIA_RECORD_ERROR: Media recorder is already prepared.")
            }

            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(context)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }

            mediaRecorder?.setAudioSource(MediaRecorder.AudioSource.CAMCORDER)
            mediaRecorder?.setVideoSource(MediaRecorder.VideoSource.SURFACE)
            mediaRecorder?.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            mediaRecorder?.setOutputFile(request.filePath)

            // Video settings
            mediaRecorder?.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
            mediaRecorder?.setVideoEncodingBitRate(request.encodingBitRate.toInt())
            mediaRecorder?.setVideoFrameRate(videoFrameRate)
            mediaRecorder?.setVideoSize(videoSize.width, videoSize.height)
            mediaRecorder?.setOrientationHint(rotationDegrees)

            // Audio settings
            mediaRecorder?.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            mediaRecorder?.setAudioChannels(request.audioChannels.toInt())
            mediaRecorder?.setAudioSamplingRate(request.audioSampleRate.toInt())
            mediaRecorder?.setAudioEncodingBitRate(request.audioEncodingBitRate.toInt())

            // Prepare the media recorder
            mediaRecorder?.prepare()

            isMediaPrepared = true
        } catch (e: Exception) {
            throw RuntimeException("MEDIA_RECORD_ERROR: Failed to prepare media recorder.", e)
        }
    }

    fun startVideoRecording() {
        try {
            if (mediaRecorder == null) {
                throw RuntimeException("MEDIA_RECORDER_ERROR: Media recorder not initialized yet.")
            } else if (!isMediaPrepared) {
                throw RuntimeException("MEDIA_RECORDER_ERROR: Media recorder not prepared yet.")
            } else if (isVideoRecording) {
                throw RuntimeException("MEDIA_RECORDER_ERROR: Video recording already started.")
            }

            mediaRecorder?.start()
            isVideoRecording = true
        } catch (e: Exception) {
            throw RuntimeException("MEDIA_RECORD_ERROR: Failed to start media recorder.", e)
        }
    }

    fun stopVideoRecording() {
        try {
            if (isVideoRecording) {
                mediaRecorder?.stop()
                mediaRecorder?.reset()
                mediaRecorder?.release()
                mediaRecorder = null
                isMediaPrepared = false
                isVideoRecording = false
            }
        } catch (e: Exception) {
            throw RuntimeException("MEDIA_RECORD_ERROR: Failed to stop media recorder.", e)
        }
    }
}