import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:percent_indicator/flutter_percent_indicator.dart';
import 'package:youtube_downloader/constant/constant.dart';
import 'package:youtube_downloader/screen/home/home_controller.dart';
import 'package:youtube_downloader/widget/button_widget.dart';
import 'package:youtube_downloader/widget/item_widget.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.focusScope!.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: _buildTitle(),
          bottom: PreferredSize(
            preferredSize: Size(double.infinity, 200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Enter Your Youtube Link',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller.urlTextController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter Youtube Video/Playlist Link',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 192, 192, 192),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFF696969),
                          width: 1.5,
                        ),
                      ),
                      hintStyle: TextStyle(color: Color(0xFFA3A3A3)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    return ButtonWidget(
                      text:
                          controller.isGenerating.value
                              ? 'Generating...'
                              : 'Generate Video Content',
                      onTap: () async {
                        if (controller.isGenerating.value) return;
                        Get.focusScope!.unfocus();
                        await controller.getVideoInformation();
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Obx(() {
                      return controller.url.isEmpty || controller.title.isEmpty
                          ? SizedBox.shrink()
                          : buildVideoInformation();
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              Obx(() {
                return controller.isGenerating.value
                    ? Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: LoadingIndicator(
                          indicatorType: Indicator.lineScale,
                          colors: [primaryColor],
                          strokeWidth: 2,
                        ),
                      ),
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
                            controller: controller.tabController1,
                            tabs: [Tab(text: 'Video'), Tab(text: 'Audio')],
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: controller.tabController1,
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

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUTUBE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'BarBender',
            fontSize: 20,
          ),
        ),
        Text(
          'DOWNLOADER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'BarBender',
            color: primaryColor,
            fontSize: 20,
          ),
        ),
      ],
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
