//InputOutputPage
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'moc_multi.dart';
import 'package:logger_lite/logger_lite.dart';
import 'navigation_drawer.dart' as my_drawer1;
import 'package:flutter/services.dart'; //'dart:typed_data'; 剪贴板服务

class InputOutputPage extends StatefulWidget {
  const InputOutputPage({super.key});

  @override
  _InputOutputPageState createState() => _InputOutputPageState();
}

class _InputOutputPageState extends State<InputOutputPage> {
  FilePickerResult? _selectedFile;
  String? _filename;
  Uint8List? _processedImageData; // 用于存储后端返回的处理后图片数据
  bool _buttonEnabled1 = false;
  bool _buttonEnabled2 = false;
  Map<String, dynamic>? jsonData;
  bool isLoading = true; // 用于显示加载状态
  OverlayEntry? _overlayEntry; // 用于管理 Overlay
  bool isRemind1 = false;
  bool isRemind2 = false;

  
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, // 限制只能选择图片
      allowMultiple: false, // 不允许选择多张图片
    );
    

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('图像选择成功'),backgroundColor: Colors.green,duration: Duration(seconds: 2),),
      );
      setState(() {
        _selectedFile = result;
        if(_buttonEnabled1 == false) _buttonEnabled1 = !_buttonEnabled1;
        if(_buttonEnabled2 == true) _buttonEnabled2 = !_buttonEnabled2;
        if(isRemind1 == false) isRemind1 = !isRemind1;
      });
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('用户取消选择')),
      );
      return;
    }
  }

  Future<void> _uploadImage() async {
    showLoading(); //表示正在处理数据
    final sustainWatch = Stopwatch()..start();
    if (_selectedFile == null) return;
    final dio = Dio();
    final file = _selectedFile!.files.first;
    // 创建 FormData
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      ),
    });
    try {
      // 发送请求到后端
      final response = await dio.post(
        'http://127.0.0.1:5000/process', // 替换为你的后端 API 地址
        data: formData,
        // options: Options(contentType: "multipart/form-data"),
        options: Options(
            responseType: ResponseType.bytes), // 确保以字节形式接收响应，后端返回的是图片的二进制数据
      );

      final imageBytes = response.data;
      if (imageBytes != null) {
        //LoggerLite.log('接受到图片长度: ${imageBytes.length}');
        sustainWatch.stop();
        setState(() {
          _processedImageData = imageBytes;
          _buttonEnabled1 = !_buttonEnabled1; //成功后关闭处理按钮
          _buttonEnabled2 = !_buttonEnabled2;
          //if(_buttonEnabled1 == false) 
          if(isRemind2 == false) isRemind2 = !isRemind2;
          if(sustainWatch.elapsedMilliseconds < 2000){
            Future.delayed(Duration(seconds: 2));
            hideLoading(); //结束处理
          }else{
            hideLoading(); //大于就不用管
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('处理成功，点击[结果解析]按钮查看结果，或者可通过[结果下载]获取相应excel数据'),backgroundColor: Colors.green,),
          );
        });
      } else {
        LoggerLite.log('Received image data is null');
      }
    } catch (e) {
      LoggerLite.log('Error processing image: $e');
    }
  }

      // 显示加载状态
  void showLoading() {
    setState(() {
      isLoading = true;
    });
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 128), // 半透明背景
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white,), // 旋转的加载图标
                SizedBox(height: 16), // 间距
                Text(
                  '处理数据中...',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!); // 插入 Overlay
  }

  // 隐藏加载状态
  void hideLoading() {
    setState(() {
      isLoading = false;
    });
    _overlayEntry?.remove(); // 移除 Overlay
    _overlayEntry = null;
  }

  Future<void> _downloadFile() async {
    setState(() {
      _filename = 'output.xlsx';
    });
    if (_filename == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('没有可下载的文件')));
      return;
    }
    try {
      var dio = Dio();
      var response = await dio.get(
        'http://127.0.0.1:5000/download/$_filename',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200) {
        String fileName = "result";
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString(); // 获取当前时间戳
        String newFileName = '$fileName-$timestamp.xlsx'; // 文件名加上时间戳

        final result = await FilePicker.platform.getDirectoryPath(
          dialogTitle: '选择保存文件的文件夹位置',
        );
        if (result == null) { // 用户取消选择
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('用户取消下载')),
          );
          return;
        }

        final filePath = '$result/$newFileName';
        File file = File(filePath);
        await file.writeAsBytes(response.data);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$newFileName Excel文件已下载到 $filePath'),duration: Duration(seconds: 4),backgroundColor: const Color.fromARGB(255, 49, 138, 49),));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel文件下载失败'),duration: Duration(seconds: 4),backgroundColor: Colors.redAccent,));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'),duration: Duration(seconds: 2)));
    }
  }

  Future<void> _getResult() async {
    _filename = 'output.xlsx';
    var dio_res = Dio();
    try{
      var response = await dio_res.get(
        'http://127.0.0.1:5000/get_result/$_filename',
        options: Options(responseType: ResponseType.json),
      );
      if(response.statusCode == 200){
        // ${response.data[0].runtimeType} $response.data
        jsonData = response.data[0];
      }
    }catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), duration: Duration(seconds: 2)));
    }
  }

  void _showDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder(
          future: _getResult(), // 调用 _getResult 方法加载数据
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // 如果数据正在加载，显示加载动画
              return AlertDialog(
                title: Text('加载数据中...'),
                content: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              // 如果加载失败，显示错误信息
              return AlertDialog(
                title: Text('Error'),
                content: Text('数据加载失败 ${snapshot.error}'),
                actions: <Widget>[
                  TextButton(
                    child: Text('关闭'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            } else {
              // 如果数据加载成功，显示数据
        return AlertDialog(
          title: Column(
            children: [
              Text(
                '玉米成熟度信息计算结果',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8), // 添加一些间距
              Divider(
                thickness: 1.0, // 横线的厚度
                color: Colors.grey, // 横线的颜色
              ),
            ],
          ),
          content: jsonData == null
              ? Text('无可用的数据')
              : SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text('🔵编号信息: ${jsonData?['id']}',style: TextStyle(fontSize: 20,color: Colors.blueAccent),),
                      SizedBox(height: 5),
                      //"${(data.ratio * 100).toStringAsFixed(2)}%"
                      Text('🔵乳线成熟度比率: ${(jsonData?['ratio']).toStringAsFixed(3)}',style: TextStyle(fontSize: 20,color: Colors.blueAccent),),
                      SizedBox(height: 20),
                      Text('🔘白线像素半径: ${jsonData?['white']}',style: TextStyle(fontSize: 20, color: Colors.black54),),
                      SizedBox(height: 5),
                      Text('🔘乳线像素半径: ${jsonData?['red']}',style: TextStyle(fontSize: 20, color: Colors.black54),),
                      SizedBox(height: 5),
                      Text('🔘黑线像素半径: ${jsonData?['black']}',style: TextStyle(fontSize: 20, color: Colors.black54),),
                      SizedBox(height: 20),
                      Divider(
                        thickness: 1.0, // 横线的厚度
                        color: Colors.grey, // 横线的颜色
                      ),
                      SizedBox(height: 16),
                      Text('使用说明：',style: TextStyle(fontSize: 20, color: Colors.black,fontWeight: FontWeight.bold),),
                      SizedBox(height: 3),
                      Text('- 白线像素半径：半径为白线到玉米中心的距离',style: TextStyle(fontSize: 16, color: Colors.black54),),
                      SizedBox(height: 3),
                      Text('- 黑线像素半径：半径为黑线到玉米中心的距离',style: TextStyle(fontSize: 16, color: Colors.black54),),
                      SizedBox(height: 3),
                      Text('- 乳线像素半径：乳线即红线，半径为红线到玉米中心的距离',style: TextStyle(fontSize: 16, color: Colors.black54),),
                      SizedBox(height: 3),
                      Text('- 玉米乳线成熟度比率计算公式=(乳线像素半径 - 黑线像素半径) / (白线像素半径 - 黑线像素半径)',style: TextStyle(fontSize: 16, color: Colors.black),),
                      SizedBox(height: 3),
                      Text('注：用户可根据自己的需求进行其他数值计算',style: TextStyle(fontSize: 16, color: Colors.black54),),
                    ],
                  ),
                ),
                actions: <Widget>[
                              TextButton(
              child: Text(
                '复制到剪贴板',
                style: TextStyle( 
                  fontSize: 16,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold
                ),
              ),
              onPressed: () {
                      // 将数据复制到剪贴板
                      String dataToCopy = jsonData != null
                          ? "ID: ${jsonData?['id']}\n"
                            "Ratio: ${jsonData?['ratio']}\n"
                            "Black: ${jsonData?['black']}\n"
                            "Red: ${jsonData?['red']}\n"
                            "White: ${jsonData?['white']}"
                          : "No data available.";
                      Clipboard.setData(ClipboardData(text: dataToCopy));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('复制成功')),
                      );
                    },
                  ),
                  TextButton(
                    child: Text(
                      '关闭',
                      style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold
                    ),),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('单张玉米图像上传与处理',style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      ),
      drawer: my_drawer1.NavigationDrawer(),
      body: Row(
        //mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                _selectedFile == null
                    ? Text('选取一张需处理的图像',style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                    :InteractiveViewer(
                      boundaryMargin: EdgeInsets.all(10), // 设置边界外的空白区域
                      minScale: 0.5, // 最小缩放比例
                      maxScale: 5.0, // 最大缩放比例
                      child: 
                        Image.file(
                          File(_selectedFile!.files.first.path!),
                          width: 620,
                          height: 550,
                        ),
                      ), 
                if(isRemind1)
                  Text(
                    '滑动滚轮可缩放图片',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () {
                        _pickImage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // 默认背景颜色
                        foregroundColor: Colors.blueAccent, // 默认文字颜色
                        disabledBackgroundColor: Colors.grey, // 禁用时的背景颜色
                        disabledForegroundColor: Colors.white, // 禁用时的文字颜色
                      ),
                      child: Text('玉米图像选择',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),)
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _buttonEnabled1 ? () {
                        _uploadImage();
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // 默认背景颜色
                        foregroundColor: Colors.blueAccent, // 默认文字颜色
                        disabledBackgroundColor: Colors.grey, // 禁用时的背景颜色
                        disabledForegroundColor: Colors.white, // 禁用时的文字颜色
                      ),
                      child: Text('玉米图像处理',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,),),
                    ),
                  ],
                ),
                SizedBox(height: 60),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                _processedImageData == null
                    ? Text('无处理结束的图像',style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                    :InteractiveViewer(
                        boundaryMargin: EdgeInsets.all(10), // 设置边界外的空白区域
                        minScale: 0.5, // 最小缩放比例
                        maxScale: 5.0, // 最大缩放比例
                        child: Image.memory(
                          _processedImageData!,
                          width: 620,
                          height: 550,
                          //fit: BoxFit.cover, // 图片适应方式
                        ),
                      ),
                if(isRemind2)
                  Text(
                    '滑动滚轮可缩放图片',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _buttonEnabled2 ? () {
                        _showDataDialog();
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // 默认背景颜色
                        foregroundColor: Colors.blueAccent, // 默认文字颜色
                        disabledBackgroundColor: Colors.grey, // 禁用时的背景颜色
                        disabledForegroundColor: Colors.white, // 禁用时的文字颜色
                      ),
                      child: Text('结果解析',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _buttonEnabled2 ? _downloadFile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // 默认背景颜色
                        foregroundColor: Colors.blueAccent, // 默认文字颜色
                        disabledBackgroundColor: Colors.grey, // 禁用时的背景颜色
                        disabledForegroundColor: Colors.white, // 禁用时的文字颜色
                      ),
                      child: Text('结果下载',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                        ),
                      ],
                    ),
                    SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }
