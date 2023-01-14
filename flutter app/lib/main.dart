import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const App());
}

class Currency {
  final String name;
  final String code;

  const Currency({required this.name, required this.code});
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Exchange',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const HomePage(title: 'Currency Exchange'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Currency> currencies = [];
  Currency? currency1;
  Currency? currency2;
  double? rate;
  double? value1;
  double? value2;

  var controller1 = TextEditingController();
  var controller2 = TextEditingController();

  @override
  void initState() {
    super.initState();

    var url = Uri.http(dotenv.env['API_URL']!, '/currencies');
    http.get(url).then((res) {
      var json = jsonDecode(res.body);
      currencies = List.from(json)
          .map((item) => Currency(name: item['name'], code: item['code']))
          .toList();
      currency1 = currencies[0];
      currency2 = currencies[1];
      value1 = 1;
      controller1.text = value1!.toString();
      updateRate();
    });
  }

  updateRate() {
    var url = Uri.http(dotenv.env['API_URL']!,
        '/exchange/${currency1!.code}/${currency2!.code}');
    http.get(url).then((res) {
      var json = jsonDecode(res.body);
      setState(() {
        rate = json['rate'];
        value2 = value1! * rate!;
        controller2.text = value2.toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              controller: controller1,
              onChanged: (String value) {
                setState(() {
                  if (value.isEmpty) {
                    controller2.text = '';
                  } else {
                    value2 = int.parse(value) * rate!;
                    controller2.text = value2.toString();
                  }
                });
                controller2.text = value2.toString();
              } ,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffix: DropdownButton(
                      value: currency1,
                      items: currencies
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text('${item.name} (${item.code})'),
                              ))
                          .toList(),
                      onChanged: (Currency? value) {
                        currency1 = value;
                        updateRate();
                      })),
            ),
            TextField(
              keyboardType: TextInputType.number,
              controller: controller2,
              onChanged: (String value) {
                setState(() {
                  if (value == '') {
                    controller1.text = '';
                  } else {
                    value1 = int.parse(value) * rate!;
                    controller1.text = value1.toString();
                  }
                });
              } ,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffix: DropdownButton(
                      value: currency2,
                      items: currencies
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text('${item.name} (${item.code})'),
                              ))
                          .toList(),
                      onChanged: (Currency? value) {
                        currency2 = value;
                        updateRate();
                      })),
            ),
          ],
        ),
      ),
    );
  }
}
