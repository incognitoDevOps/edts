import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/ChatVideoContainer.dart';
import 'package:customer/model/conversation_model.dart';
import 'package:customer/model/inbox_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/ui/chat_screen/FullScreenImageViewer.dart';
import 'package:customer/ui/chat_screen/FullScreenVideoViewer.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/firebase_pagination/src/firestore_pagination.dart';
import 'package:customer/widget/firebase_pagination/src/models/view_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ChatScreens extends StatefulWidget {
  final String? orderId;
  final String? customerId;
  final String? customerName;
  final String? customerProfileImage;
  final String? driverId;
  final String? driverName;
  final String? driverProfileImage;
  final String? token;

  const ChatScreens({Key? key, this.orderId, this.customerId, this.customerName, this.driverName, this.driverId, this.customerProfileImage, this.driverProfileImage, this.token}) : super(key: key);

  @override
  State<ChatScreens> createState() => _ChatScreensState();
}

class _ChatScreensState extends State<ChatScreens> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _controller = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollListener);
    if (_controller.hasClients) {
      Timer(const Duration(milliseconds: 500), () => _controller.jumpTo(_controller.position.maxScrollExtent));
    }
  }

  void _scrollListener() {
    if (!mounted) return;
    if (_controller.hasClients) {
      final atBottom = _controller.offset >= _controller.position.maxScrollExtent - 50;
      if (_showScrollToBottom != !atBottom) {
        setState(() {
          _showScrollToBottom = !atBottom;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_scrollListener);
    _controller.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.driverProfileImage ?? ''),
              radius: 18,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.driverName ?? '', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('#${widget.orderId}', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        leading: InkWell(
            onTap: () {
              Get.back();
            },
            child: const Icon(
              Icons.arrow_back,
            )),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF232526), const Color(0xFF414345)]
                : [const Color(0xFFF8F8F8), const Color(0xFFEDEDED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8, bottom: 8),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() {});
                      },
                      child: FirestorePagination(
                        controller: _controller,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, documentSnapshots, index) {
                          ConversationModel inboxModel = ConversationModel.fromJson(documentSnapshots[index].data() as Map<String, dynamic>);
                          final isMe = inboxModel.senderId == FireStoreUtils.getCurrentUid();
                          final isFirst = index == 0 || (ConversationModel.fromJson(documentSnapshots[index - 1].data() as Map<String, dynamic>).senderId != inboxModel.senderId);
                          return chatItemView(isMe, inboxModel, isFirst);
                        },
                        onEmpty: Center(child: Text("No Conversation found".tr)),
                        query: FirebaseFirestore.instance.collection('chat').doc(widget.orderId).collection("thread").orderBy('createdAt', descending: false),
                        viewType: ViewType.list,
                        isLive: true,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              _onCameraClick();
                            },
                            icon: const Icon(Icons.camera_alt),
                            color: AppColors.primary,
                          ),
                          Expanded(
                            child: TextField(
                              textInputAction: TextInputAction.send,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.sentences,
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Start typing ...'.tr,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                              ),
                              onSubmitted: (value) async {
                                if (_messageController.text.isNotEmpty) {
                                  _sendMessage(_messageController.text, null, '', 'text');
                                  Timer(const Duration(milliseconds: 500), () => _controller.jumpTo(_controller.position.maxScrollExtent));
                                  _messageController.clear();
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              if (_messageController.text.isNotEmpty) {
                                _sendMessage(_messageController.text, null, '', 'text');
                                _messageController.clear();
                                setState(() {});
                              } else {
                                ShowToastDialog.showToast("Please enter text".tr);
                              }
                            },
                            icon: const Icon(Icons.send_rounded),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showScrollToBottom)
              Positioned(
                right: 20,
                bottom: 80,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: AppColors.primary,
                  onPressed: () {
                    _controller.animateTo(
                      _controller.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Icon(Icons.arrow_downward, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget chatItemView(bool isMe, ConversationModel data, bool isFirst) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final avatarUrl = isMe ? widget.customerProfileImage : widget.driverProfileImage;
    final name = isMe ? "Me".tr : widget.driverName ?? '';
    final bubbleColor = isMe ? (isDark ? AppColors.darkModePrimary : AppColors.primary) : (isDark ? Colors.grey[800] : Colors.white);
    final textColor = isMe ? (isDark ? Colors.black : Colors.white) : Colors.black87;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          );
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 16 : 4,
        bottom: 4,
        left: isMe ? 40 : 8,
        right: isMe ? 8 : 40,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(avatarUrl ?? ''),
                radius: 18,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: align,
              children: [
                if (isFirst && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0, left: 2),
                    child: Text(
                      name,
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: _buildMessageContent(data, textColor),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0, left: 2, right: 2),
                  child: Text(
                    Constant.dateAndTimeFormatTimestamp(data.createdAt),
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(avatarUrl ?? ''),
                radius: 18,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ConversationModel data, Color textColor) {
    if (data.messageType == "text") {
      return Text(
        data.message.toString(),
        style: GoogleFonts.poppins(color: textColor, fontSize: 15),
      );
    } else if (data.messageType == "image") {
      return GestureDetector(
        onTap: () {
          Get.to(FullScreenImageViewer(
            imageUrl: data.url!.url,
          ));
        },
        child: Hero(
          tag: data.url!.url,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: data.url!.url,
              width: 180,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (context, url) => Constant.loader(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
      );
    } else if (data.messageType == "video") {
      return GestureDetector(
        onTap: () {
          Get.to(FullScreenVideoViewer(
            heroTag: data.id.toString(),
            videoUrl: data.url!.url,
          ));
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: data.videoThumbnail ?? '',
                width: 180,
                height: 180,
                fit: BoxFit.cover,
                placeholder: (context, url) => Constant.loader(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  _sendMessage(String message, Url? url, String videoThumbnail, String messageType) async {
    InboxModel inboxModel = InboxModel(
        lastSenderId: widget.customerId,
        customerId: widget.customerId,
        customerName: widget.customerName,
        driverId: widget.driverId,
        driverName: widget.driverName,
        driverProfileImage: widget.driverProfileImage,
        createdAt: Timestamp.now(),
        orderId: widget.orderId,
        customerProfileImage: widget.customerProfileImage,
        lastMessage: _messageController.text);

    await FireStoreUtils.addInBox(inboxModel);

    ConversationModel conversationModel = ConversationModel(
        id: const Uuid().v4(),
        message: message,
        senderId: FireStoreUtils.getCurrentUid(),
        receiverId: widget.driverId,
        createdAt: Timestamp.now(),
        url: url,
        orderId: widget.orderId,
        messageType: messageType,
        videoThumbnail: videoThumbnail);

    if (url != null) {
      if (url.mime.contains('image')) {
        conversationModel.message = "sent an image";
      } else if (url.mime.contains('video')) {
        conversationModel.message = "sent an Video";
      } else if (url.mime.contains('audio')) {
        conversationModel.message = "Sent a voice message";
      }
    }

    await FireStoreUtils.addChat(conversationModel);

    Map<String, dynamic> playLoad = <String, dynamic>{
      "type": "chat",
      "driverId": widget.driverId,
      "customerId": widget.customerId,
      "orderId": widget.orderId,
    };

    SendNotification.sendOneNotification(
        title: "${widget.customerName} ${messageType == "image" ? messageType == "video" ? "sent video to you" : "sent image to you" : "sent message to you"}",
        body: conversationModel.message.toString(),
        token: widget.token.toString(),
        payload: playLoad);
  }

  final ImagePicker _imagePicker = ImagePicker();

  _onCameraClick() {
    final action = CupertinoActionSheet(
      message: Text(
        'Send Media'.tr,
        style: const TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Get.back();
            XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              Url url = await Constant().uploadChatImageToFireStorage(File(image.path));
              _sendMessage('', url, '', 'image');
            }
          },
          child: Text("Choose image from gallery".tr),
        ),
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? galleryVideo = await _imagePicker.pickVideo(source: ImageSource.gallery);
            if (galleryVideo != null) {
              ChatVideoContainer videoContainer = await Constant().uploadChatVideoToFireStorage(File(galleryVideo.path));
              _sendMessage('', videoContainer.videoUrl, videoContainer.thumbnailUrl, 'video');
            }
          },
          child: Text("Choose video from gallery".tr),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
            if (image != null) {
              Url url = await Constant().uploadChatImageToFireStorage(File(image.path));
              _sendMessage('', url, '', 'image');
            }
          },
          child: Text("Take a Photo".tr),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? recordedVideo = await _imagePicker.pickVideo(source: ImageSource.camera);
            if (recordedVideo != null) {
              ChatVideoContainer videoContainer = await Constant().uploadChatVideoToFireStorage(File(recordedVideo.path));
              _sendMessage('', videoContainer.videoUrl, videoContainer.thumbnailUrl, 'video');
            }
          },
          child: Text("Record video".tr),
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text(
          'Cancel'.tr,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }
}
