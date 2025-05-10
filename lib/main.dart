import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_downloader/routes/app_pages.dart';
import 'package:youtube_downloader/routes/app_routes.dart';
import 'package:youtube_downloader/screen/home/home_binding.dart';

var path;
Directory? tempPath;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  path = await ExternalPath.getExternalStoragePublicDirectory(
    ExternalPath.DIRECTORY_DOWNLOAD,
  );
  tempPath = await getTemporaryDirectory();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      getPages: AppPage.pages,
      initialRoute:
          WidgetsBinding.instance.window.defaultRouteName == AppRoute.home
              ? AppRoute.home
              : AppRoute.dialog,
      initialBinding: HomeBinding(),
      theme: ThemeData(
        fontFamily: 'Kantumruy',
        colorScheme: ColorScheme.light(primary: Color(0xFF222831)),
      ),
    );
  }
}
