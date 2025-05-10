import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:percent_indicator/flutter_percent_indicator.dart';
import 'package:youtube_downloader/constant/constant.dart';
import 'package:youtube_downloader/screen/home/home_controller.dart';
import 'package:youtube_downloader/widget/item_widget.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DialogScreen extends GetView<HomeController> {
  const DialogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // controller.getVideoInformation();
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          height: double.infinity,
          child: Column(
            children: [
              Obx(() {
                return controller.isGenerating.value
                    ? Column(
                      children: [
                        const SizedBox(height: 100),

                        Center(
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: LoadingIndicator(
                              indicatorType: Indicator.lineScale,
                              colors: [primaryColor],
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ],
                    )
                    : SizedBox.shrink();
              }),

              Obx(() {
                return !controller.isGenerating.value &&
                        controller.contents.isNotEmpty
                    ? Expanded(
                      child: Column(
                        children: [
                          TabBar(
                            controller: controller.tabController2,
                            tabs: [Tab(text: 'Video'), Tab(text: 'Audio')],
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: controller.tabController2,
                              physics: NeverScrollableScrollPhysics(),
                              children: [buildVideo(), buildAudio()],
                            ),
                          ),
                        ],
                      ),
                    )
                    : const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildVideoInformation() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              clipBehavior: Clip.antiAlias,
              child: Image.network(controller.url.value, width: 150),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${controller.duration?.inHours == 0 ? '' : '${controller.duration?.inHours}:'}${controller.duration?.inMinutes.remainder(60).toString().padLeft(2, '0')}:${controller.duration?.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            controller.title.value,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget buildVideo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: controller.contents.length,
        itemBuilder: (context, index) {
          StreamInfo content = controller.contents[index];

          return Obx(() {
            return ItemWidget(
              size: '${content.size.totalMegaBytes.toStringAsPrecision(3)} MB',
              quality: content.qualityLabel,
              onTap: () async {
                if (controller.isDownloading.value ||
                    controller.isMixing.value) {
                  return;
                }

                await controller.downloadVideo(
                  controller.url.value,
                  content.tag,
                );
              },
              loading:
                  controller.progress.value != 0.0 &&
                          controller.downloadedTag.value == content.tag &&
                          controller.isDownloading.value
                      ? LinearPercentIndicator(
                        lineHeight: 5.0,
                        percent: controller.progress.value,
                        padding: EdgeInsets.zero,
                        barRadius: Radius.circular(5),
                        backgroundColor: Colors.grey.shade100,
                        progressColor: Colors.green,
                      )
                      : null,
              progress: controller.progress.value * 100,
              downloadState: controller.downloadState.value,
            );
          });
        },
      ),
    );
  }

  Widget buildAudio() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 3,
        itemBuilder: (context, index) {
          StreamInfo audio = controller.audioes.firstWhere(
            (audio) =>
                (audio.codec.parameters['codecs'] ?? '').contains('mp4a') &&
                audio.codec.type == 'audio',
          );

          return Obx(() {
            return ItemWidget(
              size:
                  index == 0
                      ? 'High'
                      : index == 1
                      ? 'Medium'
                      : 'Low',
              quality:
                  index == 0
                      ? '320 kbps'
                      : index == 1
                      ? '160 kbps'
                      : '64 kbps',
              onTap: () async {
                if (controller.isDownloading.value ||
                    controller.isMixing.value) {
                  return;
                }

                String bitrate =
                    index == 0
                        ? '320'
                        : index == 1
                        ? '160'
                        : '64';

                await controller.downloadAudio(bitrate, index);
              },
              loading:
                  controller.progress.value != 0.0 &&
                          controller.downloadedTag.value == index &&
                          controller.isDownloading.value
                      ? LinearPercentIndicator(
                        lineHeight: 5.0,
                        percent: controller.progress.value,
                        padding: EdgeInsets.zero,
                        barRadius: Radius.circular(5),
                        backgroundColor: Colors.grey.shade100,
                        progressColor: Colors.green,
                      )
                      : null,
              progress: controller.progress.value * 100,
              downloadState: controller.downloadState.value,
              isVideo: false,
            );
          });
        },
      ),
    );
  }
}
