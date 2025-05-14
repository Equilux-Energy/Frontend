import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test_web/Services/cognito_service.dart';
import '../Services/blockchain_service.dart';
import '../Models/energy_offer.dart';
import '../Services/theme_provider.dart';
import '../Services/user_service.dart';
import 'dart:js_util';

enum MessageType { text, offer }

class TradeOffer {
  final String messageId;       // Added messageId field
  final String item;
  final String amount;
  final String description;
  final bool isPending;
  final String status;
  final double pricePerUnit;
  final int totalAmount;
  final DateTime startTime;
  final String tradeType;
  final bool isNegotiating;
  final Map<String, dynamic>? latestProposal;
  final String? transactionHash; // Add blockchain transaction hash
  
  TradeOffer({
    required this.messageId,    // Make it required
    required this.item,
    required this.amount,
    this.description = '',
    this.isPending = true,
    this.status = 'pending',
    required this.pricePerUnit,
    required this.totalAmount,
    required this.startTime,
    required this.tradeType,
    this.isNegotiating = false,
    this.latestProposal,
    this.transactionHash,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final MessageType type;
  final TradeOffer? offer;
  final String? messageId; // Add this field
  
  ChatMessage({
    required this.text, 
    required this.isUser, 
    required this.time,
    this.type = MessageType.text,
    this.offer,
    this.messageId,
  });
}

// Model class for chat users
class ChatUser {
  final String userId;
  final String username;

  ChatUser({
    required this.userId,
    required this.username,
  });
  
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

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
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
  final BlockchainService _blockchainService = BlockchainService();
  bool _isWalletConnected = false;
  String? _currentWalletAddress;
  int? _currentChainId;
  
  List<ChatMessage> _messages = [];
  List<ChatUser> _users = [];
  List<ChatUser> _filteredUsers = [];
  List<Conversation> _conversations = [];
  List<Conversation> _filteredConversations = [];
  
  // Polling mechanism variables
  Timer? _pollingTimer;
  bool _isPolling = false;
  DateTime? _lastMessageTimestamp;
  int _pollingInterval = 3; // Start with 3 seconds
  int _consecutiveErrorCount = 0;
  final int _maxPollingInterval = 30; // Maximum 30 seconds between polls

  // Add these variables to your _ChatPageState class
  Timer? _refreshTimer;
  bool _isRefreshEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeBlockchain();
    _fetchRecentConversations();
    
    // Add page visibility listener for more efficient polling
    WidgetsBinding.instance.addObserver(this);
  }
  
  Future<void> _initializeBlockchain() async {
    try {
      await _blockchainService.initialize();
      
      // Setup listener for blockchain connection changes
      _blockchainService.addListener(_onBlockchainStateChanged);
      
      setState(() {
        _isWalletConnected = _blockchainService.isConnected;
        _currentWalletAddress = _blockchainService.currentAddress;
        _currentChainId = _blockchainService.currentChainId;
      });
    } catch (e) {
      print('Error initializing blockchain: $e');
    }
  }

  void _onBlockchainStateChanged() {
    // Update state when blockchain service notifies changes
    setState(() {
      _isWalletConnected = _blockchainService.isConnected;
      _currentWalletAddress = _blockchainService.currentAddress;
      _currentChainId = _blockchainService.currentChainId;
    });
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
    
    final currentUserId = widget.userData?['cognito:username'] ?? '';
    
    setState(() {
      _messages = messageResponse.messages
          .map((msg) => msg.toChatMessage(currentUserId))
          .toList().reversed.toList();
      _nextPageToken = messageResponse.nextPageToken;
      _isLoadingMessages = false;
      
      // Set the timestamp for future polling
      if (_messages.isNotEmpty) {
        _lastMessageTimestamp = _messages.first.time;
      }
    });
    
    // Start the message refresh timer AFTER the state update
    _startMessageRefresh();
    
    // Schedule scroll to bottom after messages are loaded
    _scrollToBottom();
    
  } catch (e) {
    print('Exception when loading messages: $e');
    setState(() {
      _isLoadingMessages = false;
    });
    
    // Still start refresh timer even if initial load failed
    _startMessageRefresh();
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
      _messages = []; // Clear previous messages
      _isLoadingMessages = true;
    });
    
    _loadMessageHistory(user.username).then((_) {
      // Start message refresh once initial messages are loaded
      _startMessageRefresh();
    });
  }
  
  void _openConversation(String username) {
    // Find or create a user object based on conversation
    final user = ChatUser(userId: username, username: username);
    _stopMessageRefresh();
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
        actions: [
          _buildWalletButton(),
          // Other actions...
        ],
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

    _messageController.clear();
    _scrollToBottom();
    
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
        
        // Display description if it's not empty
        if (offer.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              offer.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        
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
            // Only show Accept/Decline/Counter buttons if:
            // 1. Offer is pending AND
            // 2. Current user is the RECEIVER (not the sender)
            if (offer.status.toLowerCase() == 'pending' && !isUserSender) ...[
              // Counter offer button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(40, 36),
                  side: const BorderSide(color: Colors.blue),
                  foregroundColor: Colors.blue,
                ),
                onPressed: () => _showCounterOfferDialog(offer),
                child: const Text('Counter'),
              ),
              const SizedBox(width: 8),
              // Accept button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(40, 36),
                ),
                onPressed: () => _respondToOffer(offer.messageId, 'accept'),
                child: const Text('Accept'),
              ),
              const SizedBox(width: 8),
              // Decline button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(40, 36),
                  side: BorderSide(color: Color(0xFFE57373)),
                  foregroundColor: Colors.red.shade300,
                ),
                onPressed: () => _respondToOffer(offer.messageId, 'reject'),
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
        // Add blockchain info if available
        if (offer.transactionHash != null && offer.transactionHash!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.link, size: 14, color: Colors.teal.shade300),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'TX: ${offer.transactionHash!.substring(0, 10)}...',
                  style: TextStyle(
                    color: Colors.teal.shade300,
                    fontSize: 12,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ],
          ),
        ],
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

  void _scrollToBottom() {
  // Use SchedulerBinding to ensure we scroll after the layout is complete
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}

  @override
  void dispose() {
    _blockchainService.removeListener(_onBlockchainStateChanged);
    _stopMessageRefresh();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    
    // Remove visibility observer
    WidgetsBinding.instance.removeObserver(this);
    
    super.dispose();
  }
  
  void _sendMessage() async {
  final text = _messageController.text.trim();
  if (text.isEmpty || _currentChatUser == null) return;
  
  // Create a copy of the text before clearing
  final messageToBeSent = text;
  
  // Clear the text field immediately for better UX
  _messageController.clear();
  
  final now = DateTime.now();
  
  // Add message locally first for immediate feedback
  setState(() {
    _messages.add(ChatMessage(
      text: messageToBeSent,
      isUser: true,
      time: now,
    ));
    
    _updateConversationWithLatestMessage(
      username: _currentChatUser!.username,
      lastMessage: messageToBeSent,
      timestamp: now,
      isTradeOffer: false,
    );
  });
  
  // Scroll to bottom after UI update
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _scrollToBottom();
  });
  
  try {
    // Send the message to the server
    print('Sending message to server: $messageToBeSent');
    final cognitoService = CognitoService();
    final sentMessage = await cognitoService.sendTextMessage(
      recipientUsername: _currentChatUser!.username,
      text: messageToBeSent,
    );
    
    print('Message sent successfully with ID: ${sentMessage.messageId}');
  } catch (e) {
    print('Error sending message: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
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
                  
                  // Show loading indicator
                  setState(() {
                    _isLoadingMessages = true;
                  });
                  
                  // Check if wallet is connected
                  if (!_isWalletConnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please connect your wallet first')),
                    );
                    setState(() {
                      _isLoadingMessages = false;
                    });
                    return;
                  }

                  // Check if on correct network (Holesky testnet has chain ID 17000)
                  if (_currentChainId != 17000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please switch to Holesky testnet')),
                    );
                    
                    // Attempt to switch networks
                    await _switchNetwork(17000);
                    
                    setState(() {
                      _isLoadingMessages = false;
                    });
                    return;
                  }
                  
                  // Create blockchain transaction with BigInt values
                  final energyAmountBigInt = BigInt.from(amount * 1e18);
                  final pricePerUnitBigInt = BigInt.from(price * 1e18);
                  
                  String txHash;
                  if (tradeType == 'sell') {
                    txHash = await _blockchainService.listEnergyForSale(
                      energyAmountBigInt, 
                      pricePerUnitBigInt
                    );
                  } else {
                    // Not implemented yet
                    throw Exception('Buy offers not yet implemented in blockchain service');
                  }
                  
                  // Now send the message through Cognito
                  final cognitoService = CognitoService();
                  final message = await cognitoService.sendTradeOffer(
                    recipientUsername: _currentChatUser!.username,
                    text: "$messageText\nTransaction Hash: $txHash",
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
              _buildWalletButton()
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

Future<void> _respondToOffer(String messageId, String response) async {
    // Show loading indicator
    setState(() {
      _isLoadingMessages = true;
    });
    
    try {
      // Check if wallet is connected
      if (!_isWalletConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please connect your wallet first')),
        );
        setState(() {
          _isLoadingMessages = false;
        });
        return;
      }
      
      // Use Cognito API for the actual response
      final cognitoService = CognitoService();
      final updatedMessage = await cognitoService.respondToTradeOffer(
        messageId: messageId,
        response: response,
      );
      
      // Now refresh messages to show updated status
      await _loadMessageHistory(_currentChatUser!.username);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response == 'accept' 
                ? 'Offer accepted successfully!'
                : 'Offer declined',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: response == 'accept' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoadingMessages = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

void _showCounterOfferDialog(TradeOffer originalOffer) {
    // Pre-populate with original values but allow adjustments
    final amountController = TextEditingController(text: originalOffer.totalAmount.toString());
    final priceController = TextEditingController(text: originalOffer.pricePerUnit.toStringAsFixed(2));
    final descriptionController = TextEditingController(text: 'Here is my counter offer');
    
    // Use original start time but allow changing
    DateTime selectedDate = originalOffer.startTime;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2A0030),
          title: const Text('Counter Offer', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note about counter offer
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'Propose new price or quantity for this trade.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Trade type information (read-only in counter offer)
                const Text('Trade Type:', style: TextStyle(color: Colors.white70)),
                Text(
                  originalOffer.tradeType == 'sell' ? 'Selling Energy' : 'Buying Energy',
                  style: TextStyle(
                    color: originalOffer.tradeType == 'sell' ? Colors.green : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
                          setDialogState(() {
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
                    labelText: 'Message',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
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
                backgroundColor: Colors.blue.shade700,
              ),
              onPressed: () async {
                try {
                  // Check if wallet is connected
                  if (!_isWalletConnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please connect your wallet first')),
                    );
                    return;
                  }
                  
                  // Convert inputs to correct types
                  final amount = int.tryParse(amountController.text);
                  final price = double.tryParse(priceController.text);
                  
                  if (amount == null || price == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter valid numbers')),
                    );
                    return;
                  }
                  
                  // Close dialog before async operations
                  Navigator.pop(dialogContext);
                  
                  // Show loading indicator
                  setState(() {
                    _isLoadingMessages = true;
                  });
                  
                  // Update counter offer in Cognito API
                  final cognitoService = CognitoService();
                  await cognitoService.respondToTradeOffer(
                    messageId: originalOffer.messageId,
                    response: 'counter',
                    pricePerUnit: price,
                    totalAmount: amount,
                    counterText: descriptionController.text,
                  );
                  
                  // Refresh messages
                  await _loadMessageHistory(_currentChatUser!.username);
                  
                  // Show success message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Counter offer sent!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _isLoadingMessages = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sending counter offer: $e')),
                    );
                  }
                }
              },
              child: const Text('Send Counter Offer'),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildWalletButton() {
    if (_isWalletConnected && _currentWalletAddress != null) {
      // Connected state
      String displayAddress = '${_currentWalletAddress!.substring(0, 6)}...${_currentWalletAddress!.substring(_currentWalletAddress!.length - 4)}';
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade800,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: const Icon(
          Icons.account_balance_wallet,
          color: Colors.white,
        ),
        label: Text(
          displayAddress,
          style: const TextStyle(color: Colors.white),
        ),
        onPressed: () {
          // Show wallet details
          _showWalletDetailsDialog(context);
        },
      );
    } else {
      // Disconnected state
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade800,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: const Icon(
          Icons.link,
          color: Colors.white,
        ),
        label: const Text(
          'Connect Wallet',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: _connectWallet,
      );
    }
  }

  void _showWalletDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2A0030),
        title: const Text('Wallet Details', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address: ${_currentWalletAddress ?? "Not Connected"}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Network ID: ${_currentChainId ?? "Unknown"}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Switch to Holesky', style: TextStyle(color: Colors.purple)),
            onPressed: () {
              Navigator.pop(context);
              _switchNetwork(17000); // Holesky testnet
            },
          ),
          TextButton(
            child: const Text('Close', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

// Start message polling
void _startMessagePolling() {
  if (_isPolling) return;
  
  _isPolling = true;
  
  // Set initial last message timestamp if we have messages
  if (_messages.isNotEmpty) {
    _lastMessageTimestamp = _messages.first.time; // First because we reversed the list
  }
  
  // Initial poll immediately
  _pollForNewMessages();
  
  // Schedule regular polling
  _pollingTimer = Timer.periodic(Duration(seconds: _pollingInterval), (timer) {
    _pollForNewMessages();
  });
  
  if (kDebugMode) {
    print('Started message polling at ${_pollingInterval}s intervals');
  }
}

// Stop message polling
void _stopMessagePolling() {
  _pollingTimer?.cancel();
  _pollingTimer = null;
  _isPolling = false;
  
  if (kDebugMode) {
    print('Stopped message polling');
  }
}

// Poll for new messages - optimized to only fetch truly new messages
Future<void> _pollForNewMessages() async {
  if (_currentChatUser == null || _isLoadingMessages) return;
  
  try {
    final cognitoService = CognitoService();
    
    // Get messages after our latest message timestamp
    final messageResponse = await cognitoService.getMessagesBetweenUsers(
      _currentChatUser!.username,
      since: _lastMessageTimestamp,
    );
    
    final currentUserId = widget.userData?['cognito:username'] ?? '';
    
    if (messageResponse.messages.isNotEmpty) {
      // Keep track of existing message IDs to avoid duplicates
      final existingMessageIds = _messages.map((m) => 
        m.offer?.messageId ?? '').toSet();
      
      // Filter out messages we already have
      final newMessages = messageResponse.messages
          .where((msg) => !existingMessageIds.contains(msg.messageId))
          .map((msg) => msg.toChatMessage(currentUserId))
          .toList()
          .reversed
          .toList();
      
      if (newMessages.isNotEmpty) {
        if (kDebugMode) {
          print('Adding ${newMessages.length} new messages');
        }
        
        setState(() {
          // Append only new messages to the existing list
          _messages.addAll(newMessages);
          
          // Update timestamp to the newest message
          _lastMessageTimestamp = newMessages.last.time;
          
          // Update conversation list with the latest message if needed
          final latestMsg = newMessages.last;
          _updateConversationWithLatestMessage(
            username: _currentChatUser!.username,
            lastMessage: latestMsg.text,
            timestamp: latestMsg.time,
            isTradeOffer: latestMsg.type == MessageType.offer,
          );
        });
        
        // Auto-scroll if user was already at the bottom
        if (_isScrolledToBottom()) {
          _scrollToBottom();
        }
      }
      
      // Reset polling interval on successful fetch
      _consecutiveErrorCount = 0;
      _pollingInterval = 3;
      _updatePollingRate();
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error polling for messages: $e');
    }
    
    // Implement exponential backoff for failed requests
    _consecutiveErrorCount++;
    _pollingInterval = min(_pollingInterval * 2, _maxPollingInterval);
    _updatePollingRate();
  }
}

// Update polling rate if needed
void _updatePollingRate() {
  if (_pollingTimer != null && _pollingTimer!.isActive) {
    _stopMessagePolling();
    _startMessagePolling();
  }
}

// Check if user has scrolled to the bottom
bool _isScrolledToBottom() {
  if (!_scrollController.hasClients) return true;
  
  final maxScroll = _scrollController.position.maxScrollExtent;
  final currentScroll = _scrollController.offset;
  // Consider "close enough" to bottom (within 50 pixels)
  return maxScroll - currentScroll <= 50;
}

// Add this to cognito_service.dart
Future<MessageResponse> getMessagesBetweenUsers(String username, {DateTime? since}) async {
  try {
    final token = await CognitoService().getIdToken();
    
    String url = '${ChatConfig.baseUrl}/dev/api/messages/$username';
    
    // Add since parameter if provided
    if (since != null) {
      final sinceParam = since.toUtc().toIso8601String();
      url += '?since=$sinceParam';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MessageResponse.fromJson(data);
    } else {
      throw Exception('Failed to get messages: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error getting messages: $e');
  }
}

@override
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  super.didChangeAppLifecycleState(state);
  print('App lifecycle state changed to: $state');
  
  if (state == AppLifecycleState.resumed) {
    print('App resumed - starting refresh timer');
    if (_currentChatUser != null) {
      _startMessageRefresh();
      // Also do an immediate refresh
      _refreshMessages();
    } else {
      print('Not starting timer because no chat user is selected');
    }
  } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
    print('App paused/inactive - stopping refresh timer');
    _stopMessageRefresh();
  }
}

// Add this method to start the refresh timer
// Update the _startMessageRefresh method
void _startMessageRefresh() {
  // Cancel any existing timer
  _stopMessageRefresh();
  
  print('Starting message refresh timer...');
  
  // Start a new timer that refreshes every 3 seconds
  _isRefreshEnabled = true;
  _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
    print('Timer callback executing'); // Debug log to verify timer is running
    if (_currentChatUser != null && _isRefreshEnabled) {
      print('Refreshing messages for ${_currentChatUser!.username}');
      _refreshMessages();
    } else {
      print('Refresh skipped - currentChatUser: ${_currentChatUser?.username}, isEnabled: $_isRefreshEnabled');
    }
  });
  
  print('Message refresh timer started with interval: 3s');
}

// Add this method to stop the refresh timer
void _stopMessageRefresh() {
  _refreshTimer?.cancel();
  _refreshTimer = null;
  _isRefreshEnabled = false;
  
  if (kDebugMode) {
    print('Stopped message refresh timer');
  }
}

// Add this method to refresh messages without clearing the UI
Future<void> _refreshMessages() async {
  if (_currentChatUser == null || _isLoadingMessages) {
    print('Refresh aborted - chat user null or loading in progress');
    return;
  }
  
  try {
    print('Starting message refresh for ${_currentChatUser!.username}');
    final cognitoService = CognitoService();
    final messageResponse = await cognitoService.getMessagesBetweenUsers(_currentChatUser!.username);
    
    final currentUserId = widget.userData?['cognito:username'] ?? '';
    debugPrint('Messages: ${messageResponse.messages[0].text}');
    debugPrint('Messages length: ${messageResponse.messages.length}');
    final updatedMessages = messageResponse.messages
        .map((msg) => msg.toChatMessage(currentUserId))
        .toList()
        .reversed
        .toList();
        
    print('Retrieved ${updatedMessages.length} messages, current count: ${_messages.length}');
    
    bool shouldUpdate = false;
    
    // Check if there are new messages
    if (updatedMessages.length > _messages.length) {
      _scrollToBottom();
      shouldUpdate = true;
      print('Found ${updatedMessages.length - _messages.length} new messages');
    } 
    // Check for message content changes (like offer status)
    else if (updatedMessages.length == _messages.length) {
      for (int i = 0; i < updatedMessages.length; i++) {
        if (i < _messages.length &&
            updatedMessages[i].messageId != null && 
            _messages[i].messageId != null &&
            updatedMessages[i].messageId == _messages[i].messageId) {
          // Check for offer status changes
          if (updatedMessages[i].offer?.status != _messages[i].offer?.status) {
            print('Message ${updatedMessages[i].messageId}: Offer status changed from ${_messages[i].offer?.status} to ${updatedMessages[i].offer?.status}');
            shouldUpdate = true;
            break;
          }
        }
      }
    }
        
    if (shouldUpdate) {
      print('Updating messages UI with latest data');
      
      // Remember if we were at the bottom before update
      bool wasAtBottom = _isScrolledToBottom();
      
      // Use mounted check before setState to avoid errors
      if (mounted) {
        setState(() {
          _messages = updatedMessages;
          
          // Get the most recent message to update sidebar
          if (updatedMessages.isNotEmpty) {
            final latestMessage = updatedMessages.last;
            
            // Update conversation sidebar with latest message info
            _updateConversationWithLatestMessage(
              username: _currentChatUser!.username,
              lastMessage: latestMessage.text,
              timestamp: latestMessage.time,
              isTradeOffer: latestMessage.type == MessageType.offer,
            );
          }
        });
        
        // Auto-scroll if user was already at the bottom
        if (wasAtBottom) {
          //_scrollToBottom();
        }
      }
    } else {
      print('No message updates needed');
    }
  } catch (e) {
    print('Error refreshing messages: $e');
  }
}

// Update _sendTradeOffer to use Cognito API
Future<void> _sendTradeOffer({
  required String text,
  required double price,
  required int amount,
  required DateTime startTime,
  required String tradeType,
}) async {
  try {
    // Check if wallet is connected (for UI only)
    final walletConnected = _blockchainService.isConnected;
    if (!walletConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your wallet first')),
      );
      return;
    }

    setState(() {
      _isLoadingMessages = true;
    });
    
    // Send the message through Cognito API
    final cognitoService = CognitoService();
    final message = await cognitoService.sendTradeOffer(
      recipientUsername: _currentChatUser!.username,
      text: text,
      pricePerUnit: price,
      startTime: startTime,
      totalAmount: amount,
      tradeType: tradeType,
    );
    
    // Get current user ID for the message conversion
    final userData = await cognitoService.getUserInfo();
    final currentUserId = userData?['cognito:username'] ?? '';
    
    setState(() {
      _isLoadingMessages = false;
      _messages.add(message.toChatMessage(currentUserId));
      
      // Update conversation with trade offer
      _updateConversationWithLatestMessage(
        username: _currentChatUser!.username,
        lastMessage: text,
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
  } catch (e) {
    setState(() {
      _isLoadingMessages = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error creating offer: $e')),
    );
  }
}

// Connect wallet method
Future<void> _connectWallet() async {
  try {
    final success = await _blockchainService.connectWallet();
    
    if (success) {
      setState(() {
        _isWalletConnected = true;
        _currentWalletAddress = _blockchainService.currentAddress;
        _currentChainId = _blockchainService.currentChainId;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet connected successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect wallet')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error connecting wallet: $e')),
    );
  }
}

// Network switching method
Future<void> _switchNetwork(int targetChainId) async {
  try {
    final success = await _blockchainService.switchNetwork(targetChainId);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to switch network')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error switching network: $e')),
    );
  }
}

// Helper method for creating energy offers on the blockchain
Future<String> _createBlockchainEnergyOffer({
  required int amount,
  required double pricePerUnit,
  required bool isSelling,
}) async {
  // Check wallet connection
  if (!_isWalletConnected) {
    throw Exception('Wallet not connected');
  }
  
  // Check network
  if (_currentChainId != 17000) { // Holesky testnet
    throw Exception('Please switch to Holesky testnet (ID: 17000)');
  }
  
  // Convert to appropriate format for blockchain (assuming energy amount and price as BigInt with 18 decimals)
  final energyAmountBigInt = BigInt.from(amount * 1e18);
  final pricePerUnitBigInt = BigInt.from(pricePerUnit * 1e18);
  
  String txHash;
  if (isSelling) {
    txHash = await _blockchainService.listEnergyForSale(
      energyAmountBigInt, 
      pricePerUnitBigInt
    );
  } else {
    // This would need to be implemented in blockchain_service.dart
    throw Exception('Buy offers not yet implemented in blockchain service');
  }
  
  return txHash;
}
}