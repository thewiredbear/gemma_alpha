package com.example.gemma_mobile_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register the MediaPipe text embedder plugin
        flutterEngine.plugins.add(MediaPipeTextEmbedderPlugin())
    }
}
