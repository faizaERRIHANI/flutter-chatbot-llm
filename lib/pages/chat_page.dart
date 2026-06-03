import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String _apiUrl = 'http://localhost:11434/api/chat';
const String _model = 'tinyllama';

class ChatPage extends StatefulWidget {
  final String username;
  const ChatPage({super.key, required this.username});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _userController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent + 60);
      }
    });
  }

  Future<void> _sendMessage() async {
    final question = _userController.text.trim();
    if (question.isEmpty) return;
    _userController.clear();
    setState(() {
      messages.add({'type': 'user', 'content': question});
      _isLoading = true;
    });
    _scrollToBottom();
    try {
      final uri = Uri.parse(_apiUrl);
      final body = {
        'model': _model,
        'messages': [{'role': 'user', 'content': question}],
        'stream': false,
      };
      final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body));
      if (response.statusCode == 200) {
        final aiResponse = json.decode(response.body);
        final answer = aiResponse['message']['content'];
        setState(() {
          messages.add({'type': 'assistant', 'content': answer});
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        _handleError('Erreur serveur: ${response.statusCode}');
      }
    } catch (err) {
      print(err);
      _handleError('Impossible de joindre le serveur.');
    }
  }

  void _handleError(String msg) {
    setState(() {
      messages.add({'type': 'assistant', 'content': '⚠️ $msg'});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DWM Chatbot',
          style: TextStyle(color: Theme.of(context).indicatorColor,
            fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [IconButton(
          onPressed: () => setState(() => messages.clear()),
          icon: const Icon(Icons.delete_outline, color: Colors.white))]),
      body: Column(children: [
        Expanded(child: messages.isEmpty
          ? const Center(child: Text('Posez votre première question !',
              style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final isUser = messages[index]['type'] == 'user';
                return Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.all(6),
                  color: isUser
                    ? const Color.fromARGB(30, 0, 255, 0) : Colors.white,
                  child: ListTile(
                    leading: isUser ? null : CircleAvatar(
                      backgroundColor: const Color(0xFF00897B),
                      child: const Icon(Icons.smart_toy,
                        color: Colors.white, size: 18)),
                    trailing: isUser ? CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Text(widget.username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.black87))) : null,
                    title: Text('${messages[index]['content']}',
                      textAlign: isUser ? TextAlign.right : TextAlign.left)));
              })),
        if (_isLoading) const Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator()),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: [
            Expanded(child: TextFormField(
              controller: _userController,
              decoration: InputDecoration(
                hintText: 'Votre question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10))),
              onFieldSubmitted: (_) => _sendMessage())),
            IconButton(
              onPressed: _isLoading ? null : _sendMessage,
              icon: Icon(Icons.send,
                color: Theme.of(context).primaryColor))
          ]))
      ]));
  }
}
