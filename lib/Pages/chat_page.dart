import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:test_web/Services/cognito_service.dart';

import '../Services/user_service.dart';

enum MessageType { text, offer }

class TradeOffer {
  final String item;           // Display name of trade
  final String amount;         // Text representation of amount (with units)
  final String description;    // Additional description text
  final bool isPending;        // Quick check if pending
  final String status;         // "pending", "accepted", "rejected"
  final double pricePerUnit;   // Numeric price per kWh
  final int totalAmount;       // Numeric amount in kWh
  final DateTime startTime;    // When the trade starts
  final String tradeType;      // "buy" or "sell"
  
  TradeOffer({
    required this.item,
    required this.amount,
    this.description = '',
    this.isPending = true,
    this.status = 'pending',
    required this.pricePerUnit,
    required this.totalAmount,
    required this.startTime,
    required this.tradeType,
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

// Model class for chat users
class ChatUser {
  final String userId;
  final String username;
  
  ChatUser({required this.userId, required this.username});
  
  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      userId: json['user_id'],
      username: json['username'],
    );
  }
}

class ChatPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const ChatPage({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _isShiftPressed = false;
  bool _isLoadingUsers = false;
  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  ChatUser? _currentChatUser;
  bool _showUsersList = false; // To toggle between conversations and all users
  String? _nextPageToken;
  
  List<ChatMessage> _messages = [];
  List<ChatUser> _users = [];
  List<ChatUser> _filteredUsers = [];
  List<Conversation> _conversations = [];
  List<Conversation> _filteredConversations = [];
  
  @override
  void initState() {
    super.initState();
    _fetchRecentConversations();
  }
  
  Future<void> _fetchRecentConversations() async {
    setState(() {
      _isLoadingConversations = true;
    });
    
    try {
      final cognitoService = CognitoService();
      final fetchedConversations = await cognitoService.getRecentConversations();
      
      setState(() {
        _conversations = fetchedConversations;
        _filteredConversations = List.from(_conversations);
        _isLoadingConversations = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Exception when loading conversations: $e');
      }
      setState(() {
        _isLoadingConversations = false;
        // Add fallback data for testing if needed
        _conversations = [
          Conversation(
            username: 'John',
            lastMessage: 'Hello, are you interested in buying solar credits?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
            updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
            isTradeOffer: false,
          ),
          Conversation(
            username: 'Sarah',
            lastMessage: 'Energy offer: 150 kWh',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
            isTradeOffer: true,
          ),
        ];
        _filteredConversations = List.from(_conversations);
      });
    }
  }

  Future<void> _loadMessageHistory(String username) async {
    setState(() {
      _isLoadingMessages = true;
      _messages = [];
    });
    
    try {
      final cognitoService = CognitoService();
      final messageResponse = await cognitoService.getMessagesBetweenUsers(username);
      debugPrint('Fetched messages: $messageResponse');
      
      final currentUserId = widget.userData?['cognito:username'] ?? '';
      debugPrint('Current user ID: $currentUserId');
      
      setState(() {
        _messages = messageResponse.messages
            .map((msg) => msg.toChatMessage(currentUserId))
            .toList().reversed.toList(); // Reverse the order to show latest messages at the bottom
        _nextPageToken = messageResponse.nextPageToken;
        _isLoadingMessages = false;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  });
    } catch (e) {
      if (kDebugMode) {
        print('Exception when loading messages: $e');
      }
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }
  
  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          return user.username.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = List.from(_conversations);
      } else {
        _filteredConversations = _conversations.where((convo) {
          return convo.username.toLowerCase().contains(query.toLowerCase()) ||
                convo.lastMessage.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _startConversationWithUser(ChatUser user) {
    setState(() {
      _currentChatUser = user;
      _showUsersList = false;  // Return to conversations view
    });
    
    _loadMessageHistory(user.username);
  }
  
  void _openConversation(String username) {
    // Find or create a user object based on conversation
    final user = ChatUser(userId: username, username: username);
    _startConversationWithUser(user);
  }
  
  // Format timestamps for conversation list
  String _formatConversationTime(DateTime time) {
    final now = DateTime.now();
    final localTime = time.toLocal();
    final difference = now.difference(localTime);
    
    // Today - show time
    if (localTime.day == now.day && localTime.month == now.month && localTime.year == now.year) {
      return DateFormat('h:mm a').format(localTime);
    }
    // Yesterday
    else if (localTime.day == now.day - 1 && localTime.month == now.month && localTime.year == now.year) {
      return 'Yesterday';
    }
    // This week - show day name
    else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(localTime); // e.g. "Monday"
    }
    // Older - show date
    else {
      return DateFormat('MMM d').format(localTime); // e.g. "Apr 18"
    }
  }
  
  // Format timestamps for message bubbles
  String _formatMessageTime(DateTime time) {
    final localTime = time.toLocal();
    return DateFormat('h:mm a · MMM d, y').format(localTime);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 1100;
    
    return Scaffold(
      drawer: isMobile ? _buildDrawer(context) : null,
      appBar: isMobile ? AppBar(
        title: _currentChatUser != null
            ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _currentChatUser = null;
                      });
                    },
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.purple.shade300,
                    child: _currentChatUser!.username.isNotEmpty 
                        ? Text(_currentChatUser!.username[0].toUpperCase())
                        : const Icon(Icons.person, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(_currentChatUser!.username),
                ],
              )
            : const Text("Messages"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A0030),
                Color(0xFF5C005C),
              ],
            ),
          ),
        ),
      ) : null,
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
        child: Row(
          children: [
            // Sidebar for desktop view
            if (!isMobile) _buildSidebar(context),
            
            // Users/Conversations List Panel
            if (!isMobile || (isMobile && _currentChatUser == null))
              Container(
                width: isMobile ? screenSize.width : 300,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  border: Border(
                    right: BorderSide(
                      color: Colors.deepPurple.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Header with toggle button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.deepPurple.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _showUsersList ? 'Start New Chat' : 'Conversations',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              _showUsersList ? Icons.arrow_back : Icons.edit,
                              color: Colors.white70,
                            ),
                            tooltip: _showUsersList ? 'Back to conversations' : 'New message',
                            onPressed: () {
                              setState(() {
                                _showUsersList = !_showUsersList;
                                if (_showUsersList) {
                                  _fetchUsers();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _showUsersList ? 'Search users...' : 'Search conversations...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.search, color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: _showUsersList ? (query) => _filterUsers(query) : _filterConversations,
                      ),
                    ),
                    
                    // Content based on view mode
                    Expanded(
                      child: _showUsersList ? _buildUsersList() : _buildConversationsList(),
                    ),
                  ],
                ),
              ),
            
            // Chat area
            if (!isMobile || (isMobile && _currentChatUser != null))
              Expanded(
                child: _currentChatUser != null
                  ? Column(
                      children: [
                        // Chat header for desktop
                        if (!isMobile)
                          Container(
                            height: 70,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.purple.shade300,
                                  child: _currentChatUser!.username.isNotEmpty
                                      ? Text(
                                          _currentChatUser!.username[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white),
                                        )
                                      : const Icon(Icons.person, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentChatUser!.username,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      'Online',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        
                        // Messages list
                        _isLoadingMessages
                            ? const Expanded(
                                child: Center(
                                  child: CircularProgressIndicator(color: Colors.purpleAccent),
                                ),
                              )
                            : Expanded(
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
                                      if (event is RawKeyDownEvent) {
                                        _isShiftPressed = event.isShiftPressed;
                                        
                                        if (event.logicalKey == LogicalKeyboardKey.enter && !_isShiftPressed) {
                                          _sendMessage();
                                        }
                                      }
                                    },
                                    child: TextField(
                                      controller: _messageController,
                                      focusNode: _focusNode,
                                      style: const TextStyle(color: Colors.white),
                                      cursorColor: Colors.purpleAccent,
                                      cursorWidth: 2,
                                      minLines: 1,
                                      maxLines: 5,
                                      textCapitalization: TextCapitalization.sentences,
                                      decoration: const InputDecoration(
                                        hintText: 'Type a message',
                                        hintStyle: TextStyle(color: Colors.white54),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                                      ),
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
                                onPressed: _sendMessage,
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
                    )
                  : const Center(
                      child: Text(
                        'Select a conversation or start a new chat',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUsersList() {
    return _isLoadingUsers
        ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
        : _filteredUsers.isEmpty
            ? const Center(
                child: Text(
                  'No users found',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade700,
                      child: Text(
                        user.username.isNotEmpty ? user.username[0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      user.username,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'ID: ${user.userId.length > 8 ? user.userId.substring(0, 8) + "..." : user.userId}',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                    onTap: () => _startConversationWithUser(user),
                    trailing: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white70,
                    ),
                  );
                },
              );
  }

  Widget _buildConversationsList() {
    return _isLoadingConversations
        ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
        : _filteredConversations.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No conversations yet',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Start a new chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _showUsersList = true;
                          _fetchUsers();
                        });
                      },
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _filteredConversations.length,
                itemBuilder: (context, index) {
                  final conversation = _filteredConversations[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade700,
                      child: Text(
                        conversation.username.isNotEmpty ? conversation.username[0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      conversation.username,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Row(
                      children: [
                        if (conversation.isTradeOffer)
                          const Icon(Icons.local_offer, color: Colors.white54, size: 12),
                        if (conversation.isTradeOffer)
                          const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            style: TextStyle(color: Colors.white.withOpacity(0.5)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      _formatConversationTime(conversation.timestamp),
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                    onTap: () => _openConversation(conversation.username),
                  );
                },
              );
  }
  
  // Update the message item to show proper timestamps
  Widget _buildMessageItem(ChatMessage message) {
    // Different bubble style based on who sent the message
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(),
          const SizedBox(width: 8),
          
          // The actual bubble
          Flexible(
            child: Container(
              padding: message.type == MessageType.offer 
                  ? const EdgeInsets.all(4) 
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF5C005C).withOpacity(0.8)
                    : Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUser
                      ? Colors.purple.withOpacity(0.5)
                      : Colors.white10,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: message.type == MessageType.offer
                  ? _buildOfferCard(message.offer!, isUser) // Pass isUser parameter
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatMessageTime(message.time),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(width: 8),
          if (isUser) const SizedBox(width: 32), // Space where avatar would be
        ],
      ),
    );
  }

  // Update the offer card to show status properly
  Widget _buildOfferCard(TradeOffer offer, bool isUserSender) {
    // Determine status colors and text
    Color statusColor;
    String statusText = offer.status;
    
    switch (offer.status.toLowerCase()) {
      case 'accepted':
        statusColor = Colors.green.shade400;
        statusText = 'Offer Accepted';
        break;
      case 'rejected':
        statusColor = Colors.red.shade400;
        statusText = 'Offer Rejected';
        break;
      case 'pending':
      default:
        statusColor = Colors.amber.shade400;
        statusText = 'Pending Response';
    }

    // Calculate total value
    final totalValue = offer.pricePerUnit * offer.totalAmount;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5C005C),
            const Color(0xFF3A0030),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.shade300.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trade offer title
          Row(
            children: [
              Icon(
                offer.tradeType == 'sell' ? Icons.arrow_upward : Icons.arrow_downward,
                color: offer.tradeType == 'sell' ? Colors.green : Colors.blue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  offer.item,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Amount, price and total value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Amount',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${offer.totalAmount} kWh',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '\$${offer.pricePerUnit.toStringAsFixed(2)}/kWh',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Total value and start date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Start Date',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(offer.startTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Value',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '\$${totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          
          // Status and action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Only show Accept/Decline buttons if:
              // 1. Offer is pending AND
              // 2. Current user is the RECEIVER (not the sender)
              if (offer.status.toLowerCase() == 'pending' && !isUserSender) ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(40, 36),
                  ),
                  onPressed: () {},
                  child: const Text('Accept'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(40, 36),
                    side: const BorderSide(color: Colors.white30),
                    foregroundColor: Colors.white70,
                  ),
                  onPressed: () {},
                  child: const Text('Decline'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvatar() {
    return const CircleAvatar(
      radius: 16,
      backgroundColor: Color(0xFF4A0060),
      child: Icon(Icons.person, size: 16, color: Colors.white),
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  void _sendMessage() async {
  final text = _messageController.text.trim();
  if (text.isEmpty || _currentChatUser == null) return;

  _messageController.value = TextEditingValue.empty;
  
  // Optimistically add the message to the UI
  final newMessage = ChatMessage(
    text: text,
    isUser: true,
    time: DateTime.now(),
  );
  
  final now = DateTime.now();
  
  setState(() {
    _messages.add(newMessage);
    
    // Update conversation list with this new message
    _updateConversationWithLatestMessage(
      username: _currentChatUser!.username,
      lastMessage: text,
      timestamp: now,
      isTradeOffer: false
    );
  });
  
  // Auto-scroll to the bottom
  Future.delayed(const Duration(milliseconds: 100), () {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _messageController.value = TextEditingValue.empty;
    }
  });
  
  // Actually send the message
  try {
    final cognitoService = CognitoService();
    await cognitoService.sendTextMessage(
      recipientUsername: _currentChatUser!.username,
      text: text,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error sending message: $e');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send message: ${e.toString()}')),
    );
  }
}

// Add this helper method to update the conversation list
void _updateConversationWithLatestMessage({
  required String username,
  required String lastMessage,
  required DateTime timestamp,
  required bool isTradeOffer,
}) {
  // Check if this conversation already exists
  final existingIndex = _conversations.indexWhere((conversation) => 
    conversation.username == username);

  if (existingIndex != -1) {
    // Remove the existing conversation
    final existingConvo = _conversations.removeAt(existingIndex);
    
    // Create updated conversation with new message
    final updatedConvo = Conversation(
      username: existingConvo.username,
      lastMessage: lastMessage,
      timestamp: timestamp,
      updatedAt: timestamp,
      isTradeOffer: isTradeOffer,
    );
    
    // Add it to the beginning of the list
    _conversations.insert(0, updatedConvo);
  } else {
    // Create a new conversation and add it to the beginning
    final newConvo = Conversation(
      username: username,
      lastMessage: lastMessage,
      timestamp: timestamp,
      updatedAt: timestamp,
      isTradeOffer: isTradeOffer,
    );
    
    _conversations.insert(0, newConvo);
  }
  
  // Update filtered conversations as well
  _filteredConversations = List.from(_conversations);
}
  
  void _showNewOfferDialog() {
  final amountController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  String tradeType = 'sell'; // Default to sell

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFF2A0030),
        title: const Text('Create Trade Offer', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trade type selector
              const Text('Trade Type:', style: TextStyle(color: Colors.white70)),
              Row(
                children: [
                  Radio<String>(
                    value: 'sell',
                    groupValue: tradeType,
                    onChanged: (value) {
                      setDialogState(() {
                        tradeType = value!;
                      });
                    },
                    fillColor: MaterialStateProperty.all(Colors.white70),
                  ),
                  const Text('Sell', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 20),
                  Radio<String>(
                    value: 'buy',
                    groupValue: tradeType,
                    onChanged: (value) {
                      setDialogState(() {
                        tradeType = value!;
                      });
                    },
                    fillColor: MaterialStateProperty.all(Colors.white70),
                  ),
                  const Text('Buy', style: TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (kWh)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per kWh (\$)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Start Date: ', style: TextStyle(color: Colors.white70)),
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Colors.purple,
                                onPrimary: Colors.white,
                                surface: Color(0xFF2A0030),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Text(
                      DateFormat('MMM d, yyyy').format(selectedDate),
                      style: const TextStyle(color: Colors.purpleAccent),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
            ),
            onPressed: () async {
              if (amountController.text.isEmpty || priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }
              
              try {
                // Convert inputs to correct types
                final amount = int.tryParse(amountController.text);
                final price = double.tryParse(priceController.text);
                
                if (amount == null || price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid numbers')),
                  );
                  return;
                }
                
                final messageText = descriptionController.text.isNotEmpty 
                    ? descriptionController.text 
                    : tradeType == 'sell' 
                        ? 'Offering $amount kWh at \$$price per kWh'
                        : 'Looking to buy $amount kWh at \$$price per kWh';
                debugPrint('Sending message: $messageText');
                // Close dialog BEFORE any async operations
                Navigator.pop(dialogContext);
                
                // Show loading indicator using the parent widget's setState
                setState(() {
                  _isLoadingMessages = true;
                });
                
                final cognitoService = CognitoService();
                final message = await cognitoService.sendTradeOffer(
                  recipientUsername: _currentChatUser!.username,
                  text: messageText,
                  pricePerUnit: price,
                  startTime: selectedDate,
                  totalAmount: amount,
                  tradeType: tradeType,
                );
                
                // Get current user ID for the message conversion
                final userData = await cognitoService.getUserInfo();
                final currentUserId = userData?['cognito:username'] ?? '';
                
                // Check if widget is still mounted before calling setState
                if (mounted) {
                  setState(() {
                    _isLoadingMessages = false;
                    _messages.add(message.toChatMessage(currentUserId));
                    
                    // Update conversation with trade offer
                    _updateConversationWithLatestMessage(
                      username: _currentChatUser!.username,
                      lastMessage: messageText,
                      timestamp: DateTime.now(),
                      isTradeOffer: true
                    );
                  });
                  
                  // Auto-scroll to the bottom
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                }
              } catch (e) {
                // Check if widget is still mounted before calling setState
                if (mounted) {
                  setState(() {
                    _isLoadingMessages = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error sending offer: $e')),
                  );
                }
              }
            },
            child: const Text('Send Offer'),
          ),
        ],
      ),
    ),
  );
}
  
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF2A0030),
      child: _buildDrawerContent(context),
    );
  }
  
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2A0030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: _buildDrawerContent(context),
    );
  }
  
  Widget _buildDrawerContent(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2A0030), Color(0xff5e0b8b)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlutterLogo(size: 32),
                SizedBox(width: 8),
                Text(
                  'PIONEER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildNavItem(context, 'Dashboard', Icons.dashboard, false, "/home"),
              _buildNavItem(context, 'User Profile', Icons.person, false, "/profile"),
              _buildNavItem(context, 'Analytics', Icons.analytics, false, ""),
              _buildNavItem(context, 'Wallet', Icons.account_balance_wallet, false, ""),
              _buildNavItem(context, 'Transactions', Icons.history, false, "/transactions"),
              _buildNavItem(context, 'Chat', Icons.chat, true, "/chat"),
              _buildNavItem(context, 'Settings', Icons.settings, false, "/settings"),
              _buildNavItem(context, 'Support', Icons.support, false, ""),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C005C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              // Add your sign out logic here
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/signin');
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout),
                SizedBox(width: 8),
                Text('Logout'),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildNavItem(BuildContext context, String title, IconData icon, bool isActive, String route) {
    return ListTile(
      leading: Icon(
        icon, 
        color: isActive ? Colors.white : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? Colors.purple.withOpacity(0.3) : Colors.transparent,
      onTap: () {
        if (route.isNotEmpty) {
          Navigator.pushReplacementNamed(
            context, 
            route,
            arguments: widget.userData
          );
        }
      },
    );
  }

  // Method to fetch users from Cognito
  Future<void> _fetchUsers() async {
  setState(() {
    _isLoadingUsers = true;
  });
  
  try {
    final cognitoService = CognitoService(); // or CognitoService()
    final fetchedUsers = await cognitoService.getUsers();
    
    setState(() {
      _users = fetchedUsers;
      _filteredUsers = List.from(_users);
      _isLoadingUsers = false;
    });
  } catch (e) {
    if (kDebugMode) {
      print('Exception when loading users: $e');
    }
    setState(() {
      _isLoadingUsers = false;
      // Fallback to dummy data
    });
  }
}
}