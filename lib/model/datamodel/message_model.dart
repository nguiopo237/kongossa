
import 'dart:convert';

Messagemodel messagemodelFromJson(String str) => Messagemodel.fromJson(json.decode(str));

String messagemodelToJson(Messagemodel data) => json.encode(data.toJson());

class Messagemodel {
  String? content;
  String? messageType;
  String? id;
  String? receiveId;
  String? senderId;
  bool? isRead;
  DateTime? timestamp;

  Messagemodel({
    this.content,
    this.id,
    this.messageType = "text",
    this.receiveId,
    this.senderId,
    this.isRead,
    this.timestamp,
  });

  factory Messagemodel.fromJson(Map<String, dynamic> json) => Messagemodel(
    content: json["content"],
    id: json["id"],
    receiveId: json["receiveId"],
    senderId: json["senderId"],
    timestamp: json["timestamp"],
    messageType: json["messageType"],
    isRead: json["isRead"],
  );

  Map<String, dynamic> toJson() => {
    "content": content,
    "id": id,
    "messageType": messageType,
    "receiveId": receiveId,
    "senderId": senderId,
    "timestamp": timestamp,
  };
}


class MessageGroup {
  final String title;
  final List<Messagemodel> messages;

  MessageGroup({
    required this.title,
    required this.messages,
  });
}


class MessageService {
  static List<MessageGroup> groupMessagesByDate(List<Messagemodel> messages) {
    messages.sort((a, b) => a.timestamp!.compareTo( b.timestamp!));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    Map<String, List<Messagemodel>> groupedMessages = {};

    for (var message in messages) {
      final messageDate = DateTime(
        message.timestamp!.year,
        message.timestamp!.month,
        message.timestamp!.day,
      );

      String groupTitle;

      if (messageDate == today) {
        groupTitle = "Aujourd'hui";
      } else if (messageDate == yesterday) {
        groupTitle = 'Hier';
      } else if (messageDate == tomorrow) {
        groupTitle = 'Demain';
      } else {
        groupTitle = _formatDate(messageDate);
      }

      if (!groupedMessages.containsKey(groupTitle)) {
        groupedMessages[groupTitle] = [];
      }
      groupedMessages[groupTitle]!.add(message);
    }

    return groupedMessages.entries.map((entry) {
      return MessageGroup(
        title: entry.key,
        messages: entry.value,
      );
    }).toList();
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
 }
 }