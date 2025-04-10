# @Time : 2024/6/7 23:37
# @Author : XIE Yutai
# @FileName: moc_hull.py
import cv2
import numpy as np
import os
import pandas as pd
import openpyxl

input_folder = 'maize_normal/'  # 替换玉米所在图像文件夹路径
output_folder = 'moc_ratio'  # 替换保存输出图像的文件夹路径
excel_folder = 'output_excel/'

maize_imageExp = cv2.imread('maize_exp/Maize_exp.png')  # 用于捕捉玉米目标的示例图
gray_imageExp = cv2.cvtColor(maize_imageExp, cv2.COLOR_BGR2GRAY)

supported_ext = ['jpg', 'jpeg', 'png', 'bmp', 'tiff', 'JPG', 'PNG', 'BMP', 'TIFF']


def calculate_distances(points, target_point):
    distances = []
    for point in points:
        x, y = point[0]
        distance = np.sqrt((x - target_point[0]) ** 2 + (y - target_point[1]) ** 2)
        distances.append(distance)
    return distances


def exclude_ur(binary_image, contour, point):
    ret = cv2.pointPolygonTest(contour, point, False)
    # 判断点的位置
    if ret > 0:
        return True
    elif ret == 0:
        return True
    else:
        return False

def put_text(image, text, org):
    fontFace = cv2.FONT_HERSHEY_SIMPLEX  # 字体
    fontScale = 3  # 字体大小
    color = (0, 255, 255)  # 字体颜色 BGR
    thickness = 8  # 线条粗细
    cv2.putText(image, text, org, fontFace, fontScale, color, thickness, cv2.LINE_AA)

def get_maize_contour():
    # 使用自适应阈值进行二值化
    gray_image = cv2.cvtColor(maize_image, cv2.COLOR_BGR2GRAY)  # 转换为灰度图
    blur_dst = cv2.GaussianBlur(gray_image, (3, 3), 0)
    _, binary = cv2.threshold(blur_dst, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)
    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)  # 寻找轮廓
    _, binary_exp = cv2.threshold(gray_imageExp, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)
    contours_exp, _ = cv2.findContours(binary_exp, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)  # 寻找轮廓
    min_similarity = float('inf')
    min_similarity_contour = None
    for contour_c in contours:
        contour_exp = max(contours_exp, key=cv2.contourArea)
        if cv2.contourArea(contour_c) > 300:  # 减少对比次数
            cv2.drawContours(maize_image, [contour_c], -1, (0, 255, 0), 2)
            similarity = cv2.matchShapes(contour_c, contour_exp, cv2.CONTOURS_MATCH_I1, 0)
            if similarity < min_similarity:
                min_similarity = similarity
                min_similarity_contour = contour_c
    return min_similarity_contour


def get_white_line(contour):
    hull = cv2.convexHull(contour, returnPoints=True)
    # 计算轮廓的质心
    M = cv2.moments(contour)
    if M["m00"] != 0:
        cX = int(M["m10"] / M["m00"])
        cY = int(M["m01"] / M["m00"])
    else:
        cX, cY = 0, 0
    for point in hull:
        x, y = point[0]
    # 1.2 当前做法
    distance_hull = calculate_distances(hull, target_point=(cX, cY))
    distance_mean = np.mean(distance_hull)

    org = (100, 100)
    radius = distance_mean
    text = "The radius of white circle: " + str(round(radius, 2))
    put_text(maize_image, text, org)

    circle_center = (cX, cY)
    # 绘制轮廓 、 绘制白线
    cv2.drawContours(maize_image, [contour], -1, (0, 255, 0), 2)
    # cv2.circle(maize_image, circle_center, int(radius), (255, 255, 255), 4)
    # 绘制圆心（使用一个小圆来表示）
    cv2.circle(maize_image, circle_center, int(distance_mean), (255, 255, 255), 5)  # 小圆，填充
    return radius, circle_center


# 获取某一圆线的rgb像素情况
def get_line_rgb(arc_step, radius):
    cX, cY = center
    scan_values = []
    r_value = []
    g_value = []
    b_value = []
    n = 0
    for theta in np.arange(0, 2 * np.pi, arc_step):
        # 计算当前圆形线上点的坐标
        x = cX + radius * np.cos(theta)
        y = cY + radius * np.sin(theta)
        scan_point = (int(x), int(y))
        if exclude_ur(maize_image, contour, scan_point):
            # 提取当前点的RGB值
            bgr_value = rgb_image[int(y), int(x)]
            rgb_value = bgr_value[::-1]
            n += 1  # 方便调试
            scan_values.append(rgb_value)
            r_value.append(rgb_value[0])
            g_value.append(rgb_value[1])
            b_value.append(rgb_value[2])
    return r_value, g_value, b_value, scan_values


# 获取指定区域的rgb像素情况,调用getLineRGB
def get_area_rgb(arc_step, radius_step, init_radius, final_radius):
    r_data = []
    g_data = []
    b_data = []
    scan_all = []  # 用来检验，后期除去
    if init_radius == white_radius:
        init_radius = int(init_radius) - radius_step
    for radius_id in range(init_radius, final_radius, -radius_step):
        r_value, g_value, b_value, scan_data = get_line_rgb(arc_step, radius_id)
        r_data.append([radius_id, r_value])
        g_data.append([radius_id, g_value])
        b_data.append([radius_id, b_value])
        scan_all.append(scan_data)
    return r_data, g_data, b_data, scan_all


# 绘制黑色线，调用getAreaRGB,扫描从半径从0到半径xxx的所有圆线的rgb值情况，返回黑色线的半径
def get_black_line():
    cX, cY = center
    r_data, g_data, b_data, scan_all = get_area_rgb(arc_step, radius_step, int(white_radius) - 30, 0)
    # print(r_data)
    black_radius_id = 0
    std_max = float('-inf')  # 初始为正无穷小
    for i in range(len(r_data)):
        std_dev_r = np.std(r_data[i][1])
        std_dev_g = np.std(g_data[i][1])
        std_dev_b = np.std(b_data[i][1])
        # 计算整体的标准差（例如简单相加或取平均值）
        overall_std_dev = np.mean((std_dev_r, std_dev_g, std_dev_b))
        if overall_std_dev > std_max:
            std_max = overall_std_dev
            black_radius_id = i
    try:
        cv2.circle(maize_image, (cX, cY), r_data[black_radius_id][0], (0, 0, 0), 8)
        org = (100, 200)
        radius = r_data[black_radius_id][0]
        text = "The radius of black circle: " + str(round(radius, 2))
        put_text(maize_image, text, org)
        return r_data[black_radius_id][0]  # 返回黑色线所在半径
    except IndexError:
        print("超出索引")


def get_red_line(white_radius, black_radius, red_step):
    cX, cY = center
    split_radius = int(white_radius) - red_step
    # 设置一个获取带宽度
    width = 30
    overall_mean_data1 = []
    overall_mean_data2 = []
    while split_radius - width > black_radius:
        r_data1, g_data1, b_data1, scan_all1 = get_area_rgb(arc_step, red_step, split_radius + width, split_radius)
        r_data2, g_data2, b_data2, scan_all2 = get_area_rgb(arc_step, red_step, split_radius, split_radius - width)
        for i in range(len(r_data1)):
            r1_mean = np.mean(r_data1[i][1])
            g1_mean = np.mean(g_data1[i][1])
            b1_mean = np.mean(b_data1[i][1])
            # 计算上半部整体的平均值——灰度值
            overall_mean_data1 = np.mean((r1_mean, g1_mean, b1_mean))
            # print("overall_mean_data1", overall_mean_data1)
            r2_mean = np.mean(r_data2[i][1])
            g2_mean = np.mean(g_data2[i][1])
            b2_mean = np.mean(b_data2[i][1])
            # 计算下半部整体的平均值——灰度值
            overall_mean_data2 = np.mean((r2_mean, g2_mean, b2_mean))
        split_radius -= red_step
        if overall_mean_data2 > overall_mean_data1:
            cv2.circle(maize_image, (cX, cY), split_radius, (0, 0, 255), 3)
            org = (100, 300)
            radius = split_radius
            text = "The radius of red circle: " + str(round(radius, 2))
            put_text(maize_image, text, org)
            return split_radius


if __name__ == "__main__":
    count = 0
    row_excel = []
    file_name = None
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
    for filename in os.listdir(input_folder):
        file_ext = filename.split('.')[-1].lower()
        file_name = filename
        empty_dict = dict()
        if file_ext in supported_ext:
            count = count + 1
            print("当前处理的是第" + str(count) + "张图像：" + filename)
            input_path = os.path.join(input_folder, filename)
            maize_image = cv2.imread(input_path)
            if maize_image is None:
                print("Error: 未成功加载图像，请检查文件路径。")
            else:
                rgb_image = cv2.cvtColor(maize_image, cv2.COLOR_BGR2RGB)
            # 这两个可以定制精度
            radius_step = 10  # 每次半径变化的步长
            arc_step = 0.05  # 每次扫描圆线中弧变化的步长
            red_step = 1
            contour = get_maize_contour()
            white_radius, center = get_white_line(contour)
            white_radius = int(white_radius) - 50
            black_radius = get_black_line()
            split_radius = get_red_line(white_radius, black_radius, red_step)
            white_radius_act = white_radius + 50
            ratio = (split_radius - black_radius) / (white_radius_act - black_radius)

            empty_dict['id'] = file_name
            empty_dict['white'] = white_radius_act
            empty_dict['white'] = white_radius_act
            empty_dict['red'] = split_radius
            empty_dict['black'] = black_radius
            empty_dict['ratio'] = ratio
            row_excel.append(empty_dict)
            org = (100, 400)
            text = "The ratio of Maize (ID:" + file_name + "):" + str(round(ratio, 3))
            put_text(maize_image, text, org)
            # 保存结果
            output_path = os.path.join(output_folder, filename)
            cv2.imwrite(output_path, maize_image)

    column_headers = list(row_excel[0].keys()) if row_excel else []
    df = pd.DataFrame(row_excel, columns=column_headers)
    df.to_excel(excel_folder+'output.xlsx', index=False)
