import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:flash_chat/components/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  static const String id = 'ChatScreen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextEditingController = TextEditingController();
  FirebaseUser loggedInUser;
  final _fireStore = Firestore.instance;
  final _authenticate = FirebaseAuth.instance;
  String messages;
  @override
  void initState() {
    super.initState();

    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _authenticate.currentUser();
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }
//
//  void getMessages() async {
//    final messages = await _fireStore.collection('messages').getDocuments();
//    for (var message in messages.documents) {
//      print(message.data);
//      // prints the message data in console
//      // adding that to the screen so that user can have a look
//    }
//  }
//
//  void messagesStream() async {
//    await for (var snapshot in _fireStore.collection('messages').snapshots()) {
//      for (var message in snapshot.documents) {
//        print(message.data);
//      }
//    }
//  }
  bool isMe = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                _authenticate.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MessageStream(fireStore: _fireStore, loggedInUser: loggedInUser),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: messageTextEditingController,
                        onChanged: (value) {
                          //Do something with the user input.
                          messages = value;
                        },
                        decoration: kMessageTextFieldDecoration,
                      ),
                    ),
                    FlatButton(
                      onPressed: () {
                        // clears the sending field
                        messageTextEditingController.clear();

                        //Implement send functionality.

                        // this adds code to the firebase
                        _fireStore.collection('messages').add({
                          'text': messages,
                          'sender': loggedInUser.email,
                        });
                      },
                      child: Text(
                        'Send',
                        style: kSendButtonTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  const MessageStream({
    Key key,
    @required Firestore fireStore,
    @required this.loggedInUser,
    @required this.isMe,
  }) : _fireStore = fireStore, super(key: key);

  final Firestore _fireStore;
  final FirebaseUser loggedInUser;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore.collection('messages').snapshots(),
      builder: (context, snapshot) {
        List<MessageBubble> messageBubbleList = [];
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data.documents.reversed;
        for (var message in messages) {
          final messageSender = message.data['sender'];
          final messageText = message.data['text'];
          final currentUser = loggedInUser.email;
          final messageBubble = MessageBubble(
            messageSender: messageSender,
            messageText: messageText,
            isMe: currentUser == messageSender,
          );
          messageBubbleList.add(messageBubble);
        }

        // ListView made it scrollable accomapnied by the keyboard
        return Expanded(
          child: ListView(
            reverse: true,
            children: messageBubbleList,
          ),
        );
      },
    );
  }
}
