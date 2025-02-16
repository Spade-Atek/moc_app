import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'moc.dart';
import 'login_style.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    if (_usernameController.text == "admin" && 
        _passwordController.text == "123") {
      await Future.delayed(Duration(seconds: 1));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 登录成功!'),
          backgroundColor: const Color.fromARGB(255, 49, 138, 49),
          duration: Duration(seconds: 1),
        ),
      );
      await Future.delayed(Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => InputOutputPage(),
          transitionsBuilder: (_, a, __, c) => 
            FadeTransition(opacity: a, child: c),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 用户名或密码错误'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  void _back2main(){
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: LoginStyle.backgroundDecoration,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 440,maxHeight: 500),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_person_rounded, size: 64, color: Colors.blueAccent),
                      SizedBox(height: 24),
                      TextFormField(
                        controller: _usernameController,
                        decoration: LoginStyle.inputDecoration.copyWith(
                          labelText: '用户名',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => v!.isEmpty ? '请输入用户名' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: LoginStyle.inputDecoration.copyWith(
                          labelText: '密码',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (v) => v!.isEmpty ? '请输入密码' : null,
                      ),
                      SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _isLoading 
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                   color: Colors.blueAccent
                                  ),
                                )
                              : Icon(Icons.open_in_full_rounded,color: Colors.blueAccent),
                          label: Text(
                            _isLoading ? '登录中...' : '立即登录',
                            style: TextStyle(
                              color: Colors.blueAccent, // 设置文本颜色
                              fontSize: 18,       // 设置文本大小
                              fontWeight: FontWeight.bold,
                          ),),
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _back2main,
        tooltip: '返回',
        backgroundColor: Colors.white,
        child: const Icon(Icons.home,color: Colors.blueAccent,),
      ), 
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat, 
    );
  }
}

