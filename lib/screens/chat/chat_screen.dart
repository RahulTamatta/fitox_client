import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../themes/app_theme.dart';
// import '../../providers/subscription_provider.dart'; // Commented out for testing
import '../../models/chat_message.dart';
import '../../bloc/chat/chat_bloc.dart';
import '../../bloc/chat/chat_event.dart';
import '../../bloc/chat/chat_state.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String userId;
  final String? userName;
  final String? userImage;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.userId,
    this.userName,
    this.userImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider(
      create:
          (_) =>
              ChatBloc()..add(
                ChatStarted(
                  currentUserId: _currentUserId!,
                  otherUserId: widget.userId,
                ),
              ),
      child: Scaffold(
        backgroundColor: AppTheme.primaryColor,
        appBar: _buildAppBar(),
        body: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatLoading || state is ChatInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ChatError) {
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.red,
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }

            final loaded = state as ChatLoaded;
            final messages = loaded.messages;

            return Column(
              children: [
                Expanded(
                  child:
                      messages.isEmpty
                          ? const Center(
                            child: Text(
                              'No messages yet. Start the conversation!',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            reverse: true,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final reversedIndex = messages.length - 1 - index;
                              return _buildMessageBubble(
                                messages[reversedIndex],
                              );
                            },
                          ),
                ),
                _buildMessageInputBarBloc(context),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              String? displayImage = widget.userImage;

              // Use fetched user info image if available
              if (state is ChatLoaded && state.otherUserInfo != null) {
                displayImage =
                    state.otherUserInfo!.profileImage ?? widget.userImage;
              }

              final bool hasValidImage =
                  displayImage != null && displayImage.isNotEmpty;

              return CircleAvatar(
                backgroundImage:
                    hasValidImage
                        ? NetworkImage(displayImage!)
                        : const NetworkImage(
                          "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1280&q=80",
                        ),
                radius: 18,
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                String displayName = widget.userName ?? "User";

                // Use fetched user info if available
                if (state is ChatLoaded && state.otherUserInfo != null) {
                  displayName = state.otherUserInfo!.name;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      state is ChatLoaded && state.otherUserTyping
                          ? "Typing..."
                          : "Online",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMe ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                message.isMe
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
            bottomRight:
                message.isMe
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: TextStyle(
                    color: message.isMe ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                if (message.isMe) ...[
                  const SizedBox(width: 4),
                  _buildMessageStatusIcon(message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 14, color: Colors.white70);
      case MessageStatus.sent:
        return Icon(Icons.check, size: 14, color: Colors.white70);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 14, color: Colors.white70);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 14, color: Colors.blue);
      case MessageStatus.failed:
        return Icon(Icons.error_outline, size: 14, color: Colors.red.shade300);
    }
  }

  Widget _buildMessageInputBarBloc(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.emoji_emotions, color: AppTheme.primaryColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.attach_file, color: AppTheme.primaryColor),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (text) {
                // Send typing indicator when user starts/stops typing
                if (text.isNotEmpty) {
                  context.read<ChatBloc>().add(ChatTypingChanged(true));
                } else {
                  context.read<ChatBloc>().add(ChatTypingChanged(false));
                }
              },
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  context.read<ChatBloc>().add(ChatMessageSent(text.trim()));
                  _messageController.clear();
                }
              },
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: AppTheme.primaryColor),
            onPressed: () async {
              if (_messageController.text.trim().isNotEmpty) {
                final text = _messageController.text.trim();
                _messageController.clear();
                context.read<ChatBloc>().add(ChatMessageSent(text));
              }
            },
            // COMMENTED OUT SUBSCRIPTION CHECK FOR TESTING
            // onPressed: subscriptionProvider.isActive
            //     ? () async {
            //         if (_messageController.text.trim().isNotEmpty) {
            //           final text = _messageController.text.trim();
            //           _messageController.clear();
            //
            //           // Send via chat provider if subscription is active
            //           await chatProvider.sendMessage(text);
            //         }
            //       }
            //     : () {
            //         // Show subscription prompt
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           const SnackBar(
            //             content: Text('Subscribe to send messages'),
            //             backgroundColor: Colors.orange,
            //           ),
            //         );
            //       },
          ),
        ],
      ),
    );
  }
}
