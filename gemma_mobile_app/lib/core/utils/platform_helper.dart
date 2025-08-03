import 'dart:io';

class PlatformHelper {
  static String getModelInstructions() {
    if (Platform.isIOS) {
      return 'To add the model file to your iOS device:\n\n'
             '📱 Method 1 - iTunes/Finder File Sharing:\n'
             '1. Connect your device to iTunes/Finder\n'
             '2. Go to your device > Apps > File Sharing\n'
             '3. Select "Gemma Mobile App"\n'
             '4. Drag the .task file into the Documents folder\n\n'
             '📡 Method 2 - AirDrop:\n'
             '1. AirDrop the .task file to your device\n'
             '2. When prompted, choose "Gemma Mobile App"\n\n'
             '📁 Method 3 - Files App:\n'
             '1. Save the file to iCloud Drive or Files app\n'
             '2. Open Files app and navigate to the file\n'
             '3. Share the file and choose "Gemma Mobile App"\n\n'
             '⚠️ Important: The file must be named exactly as shown in the model selector.';
    } else {
      return 'Please ensure the model file is in your device\'s Download folder.';
    }
  }
  
  static String get platformName => Platform.operatingSystem;
}