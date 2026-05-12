import 'package:hive/hive.dart';

part 'video_model.g.dart';

@HiveType(typeId: 0)
class VideoModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String channelName;
  @HiveField(3)
  final int durationInSeconds;
  @HiveField(4)
  final String thumbnailUrl;
  @HiveField(5)
  final String? author;

  VideoModel({
    required this.id,
    required this.title,
    required this.channelName,
    required this.durationInSeconds,
    required this.thumbnailUrl,
    this.author,
  });

  Duration get duration => Duration(seconds: durationInSeconds);

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['id'] as String,
      title: map['title'] as String,
      channelName: map['channelName'] as String,
      thumbnailUrl: (map['thumbnailUrl'] as String?) ?? '',
      durationInSeconds: (map['durationInSeconds'] as int?) ?? 0,
      author: map['author'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'channelName': channelName,
      'thumbnailUrl': thumbnailUrl,
      'durationInSeconds': durationInSeconds,
      'author': author,
    };
  }

  VideoModel copyWith({
    String? id,
    String? title,
    String? channelName,
    String? thumbnailUrl,
    int? durationInSeconds,
    String? author,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      channelName: channelName ?? this.channelName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      author: author ?? this.author,
    );
  }

  @override
  String toString() {
    return 'VideoModel(id: $id, title: $title, channelName: $channelName, thumbnailUrl: $thumbnailUrl, durationInSeconds: $durationInSeconds, author: $author)';
  }
}
