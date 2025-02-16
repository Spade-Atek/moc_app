import 'package:flutter/material.dart';

class NavigationDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 260,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueAccent
            ),
            child: const Text(
              '功能导航栏',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_filled,color: Colors.blueAccent,),
            title: const Text('主页'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/main');
            },
          ),
          ListTile(
            leading: const Icon(Icons.image,color: Colors.blueAccent,),
            title: const Text('单张玉米图像处理'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/single');
            },
          ),
          ListTile(
            leading: const Icon(Icons.image_search_rounded,color: Colors.blueAccent,),
            title: const Text('批量玉米图像处理'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/multi');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout,color: Colors.blueAccent,),
            title: const Text('退出登录'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings,color: Colors.blueAccent,),
            title: const Text('设置'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/set');
            },
          ),
        ],
      ),
    );
  }
}
