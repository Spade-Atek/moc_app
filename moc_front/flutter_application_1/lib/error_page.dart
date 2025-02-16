import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: Center(
         child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '发生错误，请点击下方按钮返回主页。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),  
            SizedBox(height: 20),
            InkWell(
              onTap: () {
                Navigator.popUntil(context, (route) => route.settings.name == '/main');
              },
              child: Text('返回主页', style: TextStyle(color: Colors.blueAccent,fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}