import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// These classes should be defined at the top level, not inside _ChatPageState
enum MessageType { text, offer }

class TradeOffer {
  final String item;
  final String amount;
  final String description;
  final bool isPending;
  
  TradeOffer({
    required this.item,
    required this.amount,
    this.description = '',
    this.isPending = true,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final MessageType type;
  final TradeOffer? offer;
  
  ChatMessage({
    required this.text, 
    required this.isUser, 
    required this.time,
    this.type = MessageType.text,
    this.offer,
  });
}

class ChatPage extends StatefulWidget {
  final String contactName;
  final String contactAvatar;
  final Map<String, dynamic>? userData; // Optional user data
  
  const ChatPage({
    Key? key, 
    this.contactName = 'John Smith', // Default dummy name
    this.contactAvatar = '',
    required this.userData,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isShiftPressed = false;
  
  // Sample messages
  List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I saw your listing for the energy tokens.',
      isUser: false,
      time: DateTime(2025, 3, 8, 14, 30),
    ),
    ChatMessage(
      text: 'Hi there! Yes, I have 500 tokens available for trade.',
      isUser: true,
      time: DateTime(2025, 3, 8, 14, 32),
    ),
    ChatMessage(
      text: 'What rate are you offering?',
      isUser: false,
      time: DateTime(2025, 3, 8, 14, 33),
    ),
    ChatMessage(
      text: '',
      isUser: true,
      time: DateTime(2025, 3, 8, 14, 35),
      type: MessageType.offer,
      offer: TradeOffer(
        item: 'Energy Tokens',
        amount: '500',
        description: 'Solar energy tokens from my March generation',
      ),
    ),
    ChatMessage(
      text: 'That looks good. Could you go a bit lower on the price?',
      isUser: false,
      time: DateTime(2025, 3, 8, 14, 40),
    ),
    ChatMessage(
      text: '',
      isUser: false,
      time: DateTime(2025, 3, 8, 14, 35),
      type: MessageType.offer,
      offer: TradeOffer(
        item: 'Energy Tokens',
        amount: '500',
        description: 'Solar energy tokens from my March generation',
      ),
    ),
  ];
  
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _addMessage(text);
      _messageController.clear();
      _messageController.text = '';
      _focusNode.requestFocus();
    }
  }

  void _addMessage(String text, {MessageType type = MessageType.text, TradeOffer? offer}) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          time: DateTime.now(),
          type: type,
          offer: offer,
        ),
      );
    });
    
    // Clear the input field
    _messageController.clear();
    _messageController.text = '';
    
    // Scroll to the bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _messageController.clear();
    _messageController.text = '';
    });
  }
  
  void _showNewOfferDialog() {
    String offerItem = '';
    String offerAmount = '';
    String offerDescription = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Amount to trade',
                  hintText: 'e.g. 500',
                ),
                onChanged: (value) => offerItem = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: 'e.g. 500',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => offerAmount = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Any additional details',
                ),
                maxLines: 2,
                onChanged: (value) => offerDescription = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C005C),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (offerItem.isNotEmpty && offerAmount.isNotEmpty) {
                _addMessage(
                  '',
                  type: MessageType.offer,
                  offer: TradeOffer(
                    item: offerItem,
                    amount: offerAmount,
                    description: offerDescription,
                  ),
                );
              }
            },
            child: const Text('SEND OFFER',
            style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.contactAvatar.isNotEmpty 
                  ? NetworkImage(widget.contactAvatar) 
                  : null,
              backgroundColor: Colors.purple.shade300,
              child: widget.contactAvatar.isEmpty 
                  ? Text(widget.contactName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: const TextStyle(fontSize: 18),
                ),
                const Text(
                  'Online',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2A0030).withOpacity(0.9),
              const Color(0xFF5C005C).withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageItem(message);
                },
              ),
            ),
            
            // Input area
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Offer button
                  IconButton(
                    icon: const Icon(Icons.local_offer, color: Colors.white70),
                    onPressed: _showNewOfferDialog,
                    tooltip: 'Send Offer',
                  ),
                  
                  // Updated Text input with Enter key handling
                  // Text input with multiline support
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _focusNode.hasFocus
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? Colors.purpleAccent.withOpacity(0.5)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (RawKeyEvent event) {
                          _isShiftPressed = event.isKeyPressed(LogicalKeyboardKey.shiftLeft) ||
                              event.isKeyPressed(LogicalKeyboardKey.shiftRight);
                          if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter && !_isShiftPressed) {
                            _sendMessage();
                          }
                        },
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.purpleAccent,
                          cursorWidth: 2,
                          // Allow multiple lines
                          minLines: 1,
                          maxLines: 5, // Limit to 5 lines before scrolling
                          textCapitalization: TextCapitalization.sentences, // Start with capital letter
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (value) {
                            if (!_isShiftPressed) {
                              _sendMessage();
                              // Re-focus the input field after sending
                              Future.delayed(const Duration(milliseconds: 50), () {
                                _focusNode.requestFocus();
                              });
                              Future.delayed(const Duration(milliseconds: 200), () {
                                _messageController.text = '';
                                _messageController.dispose();
                              });
                            }
                          },
                          textInputAction: TextInputAction.newline,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Send button
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: const Color(0xFF5C005C),
                    onPressed: _sendMessage, // Use the same method as Enter key
                    child: const Icon(
                      Icons.send,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
  return Align(
    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: EdgeInsets.only(
        left: message.isUser ? 64 : 8,
        right: message.isUser ? 8 : 64,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: message.isUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          // Message bubble - no fixed width constraints here
          message.type == MessageType.text
              ? _buildTextMessage(message)
              : _buildOfferMessage(message),
          
          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(
              _formatTime(message.time),
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTextMessage(ChatMessage message) {
  return ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width * 0.7, // Maximum width is 70% of screen
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: message.isUser 
            ? const Color(0xFF5C005C) 
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message.text,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}

  Widget _buildOfferMessage(ChatMessage message) {
    final offer = message.offer!;
    
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2A0030),
            const Color(0xFF5C005C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.local_offer, color: Colors.purpleAccent, size: 16),
              SizedBox(width: 8),
              Text(
                'TRADE OFFER',
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const Divider(color: Colors.purpleAccent, height: 20),
          
          // Offer details
          _buildOfferDetailRow('Amount', offer.item),
          const SizedBox(height: 8),
          _buildOfferDetailRow('Price', offer.amount),
          
          if (offer.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildOfferDetailRow('Details', offer.description),
          ],
          
          const SizedBox(height: 16),
          
          // Status and buttons
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.spaceBetween,
            children: [
              if (!message.isUser) ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(100, 36),
                  ),
                  onPressed: () {},
                  child: const Text('ACCEPT'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {},
                  child: const Text('DECLINE'),
                ),
              ],
              
              if (message.isUser)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfferDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label + ':',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}