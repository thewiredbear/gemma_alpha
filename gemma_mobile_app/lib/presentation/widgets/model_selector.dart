import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import '../../core/constants/model_constants.dart';

class ModelSelector extends StatelessWidget {
  const ModelSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.psychology, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Model:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: provider.selectedModelName,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  onChanged: provider.isLoading 
                      ? null 
                      : (String? newValue) {
                          if (newValue != null && 
                              provider.selectedModelName != newValue) {
                            provider.initializeModel(newValue);
                          }
                        },
                  items: ModelConstants.availableModels.keys
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (provider.selectedModelName == value && 
                              provider.isModelReady)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (provider.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        );
      },
    );
  }
}