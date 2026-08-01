package io.github.bonkoturyu.timer_utility

import android.Manifest
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.ModelDownloadListener
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
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
        private const val TAG = "OnDeviceSpeech"
    }

    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private var recognizer: SpeechRecognizer? = null
    private var listening = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(isAvailable())
                "checkSupport" -> withSpeechArguments(call, result) {
                    localeTag, _ ->
                    checkSupport(localeTag, result)
                }
                "requestModelDownload" -> withSpeechArguments(call, result) {
                    localeTag, _ ->
                    requestModelDownload(localeTag, result)
                }
                "startListening" -> {
                    withSpeechArguments(call, result) { localeTag, phrases ->
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

    private fun withSpeechArguments(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
        action: (String, List<String>) -> Unit,
    ) {
        val localeTag = call.argument<String>("localeTag")
        val phrases = call.argument<List<String>>("biasingPhrases")
        if (localeTag.isNullOrBlank() || phrases == null) {
            result.error("INVALID_ARGUMENT", "Missing speech arguments", null)
            return
        }
        action(localeTag, phrases)
    }

    private fun getOrCreateRecognizer(): SpeechRecognizer =
        recognizer ?: SpeechRecognizer
            .createOnDeviceSpeechRecognizer(activity)
            .also {
                it.setRecognitionListener(this)
                recognizer = it
            }

    private fun buildIntent(spec: OnDeviceSpeechIntentSpec): Intent =
        Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, spec.localeTag)
            spec.maxResults?.let { putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, it) }
            spec.partialResults?.let {
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, it)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                spec.biasingPhrases?.let {
                    putStringArrayListExtra(
                        RecognizerIntent.EXTRA_BIASING_STRINGS,
                        ArrayList(it),
                    )
                }
            }
        }

    private fun checkSupport(
        localeTag: String,
        result: MethodChannel.Result,
    ) {
        if (!isAvailable()) {
            result.success("unavailable")
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success("ready")
            return
        }

        try {
            getOrCreateRecognizer().checkRecognitionSupport(
                buildIntent(OnDeviceSpeechRecognitionPolicy.modelIntentSpec(localeTag)),
                activity.mainExecutor,
                object : RecognitionSupportCallback {
                    override fun onSupportResult(recognitionSupport: RecognitionSupport) {
                        logSupportResult(recognitionSupport, localeTag)
                        result.success(
                            OnDeviceSpeechRecognitionPolicy.supportStatus(
                                installedLanguages =
                                    recognitionSupport.installedOnDeviceLanguages,
                                pendingLanguages =
                                    recognitionSupport.pendingOnDeviceLanguages,
                                downloadableLanguages =
                                    recognitionSupport.supportedOnDeviceLanguages,
                                localeTag = localeTag,
                                downloadCallbacksAvailable =
                                    Build.VERSION.SDK_INT >=
                                        Build.VERSION_CODES.UPSIDE_DOWN_CAKE,
                            ).wireValue,
                        )
                    }

                    override fun onError(error: Int) {
                        result.success(supportErrorStatus(error))
                    }
                },
            )
        } catch (_: UnsupportedOperationException) {
            result.success("unavailable")
        } catch (_: RuntimeException) {
            result.success("unavailable")
        }
    }

    private fun logSupportResult(
        support: RecognitionSupport,
        localeTag: String,
    ) {
        if (activity.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) return
        Log.d(
            TAG,
            "support locale=$localeTag " +
                "installed=${support.installedOnDeviceLanguages} " +
                "pending=${support.pendingOnDeviceLanguages} " +
                "downloadable=${support.supportedOnDeviceLanguages} " +
                "online=${support.onlineLanguages}",
        )
    }

    private fun supportErrorStatus(error: Int): String =
        OnDeviceSpeechRecognitionPolicy.supportErrorStatus(
            when (error) {
                SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED ->
                    OnDeviceSpeechSupportError.LANGUAGE_NOT_SUPPORTED
                SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE ->
                    OnDeviceSpeechSupportError.LANGUAGE_UNAVAILABLE
                else -> OnDeviceSpeechSupportError.OTHER
            },
        ).wireValue

    private fun requestModelDownload(
        localeTag: String,
        result: MethodChannel.Result,
    ) {
        if (!isAvailable()) {
            result.success("unavailable")
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success("unavailable")
            return
        }

        val intent = buildIntent(OnDeviceSpeechRecognitionPolicy.modelIntentSpec(localeTag))
        try {
            val target = getOrCreateRecognizer()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                var completed = false
                fun finish(status: String) {
                    if (completed) return
                    completed = true
                    result.success(status)
                }
                target.triggerModelDownload(
                    intent,
                    activity.mainExecutor,
                    object : ModelDownloadListener {
                        override fun onProgress(completedPercent: Int) = Unit

                        override fun onSuccess() {
                            finish("ready")
                        }

                        override fun onScheduled() {
                            finish("download_pending")
                        }

                        override fun onError(error: Int) {
                            finish(supportErrorStatus(error))
                        }
                    },
                )
            } else {
                @Suppress("DEPRECATION")
                target.triggerModelDownload(intent)
                result.success("download_pending")
            }
        } catch (_: UnsupportedOperationException) {
            result.success("unavailable")
        } catch (_: RuntimeException) {
            result.success("unavailable")
        }
    }

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
            val target = getOrCreateRecognizer()
            val intent = buildIntent(
                OnDeviceSpeechRecognitionPolicy.listeningIntentSpec(
                    localeTag,
                    biasingPhrases,
                ),
            )
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
            SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED -> "language_unsupported"
            SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> "language_unavailable"
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
