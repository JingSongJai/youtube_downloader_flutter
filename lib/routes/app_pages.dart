import 'package:get/get.dart';
import 'package:youtube_downloader/routes/app_routes.dart';
import 'package:youtube_downloader/screen/dialog/dialog_screen.dart';
import 'package:youtube_downloader/screen/home/home_screen.dart';

class AppPage {
  AppPage._();

  static List<GetPage> pages = [
    GetPage(name: AppRoute.home, page: () => HomeScreen()),
    GetPage(name: AppRoute.dialog, page: () => DialogScreen()),
  ];
}
