from flask import Flask, request, send_file, jsonify, Response
import os
from werkzeug.utils import secure_filename
import runpy
from PIL import Image
import io
import pandas as pd
app = Flask(__name__)


# 配置上传文件的保存路径
UPLOAD_FOLDER = 'maize_normal'
UPLOAD_FOLDER_EXP = 'maize_exp'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)
if not os.path.exists(UPLOAD_FOLDER_EXP):
    os.makedirs(UPLOAD_FOLDER_EXP)
# 配置图片处理后、excel结果文件的保存路径
IMAGE_OUTPUT_FOLDER = 'moc_ratio'
EXCEL_OUTPUT_FOLDER = 'output_excel'
if not os.path.exists(IMAGE_OUTPUT_FOLDER):
    os.makedirs(IMAGE_OUTPUT_FOLDER)
if not os.path.exists(EXCEL_OUTPUT_FOLDER):
    os.makedirs(EXCEL_OUTPUT_FOLDER)

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'}

def allowed_file(filename):
    """检查文件扩展名是否允许"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/')
def hello_world():  # put application's code here
    return 'Hello World!'

@app.route('/process', methods=['POST'])
def upload_image():
    """接收前端上传的图片"""
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        # unique_filename = os.path.splitext(filename)[0] 046-2.jpg取046-2
        save_path = os.path.join(UPLOAD_FOLDER, filename)
        file.save(save_path)
        runpy.run_path('moc_hull.py', run_name="__main__")

        # 构造文件路径并检查文件是否存在
        file_path = os.path.join(IMAGE_OUTPUT_FOLDER, filename)
        if not os.path.exists(file_path):
            return "File not found", 404
        # 打开并图片保存到一个字节流中
        image_res = Image.open(file_path)
        img_byte_arr = io.BytesIO()
        image_res.save(img_byte_arr, format='JPEG')
        img_byte_arr.seek(0)

        for filename in os.listdir(UPLOAD_FOLDER):
            file_path = os.path.join(UPLOAD_FOLDER, filename)
            os.remove(file_path)

        # 使用 Response 发送处理后的图片
        return Response(img_byte_arr, mimetype='image/jpeg')
        # return jsonify({"message": "Successfully", "filename": filename}), 200
    else:
        return jsonify({"error": "Invalid file type"}), 400

@app.route('/processMultiPic', methods=['POST'])
def upload_file():
    """接收前端上传的图片"""
    if 'files[]' not in request.files:
        return jsonify({"error": "No file part"}), 400

    files = request.files.getlist('files[]')
    if not files:
        return jsonify({"error": "No selected files"}), 400

    for file in files:
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            save_path = os.path.join(UPLOAD_FOLDER, filename)
            file.save(save_path)
        else:
            return jsonify({"error": "Invalid file type"}), 400

    # 运行处理脚本
    runpy.run_path('moc_hull.py', run_name="__main__")

    # 构造返回的图片列表
    processed_images = []
    for filename in os.listdir(UPLOAD_FOLDER):
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        output_path = os.path.join(IMAGE_OUTPUT_FOLDER, filename)
        if os.path.exists(output_path):
            image_res = Image.open(output_path)
            img_byte_arr = io.BytesIO()
            image_res.save(img_byte_arr, format='JPEG')
            img_byte_arr.seek(0)
            processed_images.append(img_byte_arr.getvalue())

    # 清空上传文件夹
    for filename in os.listdir(UPLOAD_FOLDER):
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        os.remove(file_path)

    # 返回处理后的图片
    if processed_images:
        return Response(processed_images[0], mimetype='image/jpeg')
    else:
        return jsonify({"error": "No processed images found"}), 404

@app.route('/download/<filename>', methods=['GET'])
def download_file(filename):
    file_path = os.path.join(EXCEL_OUTPUT_FOLDER, filename)
    if os.path.exists(file_path):
        print("发送",file_path)
        return send_file(
            file_path,
            as_attachment=True,
            download_name=filename,
            mimetype='application/octet-stream'
        )
    else:
        return jsonify({"error": "File not found"}), 404


@app.route('/get_result/<filename>',methods=['GET'])
def get_result(filename):
    file_path = os.path.join(EXCEL_OUTPUT_FOLDER, filename)
    try:
        # 读取 Excel 文件
        df = pd.read_excel(file_path)
        # 将 DataFrame 转换为 JSON 格式
        data = df.to_dict(orient='records')
        return jsonify(data)
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/get_image/<filename>', methods=['GET'])
def get_image(filename):
    """根据文件名返回图片"""
    file_path = os.path.join(IMAGE_OUTPUT_FOLDER, filename)
    if os.path.exists(file_path):
        return send_file(file_path, mimetype='image/jpeg')
    else:
        return jsonify({"error": "File not found"}), 404


if __name__ == '__main__':
    app.run()
