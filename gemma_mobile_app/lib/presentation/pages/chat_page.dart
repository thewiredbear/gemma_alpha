import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/providers/chat_provider.dart';
import '../widgets/model_selector.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_message.dart';
import '../widgets/blinking_cursor.dart';
import '../../core/utils/platform_helper.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gemma AI Chat (${PlatformHelper.platformName})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showConversationHistory(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Model Selector
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: ModelSelector(),
            ),
            
            // Status Message
            Consumer<ChatProvider>(
              builder: (context, provider, child) {
                if (provider.statusMessage.isEmpty) return const SizedBox.shrink();
                
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: provider.statusMessage.startsWith('ERROR')
                        ? Colors.red.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: provider.statusMessage.startsWith('ERROR')
                          ? Colors.red
                          : Colors.blue,
                    ),
                  ),
                  child: Text(
                    provider.statusMessage,
                    style: TextStyle(
                      color: provider.statusMessage.startsWith('ERROR')
                          ? Colors.red
                          : Colors.blue,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Chat Messages
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, child) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: provider.messages.length + 
                        (provider.currentResponse.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < provider.messages.length) {
                        return ChatMessage(message: provider.messages[index]);
                      } else {
                        // Current AI response being generated
                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(provider.currentResponse),
                                  if (provider.isLoading)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: BlinkingCursor(),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  );
                },
              ),
            ),
            
            // Chat Input
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: ChatInput(),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showConversationHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ConversationHistorySheet(),
    );
  }
}

class ConversationHistorySheet extends StatelessWidget {
  const ConversationHistorySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ChatProvider>();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conversation History',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder(
              future: provider.getConversationHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No conversation history yet'),
                  );
                }
                
                final conversations = snapshot.data!;
                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return ListTile(
                      title: Text(conversation.title),
                      subtitle: Text(conversation.preview),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => provider.deleteConversation(conversation),
                      ),
                      onTap: () {
                        provider.loadConversation(conversation);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}