import 'dart:convert';
import 'package:education_app/core/utils/typedefs.dart';
import 'package:http/http.dart' as http;

class YoutubeMetadataData {
  YoutubeMetadataData({
    this.title,
    this.authorName,
    this.thumbnailUrl,
  });
  final String? title;
  final String? authorName;
  final String? thumbnailUrl;
}

class YoutubeMetadata {
  static Future<YoutubeMetadataData> getData(String url) async {
    final uri = Uri.parse(
      'https://www.youtube.com/oembed?url=$url&format=json',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load metadata');
    }

    final json = jsonDecode(response.body) as DataMap;

    return YoutubeMetadataData(
      title: json['title'] as String?,
      authorName: json['author_name'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
}
