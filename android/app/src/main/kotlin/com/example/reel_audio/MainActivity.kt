package com.example.reel_audio

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.reel_audio/tts"
    private var tts: TextToSpeech? = null
    private var ttsReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Request manage external storage permission on Android 11+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (!Environment.isExternalStorageManager()) {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "synthesizeToFile" -> {
                        val text     = call.argument<String>("text") ?: ""
                        val filePath = call.argument<String>("filePath") ?: ""
                        val lang     = call.argument<String>("lang") ?: "hi-IN"
                        val rate     = (call.argument<Double>("rate") ?: 0.55).toFloat()
                        val pitch    = (call.argument<Double>("pitch") ?: 1.1).toFloat()
                        synthesize(text, filePath, lang, rate, pitch, result)
                    }
                    "dispose" -> {
                        tts?.shutdown()
                        tts = null
                        ttsReady = false
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun synthesize(
        text: String,
        filePath: String,
        lang: String,
        rate: Float,
        pitch: Float,
        result: MethodChannel.Result
    ) {
        // Delete old file
        val outFile = File(filePath)
        if (outFile.exists()) outFile.delete()

        val locale = Locale.forLanguageTag(lang)

        if (tts != null && ttsReady) {
            doSynthesize(text, filePath, locale, rate, pitch, result)
            return
        }

        // Init TTS fresh
        tts?.shutdown()
        tts = TextToSpeech(applicationContext) { status ->
            if (status == TextToSpeech.SUCCESS) {
                ttsReady = true
                doSynthesize(text, filePath, locale, rate, pitch, result)
            } else {
                result.error("TTS_INIT_FAILED", "TTS engine failed to initialize. Status: $status", null)
            }
        }
    }

    private fun doSynthesize(
        text: String,
        filePath: String,
        locale: Locale,
        rate: Float,
        pitch: Float,
        result: MethodChannel.Result
    ) {
        val engine = tts ?: run {
            result.error("TTS_NULL", "TTS not initialized", null)
            return
        }

        // Set language — fallback to en-US if not available
        val langResult = engine.setLanguage(locale)
        if (langResult == TextToSpeech.LANG_MISSING_DATA || langResult == TextToSpeech.LANG_NOT_SUPPORTED) {
            engine.setLanguage(Locale.US)
        }

        engine.setSpeechRate(rate)
        engine.setPitch(pitch)

        val utteranceId = "utt_${System.currentTimeMillis()}"

        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(id: String?) {}
            override fun onDone(id: String?) {
                if (id == utteranceId) {
                    runOnUiThread {
                        if (File(filePath).exists()) {
                            result.success(true)
                        } else {
                            result.error("FILE_NOT_CREATED", "TTS ran but file was not created at $filePath", null)
                        }
                    }
                }
            }
            override fun onError(id: String?) {
                runOnUiThread {
                    result.error("TTS_ERROR", "TTS synthesis error for utterance $id", null)
                }
            }
        })

        val params = Bundle()
        params.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId)

        val r = engine.synthesizeToFile(text, params, File(filePath), utteranceId)
        if (r != TextToSpeech.SUCCESS) {
            result.error("SYNTH_FAILED", "synthesizeToFile returned error code: $r", null)
        }
    }

    override fun onDestroy() {
        tts?.shutdown()
        super.onDestroy()
    }
}
