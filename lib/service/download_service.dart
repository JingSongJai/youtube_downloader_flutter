import 'dart:developer';
import 'dart:io';

import 'package:youtube_downloader/main.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadService {
  static final yt = YoutubeExplode();
  static Video? video;
  static StreamManifest? manifest;

  static Future<Video?> getVideoInformation(String url) async {
    video = await yt.videos.get(url);

    return video;
  }

  static Future<List<StreamInfo>> getVideoContents(String url) async {
    manifest = await yt.videos.streams.getManifest(
      url,
      ytClients: [YoutubeApiClient.ios, YoutubeApiClient.androidVr],
    );

    log('$manifest');

    return manifest?.streams.toList() ?? [];
  }

  static Future<void> download(String url, int tag) async {
    if (video != null && manifest != null) {
      var streamInfo = manifest!.streams.where((stream) => stream.tag == tag);
      final totalSize = streamInfo.single.size.totalBytes;

      log('Downloading...');
      final stream = yt.videos.streams.get(streamInfo.single);

      var file = File(
        '$path/${video!.title}.${streamInfo.single.container.name}',
      );
      var fileStream = file.openWrite();

      int downloaded = 0;

      await for (final data in stream) {
        downloaded += data.length;
        final progress = (downloaded / totalSize) * 100;
        log('Progress: ${progress.toStringAsFixed(2)}%');

        fileStream.add(data);
      }

      await fileStream.flush();
      await fileStream.close();

      log('Download Completed!');

      yt.close();
    }
  }
}
