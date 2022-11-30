import math
from collections import defaultdict

from PIL import Image as PIL_Image
import cv2
import numpy as np
from scipy import ndimage


def rotate_image(image, angle):
    if angle == 0:
        return image
    image = np.array(image.convert('RGB'))
    img = ndimage.rotate(image, angle)
    img = PIL_Image.fromarray(img)
    return img


def resize_image(image, max_width=1800):
    # google OCR receommended size: 1024 * 768
    if image.width <= max_width:
        return image
    else:
        width_pct = (max_width / float(image.size[0]))
        new_height = int(float(image.size[1]) * float(width_pct))
        return image.resize((max_width, new_height), PIL_Image.ANTIALIAS)


def grayscale(img):
    return cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)


def get_angle_from_lines(lines, direction):
    if lines is None:
        return 0
    ratio_threshold = 1.1
    degrees = []
    zero_count = 0

    for line in lines:
        x1, y1, x2, y2 = line[0]
        degree = math.degrees(math.atan2((y2 - y1), (x2 - x1)))
        if (direction == 'horizontal' and abs(degree) <= 10) or (direction == 'vertical' and abs(degree) >= 80):  # noqa: B950
            if direction == 'vertical':
                degree = (90 - abs(degree)) * (degree / abs(degree)) * (-1.0)
            if abs(degree) < 0.1:
                degree = 0
            if degree == 0:
                zero_count += 1
            else:
                degrees.append(degree)

    if not degrees:
        return 0
    if zero_count > ratio_threshold * len(degrees):
        return 0
    return np.median(degrees)


# expects cv2 image
def micro_angle(image):
    shifted = cv2.pyrMeanShiftFiltering(image, 7, 21)
    img = cv2.bilateralFilter(shifted, 9, 75, 75)
    img = grayscale(img)
    _rows, cols = img.shape
    scale_kernel = 100
    scale_length = 6
    maxlinegap = 50
    iterations = 2

    # get horizontal lines
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (cols // scale_kernel, 1))
    horizontal_lines = cv2.morphologyEx(
        img, cv2.MORPH_OPEN, kernel, iterations=iterations)
    edges = cv2.Canny(horizontal_lines, 100, 150, apertureSize=3)
    lines = cv2.HoughLinesP(edges, rho=1, theta=np.pi / 180, threshold=cols // scale_length,
                            minLineLength=cols // scale_length, maxLineGap=maxlinegap)

    horizontal_degree = get_angle_from_lines(lines, 'horizontal')

    return horizontal_degree


def rotation_angle_of_word(word):
    bounds = word['bounding_poly']['vertices']
    top_left = defaultdict(int, bounds[0])
    top_right = defaultdict(int, bounds[1])
    return math.atan2(top_left['y'] - top_right['y'],
                      top_right['x'] - top_left['x']) * (180 / math.pi)


def macro_angle(words):
    if (len(words) == 0):
        return 0
    angles = [rotation_angle_of_word(word)
              for word in words]
    return max(angles, key=lambda angle: angles.count(angle))


def convert_pil_image_to_cv2(image):
    pil_image = image.convert('RGB')
    return cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
