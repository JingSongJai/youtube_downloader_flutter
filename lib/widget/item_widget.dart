import 'package:flutter/material.dart';
import 'package:youtube_downloader/constant/constant.dart';

class ItemWidget extends StatelessWidget {
  const ItemWidget({
    super.key,
    required this.size,
    required this.quality,
    required this.onTap,
    required this.loading,
    required this.progress,
    required this.downloadState,
    this.isVideo = true,
  });
  final String size, quality;
  final Function() onTap;
  final Widget? loading;
  final double progress;
  final String downloadState;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Color(0xFFA3A3A3), width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        title:
            loading ??
            Row(
              children: [
                Expanded(child: Text(quality)),
                Expanded(child: Text(size)),
              ],
            ),
        trailing:
            loading == null
                ? InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.download, size: 20, color: primaryColor),
                  ),
                )
                : null,
        subtitle:
            loading == null
                ? null
                : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      downloadState,
                      style: TextStyle(color: Color(0xFFA3A3A3)),
                    ),
                    Text(
                      '${progress.toInt().toString()} %',
                      style: TextStyle(color: Color(0xFFA3A3A3)),
                    ),
                  ],
                ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: primaryColor,
          ),
          child:
              isVideo
                  ? Icon(Icons.play_circle, color: Colors.white)
                  : Icon(Icons.music_note, color: Colors.white),
        ),
      ),
    );
  }
}
