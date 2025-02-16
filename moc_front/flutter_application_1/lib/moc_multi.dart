//InputOutputPage
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:logger_lite/logger_lite.dart';
import 'navigation_drawer.dart' as my_drawer2;
import 'package:path/path.dart' as path;

// 创建一个用来存储输出信息的类
class ImageData {
  final String id;
  final int black;
  final int red;
  final int white;
  final double ratio;

  ImageData({
    required this.id,
    required this.black,
    required this.red,
    required this.white,
    required this.ratio,
  });

  factory ImageData.fromJson(Map<String, dynamic> json) => ImageData(
        id: json['id']?.toString() ?? '',
        black: (json['black'] as num?)?.toInt() ?? 0,
        red: (json['red'] as num?)?.toInt() ?? 0,
        white: (json['white'] as num?)?.toInt() ?? 0,
        ratio: (json['ratio'] as num?)?.toDouble() ?? 0.0,
      );
}

class MultiInputOutputPage extends StatefulWidget {
  const MultiInputOutputPage({super.key});

  @override
  _MultiInputOutputPageState createState() => _MultiInputOutputPageState();
}

class _MultiInputOutputPageState extends State<MultiInputOutputPage> {
  List<PlatformFile>? _selectedFiles;
  String? _filename;
  bool _buttonEnabled1 = false;
  bool _buttonEnabled2 = false;
  bool _buttonEnabledWait = false;
  bool isLoading = false; // 控制加载状态
  OverlayEntry? _overlayEntry; // 用于管理 Overlay
  List<dynamic>? _excelData;

  Future<void> _pickImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, // 限制只能选择图片
      allowMultiple: true, // 允许选择多张图片
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('图像选择成功'),backgroundColor: Colors.green,duration: Duration(seconds: 2),),
      );
      setState(() {
        _selectedFiles = result.files;
        if(_buttonEnabled1 == false) _buttonEnabled1 = !_buttonEnabled1;
        if(_buttonEnabled2 == true) _buttonEnabled2 = !_buttonEnabled2;
        if(_buttonEnabledWait == true) _buttonEnabledWait = !_buttonEnabledWait;
      });
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('用户取消选择')),
      );
      return;
    }
  }
  //批量处理按钮方法
  Future<void> _uploadImages() async {
    showLoading(); //表示正在处理数据
    final stopwatch = Stopwatch()..start();
    if (_selectedFiles == null || _selectedFiles!.isEmpty) return;
    final dio = Dio();
    final formData = FormData();
    for (var file in _selectedFiles!) {
      formData.files.add(
        MapEntry(
          "files[]",
          await MultipartFile.fromFile(
            file.path!,
            filename: file.name,
          ),
        ),
      );
    }
    try {
      // 发送请求到后端
      final response = await dio.post(
        'http://127.0.0.1:5000/processMultiPic', // 替换为你的后端 API 地址
        data: formData,
        // options: Options(contentType: "multipart/form-data"),
        options: Options(responseType: ResponseType.bytes), // 确保以字节形式接收响应,后端返回的是图片的二进制数据
      );
      final imageBytes = response.data;
      if (imageBytes != null) {
        stopwatch.stop();
        setState(() {
          _buttonEnabled2 = !_buttonEnabled2;
          _buttonEnabledWait = !_buttonEnabledWait;
          _buttonEnabled1 = !_buttonEnabled1;//成功后关闭上传处理按钮
          if(stopwatch.elapsedMilliseconds < 2000){
            Future.delayed(Duration(seconds: 2));
            hideLoading(); //结束处理
            
          }else{
            hideLoading(); //大于就不用管
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('批量处理成功，点击[结果解析]按钮查看结果，或者可通过[结果下载]获取相应excel数据'),backgroundColor: Colors.green,),
          );
        });
      } else {
        LoggerLite.log('Received image data is null');
      }
    } catch (e) {
      LoggerLite.log('Error processing image: $e');
    }
  }

  Future<void> _presentExcelData() async {
    setState(() {
      _filename = 'output.xlsx';
    });
    var dio_res = Dio();
    try{
      var response = await dio_res.get(
        'http://127.0.0.1:5000/get_result/$_filename',
        options: Options(responseType: ResponseType.json),
      );
      if(response.statusCode == 200){
        // ${response.data[0].runtimeType} $response.data
        print('Data type: ${response.data.runtimeType}'); 
        //print(response.data);
        setState(() {
          _excelData = response.data;
        });
        //LoggerLite.log(_excelData);
      }
    }catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), duration: Duration(seconds: 2)));
    }
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
                CircularProgressIndicator(), // 旋转的加载图标
                SizedBox(height: 16), // 间距
                Text(
                  '处理数据中...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
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

  @override
  Widget build(BuildContext context) {
    final dataList = _excelData?.map((item) => ImageData.fromJson(item as Map<String, dynamic>)).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('批量玉米图像上传与处理',style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),),
      ),
      drawer: my_drawer2.NavigationDrawer(),
      body: Row(
        //mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (_selectedFiles != null)
                  Column(
                    children: [
                      Text(
                        '选择了 ${_selectedFiles!.length} 张图像,分别是',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      ..._selectedFiles!.take(15).map(
                        (file) => Text(
                          path.basename(file.path!), // 显示文件名
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '可选择一张或多张需处理图像',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                SizedBox(height: 80),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () {
                        _pickImages();
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
                        _uploadImages();
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // 默认背景颜色
                        foregroundColor: Colors.blueAccent, // 默认文字颜色
                        disabledBackgroundColor: Colors.grey, // 禁用时的背景颜色
                        disabledForegroundColor: Colors.white, // 禁用时的文字颜色
                      ),
                      child: Text('批量处理',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
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
                Container(
                  width: 520, // 设置最大宽度
                  height: 450, // 设置最大高度
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue), // 添加边框
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical, 
                    child: DataTable(
                      //border: TableBorder.all(color:Colors.blue,), // 添加边框
                      columns: const [
                        DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Black', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Red', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('White', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Ratio(%)', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: dataList?.map((data) => DataRow(
                        cells: [
                          DataCell(Text(data.id, style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(data.black.toString())),
                          DataCell(Text(data.red.toString())),
                          DataCell(Text(data.white.toString())),
                          DataCell(Text("${(data.ratio * 100).toStringAsFixed(2)}%", style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blue))), // 转换为百分比
                        ],
                      )).toList() ?? [],
                    ),
                  ),
                ),
                SizedBox(height: 80),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[ 
                    ElevatedButton(
                      onPressed: _buttonEnabledWait ? () {
                        _presentExcelData();
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


