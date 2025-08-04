package com.example.gemma_mobile_app

import android.content.Context
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.text.textembedder.TextEmbedder
import com.google.mediapipe.tasks.text.textembedder.TextEmbedder.TextEmbedderOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MediaPipeTextEmbedderPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var textEmbedder: TextEmbedder? = null
    private lateinit var backgroundExecutor: ExecutorService

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mediapipe_text_embedder")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        backgroundExecutor = Executors.newSingleThreadExecutor()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val modelPath = call.argument<String>("modelPath")
                if (modelPath == null) {
                    result.error("INVALID_ARG", "modelPath argument is missing.", null)
                    return
                }
                initializeEmbedder(modelPath, result)
            }
            "embedText" -> {
                val textToEmbed = call.argument<String>("text")
                if (textToEmbed == null) {
                    result.error("INVALID_ARG", "text argument is missing.", null)
                    return
                }
                embedText(textToEmbed, result)
            }
            "close" -> closeEmbedder(result)
            else -> result.notImplemented()
        }
    }

    private fun initializeEmbedder(modelAssetPath: String, result: Result) {
        backgroundExecutor.execute {
            try {
                val baseOptions = BaseOptions.builder().setModelAssetPath(modelAssetPath).build()
                val options = TextEmbedderOptions.builder().setBaseOptions(baseOptions).build()
                textEmbedder = TextEmbedder.createFromOptions(context, options)
                
                context.mainExecutor.execute { result.success(true) }
            } catch (e: Exception) {
                context.mainExecutor.execute {
                    result.error("INITIALIZATION_ERROR", "Failed to initialize MediaPipe: ${e.message}", null)
                }
            }
        }
    }

    private fun embedText(text: String, result: Result) {
        val embedder = textEmbedder
        if (embedder == null) {
            result.error("NOT_INITIALIZED", "TextEmbedder not initialized.", null)
            return
        }

        backgroundExecutor.execute {
            try {
                val embeddingResult = embedder.embed(text)
                
                // **** CORRECTED SECTION ****
                // The result is nested. We need to access the textEmbedderResult() first.
                val embeddingContainer = embeddingResult.textEmbedderResult().get()
                if (embeddingContainer.embeddings().isNotEmpty()) {
                    val embedding = embeddingContainer.embeddings()[0]
                    val vector = embedding.floatEmbedding().map { it.toDouble() }.toDoubleArray()

                    context.mainExecutor.execute {
                        result.success(vector)
                    }
                } else {
                    context.mainExecutor.execute {
                        result.error("EMBEDDING_ERROR", "Model failed to produce an embedding.", null)
                    }
                }
                 // **** END OF CORRECTION ****

            } catch (e: Exception) {
                context.mainExecutor.execute {
                    result.error("EMBEDDING_ERROR", "Failed to embed text: ${e.message}", null)
                }
            }
        }
    }
    
    private fun closeEmbedder(result: Result) {
        backgroundExecutor.execute {
            try {
                textEmbedder?.close()
                textEmbedder = null
                context.mainExecutor.execute { result.success(null) }
            } catch (e: Exception) {
                context.mainExecutor.execute {
                    result.error("CLOSE_ERROR", "Error closing TextEmbedder: ${e.message}", null)
                }
            }
        }
    }


    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        backgroundExecutor.execute {
            textEmbedder?.close()
            textEmbedder = null
        }
        backgroundExecutor.shutdown()
    }
}