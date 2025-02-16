import 'package:flutter/material.dart';
import 'login_page.dart';
import 'moc.dart';
import 'moc_multi.dart';
import 'setting.dart';
import 'error_page.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';


//void main() {
/*
void main()  {
  runApp(const MyApp());
}
*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  // 必须加上这一行。
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1400, 800), // 设置默认窗口大小
    minimumSize: Size(300, 220), // 设置最小窗口大小  
    //maximumSize: Size(800, 600),//设置窗口的最大尺寸
    center: true, // 设置窗口居中
    //titleBarStyle: TitleBarStyle.hidden,  //隐藏标签栏
    title: "玉米成熟度计算软件", // 设置窗口标题
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    windowManager.setResizable(true);
  });
 
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOC',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        fontFamily: Platform.isWindows ? 'Microsoft YaHei' : 'Arial',
        fontFamilyFallback : ['Arial', 'Helvetica', 'sans-serif','楷体'],
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      //home: LoginPage(),
      initialRoute: '/single', // 应用启动时显示的页面
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => ErrorPage());
      },
      routes: {   // 定义路由
        '/main':(context) => MyHomePage(),
        '/login':(context) => LoginPage(),
        '/single': (context) => InputOutputPage(),
        '/multi': (context) => MultiInputOutputPage(), 
        '/set': (context) => SettingsPage(),
      },
    );
  }
}


class MyHomePage extends StatefulWidget {
  //const MyHomePage({super.key, required this.title});
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  //final String title;

  @override  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

void _login() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
}

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      //appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        //title: Text(widget.title),
      //),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          
          children: <Widget>[
            Text('华中农业大学玉米表型成熟度分析计算软件',
            style: TextStyle(
              fontSize: 60, // 设置字体大小为30
              fontWeight: FontWeight.bold, // 设置字体为粗体
              color: Colors.white, // 设置字体颜色为黑色
              fontFamily: "楷体",
            ),),
            SizedBox(height: 20),
            Container(
              width: 760, // 图片宽度
              height: 500, // 图片高度
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white, // 边框颜色
                  width: 1, // 边框宽度
              ),
                image: DecorationImage(
                  image: AssetImage('assets/images/image.png'), // 替换为你的图片路径
                  fit: BoxFit.cover, // 图片填充方式
                ),
              ),
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: _login,
        tooltip: '登录',
        backgroundColor: Colors.white,
        child: const Icon(Icons.login_rounded,color: Colors.blue,),
      ), 
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, 
    );
  }
}


