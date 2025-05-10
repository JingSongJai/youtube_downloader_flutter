import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_min_gpl/statistics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:youtube_downloader/main.dart';
import 'package:youtube_downloader/routes/app_routes.dart';
import 'package:youtube_downloader/service/download_service.dart';

class HomeController extends GetxController with GetTickerProviderStateMixin {
  final urlTextController = TextEditingController();
  final url = ''.obs, title = ''.obs, desc = ''.obs;
  Duration? duration;
  DateTime? uploadDate;
  final isLoading = false.obs;
  final isDownloading = false.obs;
  final isMixing = false.obs;
  final isGenerating = false.obs;
  var contents = [].obs;
  var audioes = [].obs;
  final progress = 0.0.obs;
  final downloadedTag = 0.obs;
  final downloadState = ''.obs;
  TabController? tabController1;
  TabController? tabController2;
  late StreamSubscription _intentSub;
  final _sharedFiles = <SharedMediaFile>[];

  Future<void> getVideoInformation() async {
    log('Getting video information...');
    try {
      if (urlTextController.text.isEmpty) return;

      isGenerating.value = true;
      final video = await DownloadService.getVideoInformation(
        urlTextController.text,
      );

      contents.value = await DownloadService.getVideoContents(
        urlTextController.text,
      );

      audioes.value =
          contents.where((content) => content.codec.type == 'audio').toList();
      log(audioes.length.toString());

      // filter videos
      contents.removeWhere(
        (element) =>
            element.container.name == 'm3u8' ||
            element.container.name == 'webm' ||
            !element.codec.parameters['codecs'].contains('avc1'),
      );

      if (video != null) {
        url.value = video.thumbnails.highResUrl;
        title.value = video.title;
        desc.value = video.description;
        duration = video.duration;
        uploadDate = video.uploadDate;
      }

      isGenerating.value = false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        return true;
      }

      if (Platform.version.contains('11') ||
          Platform.version.contains('12') ||
          Platform.version.contains('13')) {
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      }
    }

    return false;
  }

  Future<void> downloadVideo(String url, int tag) async {
    if (await checkPermission() == PermissionStatus.denied) return;

    if (DownloadService.video != null && DownloadService.manifest != null) {
      isDownloading.value = true;
      downloadedTag.value = tag;
      downloadState.value = 'Downloading video...';
      try {
        var videoInfo = DownloadService.manifest!.streams.where(
          (stream) => stream.tag == tag,
        );
        final totalSize = videoInfo.single.size.totalBytes;

        var audioInfo = DownloadService.manifest!.streams.firstWhere(
          (stream) =>
              (stream.codec.parameters['codecs'] ?? '').contains('mp4a') &&
              stream.codec.type == 'audio',
        );

        // log('Total : ${audioInfo.length}');

        final totalAudioSize = audioInfo.size.totalBytes;

        log('Size : $totalAudioSize');

        log('Downloading...');
        final videoStream = DownloadService.yt.videos.streams.get(
          videoInfo.single,
        );
        final audioStream = DownloadService.yt.videos.streams.get(audioInfo);

        String resolution =
            contents
                .where((content) => content.tag == downloadedTag.value)
                .toList()
                .single
                .qualityLabel
                .toString();
        String videoFileName =
            '${tempPath?.path}/${DownloadService.video!.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '')} ($resolution).${videoInfo.single.container.name}'
                .trim();
        String audioFileName =
            '${tempPath?.path}/${DownloadService.video!.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '')}.${audioInfo.container.name}'
                .trim();

        var file1 = File(videoFileName);
        var file2 = File(audioFileName);
        var fileStream1 = file1.openWrite();
        var fileStream2 = file2.openWrite();

        int downloaded = 0;

        await for (final data in videoStream) {
          downloaded += data.length;
          progress.value = (downloaded / totalSize);
          log('Progress: ${progress.toStringAsFixed(2)}%');

          fileStream1.add(data);
        }

        await fileStream1.flush();
        await fileStream1.close();

        downloaded = 0;
        downloadState.value = 'Downloading audio...';

        await for (final data in audioStream) {
          downloaded += data.length;
          progress.value = (downloaded / totalAudioSize);
          log('Progress: ${progress.toStringAsFixed(2)}%');

          fileStream2.add(data);
        }

        await fileStream2.flush();
        await fileStream2.close();

        log('Download Completed!');
        await muxVideoAndAudio(videoFileName, audioFileName);
        Get.snackbar(
          'Success',
          'Download Successfully! Your files is stored in Download folder.',
          backgroundColor: Color(0xFFFFFDF6),
          animationDuration: 300.milliseconds,
          borderRadius: 10,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          e.toString(),
          backgroundColor: Color(0xFFFFFDF6),
          animationDuration: 300.milliseconds,
          borderRadius: 10,
        );
      }
      progress.value = 0;
      isDownloading.value = false;

      // DownloadService.yt.close();
    }
  }

  Future<void> downloadAudio(String bitrate, int index) async {
    if (await checkPermission() == PermissionStatus.denied) return;

    try {
      isDownloading.value = true;
      downloadState.value = 'Downloading audio...';
      downloadedTag.value = index;
      var audioInfo = DownloadService.manifest!.streams.firstWhere(
        (stream) =>
            (stream.codec.parameters['codecs'] ?? '').contains('mp4a') &&
            stream.codec.type == 'audio',
      );

      final totalAudioSize = audioInfo.size.totalBytes;

      log('Downloading...');
      final audioStream = DownloadService.yt.videos.streams.get(audioInfo);

      String audioFileName =
          '${tempPath?.path}/${DownloadService.video!.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '')}.${audioInfo.container.name}'
              .trim();

      var file2 = File(audioFileName);
      var fileStream2 = file2.openWrite();

      int downloaded = 0;

      await for (final data in audioStream) {
        downloaded += data.length;
        progress.value = (downloaded / totalAudioSize);
        log('Progress: ${progress.toStringAsFixed(2)}%');

        fileStream2.add(data);
      }

      await fileStream2.flush();
      await fileStream2.close();

      log('Download Completed!');
      await convertToMp3(audioFileName, bitrate);
      if (WidgetsBinding.instance.window.defaultRouteName != AppRoute.dialog) {
        Get.snackbar(
          'Success',
          'Download Successfully! Your files is stored in Download folder.',
          backgroundColor: Color(0xFFFFFDF6),
          animationDuration: 300.milliseconds,
          borderRadius: 10,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Color(0xFFFFFDF6),
        animationDuration: 300.milliseconds,
        borderRadius: 10,
      );
    }
    isDownloading.value = false;
    progress.value = 0;
  }

  Future<void> muxVideoAndAudio(
    String videoFilePath,
    String audioFilePath,
  ) async {
    if (await checkPermission() == PermissionStatus.denied) return;
    isMixing.value = true;
    downloadState.value = 'Preparing to merge...';

    final videoFile = File(videoFilePath);
    final audioFile = File(audioFilePath);

    if (!videoFile.existsSync() || !audioFile.existsSync()) {
      log('Files do not exist');
      return;
    }

    String outputFile = DownloadService.video!.title.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '',
    );

    final safeVideoPath = '$path/temp_video.mp4';
    final safeAudioPath = '$path/temp_audio.m4a';
    final outputPath = '$path/$outputFile-yd.mp4';

    await videoFile.copy(safeVideoPath);
    await audioFile.copy(safeAudioPath);

    // Get video duration
    final totalDuration = await getDurationInSeconds(safeVideoPath);

    final command =
        '-y -i "$safeVideoPath" -i "$safeAudioPath" -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -shortest "$outputPath"';

    // Setup FFmpeg progress callback
    FFmpegKitConfig.enableStatisticsCallback((stats) {
      final timeMs = stats.getTime();
      final timeSec = (timeMs ?? 0) / 1000.0;

      if (totalDuration > 0) {
        final percent = (timeSec / totalDuration * 100)
            .clamp(0, 100)
            .toStringAsFixed(1);
        downloadState.value = 'Merging... $percent%';
        log('Muxing progress: $percent%');
      }
    });

    log('Executing FFmpeg command: $command');
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    // Clear callback
    FFmpegKitConfig.enableStatisticsCallback(null);

    if (ReturnCode.isSuccess(returnCode)) {
      await Future.wait([
        if (File(safeVideoPath).existsSync()) File(safeVideoPath).delete(),
        if (File(safeAudioPath).existsSync()) File(safeAudioPath).delete(),
        if (File(videoFilePath).existsSync()) File(videoFilePath).delete(),
        if (File(audioFilePath).existsSync()) File(audioFilePath).delete(),
      ]);
    } else {
      log('Muxing failed with return code: $returnCode');
      Get.snackbar(
        'Error',
        'Muxing failed with return code: $returnCode',
        backgroundColor: Color(0xFFFFFDF6),
        animationDuration: 300.milliseconds,
        borderRadius: 10,
      );
      final logs = await session.getAllLogs();
      for (var log in logs) {
        debugPrint(log.getMessage());
      }
    }

    isMixing.value = false;
  }

  Future<void> convertToMp3(String inputFilePath, String bitrate) async {
    String outputFile = DownloadService.video!.title.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '',
    );

    downloadState.value = 'Converting to audio...';
    final outputPath = '$path/$outputFile-yd-$bitrate.m4a';

    // Get duration
    final totalDuration = await getDurationInSeconds(inputFilePath);

    final command =
        "-y -i '$inputFilePath' -vn -ar 44100 -ac 2 -b:a ${bitrate}k '$outputPath'";

    // Track progress
    FFmpegKitConfig.enableStatisticsCallback((Statistics stats) {
      final timeMs = stats.getTime();
      final timeSec = (timeMs ?? 0) / 1000.0;

      if (totalDuration > 0) {
        final percent = (timeSec / totalDuration * 100)
            .clamp(0, 100)
            .toStringAsFixed(1);
        downloadState.value = 'Converting... $percent%';
        log('Progress: $percent%');
      }
    });

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      log('Conversion complete: $outputPath');
      if (File(inputFilePath).existsSync()) {
        await File(inputFilePath).delete();
      }
    } else {
      log('Conversion failed with return code: $returnCode');
      final logs = await session.getAllLogs();
      for (var logEntry in logs) {
        debugPrint(logEntry.getMessage());
      }
    }

    FFmpegKitConfig.enableStatisticsCallback(null);
  }

  Future<double> getDurationInSeconds(String filePath) async {
    final session = await FFprobeKit.getMediaInformation(filePath);
    final info = session.getMediaInformation();
    final duration = info?.getDuration();
    return double.tryParse(duration ?? '0') ?? 0;
  }

  @override
  void onInit() {
    tabController1 = TabController(length: 2, vsync: this);
    tabController2 = TabController(length: 2, vsync: this);
    // Listen to media sharing coming from outside the app while the app is in the memory.
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (value) async {
        _sharedFiles.clear();
        _sharedFiles.addAll(value);
        if (value.isNotEmpty) {
          urlTextController.text = value.single.path;
          // getVideoInformation();
        }
      },
      onError: (err) {
        print("getIntentDataStream error: $err");
      },
    );

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) async {
      _sharedFiles.clear();
      _sharedFiles.addAll(value);
      if (value.isNotEmpty) {
        urlTextController.text = value.single.path;
        // getVideoInformation();
      }
      // Tell the library that we are done processing the intent.
      ReceiveSharingIntent.instance.reset();
    });

    super.onInit();
  }

  @override
  void onReady() async {
    super.onReady();
    if (WidgetsBinding.instance.window.defaultRouteName == AppRoute.dialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await getVideoInformation();
      });
    }
  }
}
