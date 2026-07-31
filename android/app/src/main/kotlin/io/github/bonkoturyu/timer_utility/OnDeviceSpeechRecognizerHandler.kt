package io.github.bonkoturyu.timer_utility

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Owns Android's API 31+ on-device speech recognizer.
 *
 * This class never calls `createSpeechRecognizer`; an unavailable on-device
 * engine is reported to Flutter instead of falling back to cloud recognition.
 * Transcripts are forwarded transiently and are never logged or persisted.
 */
class OnDeviceSpeechRecognizerHandler(
    private val activity: MainActivity,
    messenger: BinaryMessenger,
) : RecognitionListener {
    companion object {
        const val CHANNEL_NAME = "io.github.bonkoturyu.timer_utility/on_device_speech"
    }

    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private var recognizer: SpeechRecognizer? = null
    private var listening = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(isAvailable())
                "startListening" -> {
                    val localeTag = call.argument<String>("localeTag")
                    val phrases = call.argument<List<String>>("biasingPhrases")
                    if (localeTag.isNullOrBlank() || phrases == null) {
                        result.error("INVALID_ARGUMENT", "Missing speech arguments", null)
                    } else {
                        startListening(localeTag, phrases, result)
                    }
                }
                "cancelListening" -> {
                    cancelListening()
                    result.success(null)
                }
                "destroy" -> {
                    result.success(null)
                    dispose()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAvailable(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            SpeechRecognizer.isOnDeviceRecognitionAvailable(activity)

    private fun startListening(
        localeTag: String,
        biasingPhrases: List<String>,
        result: MethodChannel.Result,
    ) {
        if (!isAvailable()) {
            result.error("ON_DEVICE_UNAVAILABLE", "On-device recognition unavailable", null)
            return
        }
        if (
            ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error("MICROPHONE_PERMISSION_DENIED", "Microphone permission denied", null)
            return
        }
        if (listening) {
            result.error("RECOGNIZER_BUSY", "Recognition session is already active", null)
            return
        }

        try {
            val target = recognizer ?: SpeechRecognizer
                .createOnDeviceSpeechRecognizer(activity)
                .also {
                    it.setRecognitionListener(this)
                    recognizer = it
                }
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(
                    RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                    RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
                )
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeTag)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    putStringArrayListExtra(
                        RecognizerIntent.EXTRA_BIASING_STRINGS,
                        ArrayList(biasingPhrases),
                    )
                }
            }
            listening = true
            target.startListening(intent)
            result.success(null)
        } catch (_: SecurityException) {
            listening = false
            result.error("MICROPHONE_PERMISSION_DENIED", "Microphone permission denied", null)
        } catch (_: UnsupportedOperationException) {
            listening = false
            result.error("ON_DEVICE_UNAVAILABLE", "On-device recognition unavailable", null)
        } catch (error: RuntimeException) {
            listening = false
            result.error("RECOGNIZER_ERROR", error.javaClass.simpleName, null)
        }
    }

    private fun cancelListening() {
        listening = false
        recognizer?.cancel()
    }

    fun dispose() {
        listening = false
        recognizer?.cancel()
        recognizer?.destroy()
        recognizer = null
        channel.setMethodCallHandler(null)
    }

    override fun onReadyForSpeech(params: Bundle?) {
        channel.invokeMethod("onReady", null)
    }

    override fun onBeginningOfSpeech() = Unit

    override fun onRmsChanged(rmsdB: Float) = Unit

    override fun onBufferReceived(buffer: ByteArray?) = Unit

    override fun onEndOfSpeech() = Unit

    override fun onError(error: Int) {
        listening = false
        val code = when (error) {
            SpeechRecognizer.ERROR_NO_MATCH -> "no_match"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "speech_timeout"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "recognizer_busy"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS ->
                "microphone_permission_denied"
            SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED,
            SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE
            -> "language_unavailable"
            else -> "other"
        }
        channel.invokeMethod("onError", mapOf("code" to code))
    }

    override fun onResults(results: Bundle?) {
        listening = false
        val hypotheses =
            results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION).orEmpty()
        val scores = results
            ?.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)
            ?.map { it.toDouble() }
            .orEmpty()
        channel.invokeMethod(
            "onFinalResult",
            mapOf(
                "hypotheses" to hypotheses,
                "confidenceScores" to scores,
            ),
        )
    }

    override fun onPartialResults(partialResults: Bundle?) = Unit

    override fun onEvent(eventType: Int, params: Bundle?) = Unit
}
