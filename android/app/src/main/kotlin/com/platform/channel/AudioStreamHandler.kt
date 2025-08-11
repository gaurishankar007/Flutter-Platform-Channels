package com.platform.channel

import AndroidAudioStreamRequest
import android.Manifest
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.util.Log
import androidx.annotation.RequiresPermission

class AudioStreamHandler {
    private var audioRecord: AudioRecord? = null
    private var audioRunnable: Runnable? = null
    private var isAudioStreaming: Boolean = false

    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    fun startStream(
        request: AndroidAudioStreamRequest,
        handler: Handler,
        onAudioReceived: (ByteArray) -> Unit,
    ) {
        try {
            if (isAudioStreaming) {
                throw RuntimeException("AUDIO_RECORD_ERROR: Audio streaming is already started.")
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
                            onAudioReceived(audioBytesToSend)
                        }

                        // Reschedule the runnable to run again
                        handler.post(this)
                    }
                }
            }

            // Start the repeating task
            handler.post(audioRunnable!!)
            isAudioStreaming = true
        } catch (e: Exception) {
            throw RuntimeException("AUDIO_RECORD_ERROR: Failed to start audio stream.", e)
        }
    }

    fun stopStream(handler: Handler) {
        try {
            if (isAudioStreaming) {
                handler.removeCallbacks(audioRunnable!!)
                audioRunnable = null
                audioRecord?.stop()
                audioRecord?.release()
                audioRecord = null
                isAudioStreaming = false
            }
        } catch (e: Exception) {
            Log.e("AUDIO_RECORD_ERROR", "AUDIO_RECORD_ERROR: Failed to stop audio stream.", e)
        }
    }
}