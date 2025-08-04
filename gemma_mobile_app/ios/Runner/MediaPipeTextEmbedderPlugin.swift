import Flutter
import UIKit
import MediaPipeTasksText

@objc class MediaPipeTextEmbedderPlugin: NSObject, FlutterPlugin {
    private var textEmbedder: TextEmbedder?
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "mediapipe_text_embedder", binaryMessenger: registrar.messenger())
        let instance = MediaPipeTextEmbedderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(call: call, result: result)
        case "embedText":
            embedText(call: call, result: result)
        case "calculateSimilarity":
            calculateSimilarity(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let modelPath = args["modelPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Model path is required", details: nil))
            return
        }
        
        do {
            // Get the model file path from the app bundle
            guard let modelFilePath = Bundle.main.path(forResource: "universal_sentence_encoder", ofType: "tflite") else {
                result(FlutterError(code: "MODEL_NOT_FOUND", message: "Model file not found in bundle", details: nil))
                return
            }
            
            // Create TextEmbedder options
            let options = TextEmbedderOptions()
            options.baseOptions.modelAssetPath = modelFilePath
            
            // Initialize the text embedder
            textEmbedder = try TextEmbedder(options: options)
            
            print("✅ MediaPipe TextEmbedder initialized successfully")
            result(true)
            
        } catch {
            print("❌ Failed to initialize TextEmbedder: \(error)")
            result(FlutterError(code: "INITIALIZATION_FAILED", message: error.localizedDescription, details: nil))
        }
    }
    
    private func embedText(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let textEmbedder = textEmbedder else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "TextEmbedder not initialized", details: nil))
            return
        }
        
        guard let args = call.arguments as? [String: Any],
              let text = args["text"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Text is required", details: nil))
            return
        }
        
        do {
            // Embed the text
            let embeddingResult = try textEmbedder.embed(text: text)
            
            // Extract the embedding vector
            if let embedding = embeddingResult.embeddings.first,
               let floatEmbedding = embedding.floatEmbedding {
                print("✅ Generated \(floatEmbedding.count)D embedding vector")
                result(floatEmbedding)
            } else {
                result(FlutterError(code: "NO_EMBEDDING", message: "No embedding generated", details: nil))
            }
            
        } catch {
            print("❌ Failed to embed text: \(error)")
            result(FlutterError(code: "EMBEDDING_FAILED", message: error.localizedDescription, details: nil))
        }
    }
    
    private func calculateSimilarity(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let textEmbedder = textEmbedder else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "TextEmbedder not initialized", details: nil))
            return
        }
        
        guard let args = call.arguments as? [String: Any],
              let text1 = args["text1"] as? String,
              let text2 = args["text2"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Both text1 and text2 are required", details: nil))
            return
        }
        
        do {
            // Embed both texts
            let result1 = try textEmbedder.embed(text: text1)
            let result2 = try textEmbedder.embed(text: text2)
            
            // Get the embeddings
            guard let embedding1 = result1.embeddings.first,
                  let embedding2 = result2.embeddings.first else {
                result(FlutterError(code: "NO_EMBEDDING", message: "Failed to generate embeddings", details: nil))
                return
            }
            
            // Calculate cosine similarity
            let similarity = try TextEmbedder.cosineSimilarity(embedding1: embedding1, embedding2: embedding2)
            
            print("✅ Calculated cosine similarity: \(String(format: "%.2f", similarity * 100))%")
            result(similarity)
            
        } catch {
            print("❌ Failed to calculate similarity: \(error)")
            result(FlutterError(code: "SIMILARITY_FAILED", message: error.localizedDescription, details: nil))
        }
    }
}