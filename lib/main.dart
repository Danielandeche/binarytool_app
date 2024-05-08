import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
      debug: true); // Set to false to disable printing logs to console
  await Permission.storage.request(); // Request storage permission
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BinaryTools',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late InAppWebViewController controller;
  late PullToRefreshController pullToRefreshController;
  late CookieManager cookieManager;

  @override
  void initState() {
    super.initState();

    cookieManager = CookieManager.instance();
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(color: Colors.blue),
      onRefresh: () async {
        controller.reload();
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (await controller.canGoBack()) {
      controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(
                    url: WebUri.uri(Uri.parse('https://ultimate.binarytool.site/'))),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  transparentBackground: true,
                ),
                pullToRefreshController: pullToRefreshController,
                onWebViewCreated: (InAppWebViewController webViewController) {
                  controller = webViewController;
                },
                onLoadStop: (InAppWebViewController webViewController, Uri? url) async {
                  pullToRefreshController.endRefreshing();
                  setState(() {
                    cookieManager.setCookie(
                      url: WebUri.uri(url!),
                      name: 'binarytools_cc',
                      value: 'value',
                      expiresDate: DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
                      isSecure: true,
                    );
                  });
                },
                onDownloadStartRequest: (controller, request) async {
                  final directory = await getExternalStorageDirectory();
                  await FlutterDownloader.enqueue(
                    url: request.url.toString(),
                    savedDir: directory!.path,
                    showNotification: true, // Show download progress in status bar
                    openFileFromNotification: true, // Open the file when download is complete
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
