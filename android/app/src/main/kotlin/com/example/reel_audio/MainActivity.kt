package com.example.reel_audio

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
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
    private val MEDIA_CHANNEL = "com.example.reel_audio/media"
    private var tts: TextToSpeech? = null
    private var ttsReady = false

    // The all-files-access request that used to live in onCreate is gone. It threw the
    // user into a system settings screen at launch to get a permission that only
    // existed so a video could be copied into Movies by hand — and copying it by hand
    // is the bug this class now fixes properly. Saving through MediaStore needs no
    // storage permission at all on Android 10 and up.

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveVideoToGallery" -> saveVideoToGallery(
                        call.argument<String>("path") ?: "",
                        call.argument<String>("name") ?: "reel.mp4",
                        result
                    )
                    else -> result.notImplemented()
                }
            }

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

    /**
     * Puts a finished reel in the phone's gallery.
     *
     * Copying the file into /storage/emulated/0/Movies is not enough, and that is the
     * whole bug: Gallery, Photos and Instagram do not look at the filesystem, they read
     * MediaStore. A file copied in by hand exists on disk but has no MediaStore row, so
     * those apps cannot see it. A player like MX can, because it scans folders itself —
     * which is exactly why the video appeared to be there and missing at the same time.
     *
     * Writing it THROUGH MediaStore creates the row and the file together, so it cannot
     * end up with one and not the other.
     */
    private fun saveVideoToGallery(
        sourcePath: String,
        displayName: String,
        result: MethodChannel.Result
    ) {
        try {
            val source = File(sourcePath)
            if (!source.exists()) {
                result.error("NO_FILE", "The video is not at $sourcePath any more.", null)
                return
            }

            // Before Android 10 there is no RELATIVE_PATH and no IS_PENDING: write the
            // file, then ask the scanner to notice it.
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                val dir = File(
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES),
                    "Reels"
                )
                if (!dir.exists()) dir.mkdirs()
                val dest = File(dir, displayName)
                source.copyTo(dest, overwrite = true)

                MediaScannerConnection.scanFile(
                    applicationContext,
                    arrayOf(dest.absolutePath),
                    arrayOf("video/mp4")
                ) { _, _ ->
                    runOnUiThread { result.success(dest.absolutePath) }
                }
                return
            }

            val values = ContentValues().apply {
                put(MediaStore.Video.Media.DISPLAY_NAME, displayName)
                put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                put(MediaStore.Video.Media.RELATIVE_PATH, Environment.DIRECTORY_MOVIES + "/Reels")
                // Marked pending until the bytes are all written, so nothing picks it up
                // half-copied and caches a broken thumbnail for it.
                put(MediaStore.Video.Media.IS_PENDING, 1)
            }

            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(
                MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY),
                values
            ) ?: run {
                result.error("NO_ROW", "The gallery would not make a place for the video.", null)
                return
            }

            resolver.openOutputStream(uri)?.use { out ->
                source.inputStream().use { it.copyTo(out) }
            } ?: run {
                resolver.delete(uri, null, null)
                result.error("NO_STREAM", "Could not write the video into the gallery.", null)
                return
            }

            values.clear()
            values.put(MediaStore.Video.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            result.success(uri.toString())
        } catch (e: Exception) {
            result.error("SAVE_FAILED", e.message ?: "Saving to the gallery failed.", null)
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
