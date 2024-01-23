import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http_service/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  NetworkService.configureNetworkService(
    baseURL: "https://dummyjson.com",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Api Caching',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Api Caching Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ValueNotifier<String> _response1 = ValueNotifier("No Data");
  final ValueNotifier<String> _response2 = ValueNotifier("No Data");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ValueListenableBuilder<String>(
              builder: (_, response1, __) {
                return Text(response1);
              },
              valueListenable: _response1,
            ),
            const SizedBox(height: 50),
            ValueListenableBuilder<String>(
              builder: (_, response2, __) {
                return Text(response2);
              },
              valueListenable: _response2,
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: () async {
              await (await SharedPreferences.getInstance()).clear();
              _response1.value = "";
              _response2.value = "";
            },
            child: const Icon(Icons.close),
          ),
          FloatingActionButton(
            onPressed: () async {
              var responseData = await NetworkService.apiRequest.getResponse(
                  endPoint: "/products/add",
                  apiMethods: ApiMethods.post,
                  isToRefresh: false,
                  expiryDurationInDays: 1,
                  queryParams: {
                    "abc": 1223
                  },
                  body: {
                    "title": 'BMW Pencil',
                  });
              responseData.fold(
                (l) {
                  _response1.value = l.toString();
                  log(l.toString());
                },
                (r) {
                  _response1.value = r.toJson().toString();
                  log(r.toJson().toString());
                },
              );

              var responseData1 = await NetworkService.apiRequest.getResponse(
                endPoint: "/users",
                apiMethods: ApiMethods.get,
                isToRefresh: false,
                expiryDurationInDays: 3,
              );
              responseData1.fold(
                (l) {
                  _response2.value = l.toString();
                  log(l.toString());
                },
                (r) {
                  _response2.value = r.toJson().toString();
                  log(r.toJson().toString());
                },
              );
            },
            child: const Icon(Icons.request_page),
          ),
        ],
      ),
    );
  }
}
