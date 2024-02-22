import 'package:example/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_network_library/data_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RESTExecutor.initialize(config, domains);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return RESTWidget(
        executor: RESTExecutor(domain: 'appState', label: 'theme'),
        exact: true,
        builder: (response) {
          print("inside listenable");
          return MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              brightness: (response.value('dark') ?? true)
                  ? Brightness.dark
                  : Brightness.light,
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: MyHomePage(title: 'Network Library Example'),
          );
        });
  }
}

RESTExecutor _changeTheme = RESTExecutor(domain: 'appState', label: 'theme');

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  Widget build(BuildContext context) {
    RESTExecutor _getData = RESTExecutor(
      domain: 'api',
      label: 'list',
      retryAfterSeconds: 5,
    );
    var data = _getData.watch(context);
    print("---------");
    print(data.statusCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(title!),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'For Local State Management',
              style: TextStyle(fontSize: 18, height: 2),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              _changeTheme.response.data.toString(),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                _changeTheme.execute(data: {
                  'dark': !(_changeTheme.response.value('dark') ?? true)
                });
              },
              child: Text(
                'Change Theme',
              ),
            ),
            Divider(),
            Text(
              'For Network Request Caching',
              style: TextStyle(fontSize: 18, height: 2),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              data.fetching ? 'Loading...' : data.data.toString(),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                await _getData.execute();
              },
              child: Text(
                'Fetch Data',
              ),
            ),
            /* RESTListenableBuilder(
              executor: RESTExecutor(domain: 'appState',label: 'theme'),
              builder: (response)=>Text(response.data.toString()),
            ) */
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
