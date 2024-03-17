import time
start_time2 = time.time()
import cv2
from yolov8 import YOLOv8

model_path = "model11.onnx"
yolov8_detector = YOLOv8(model_path, conf_thres=0.75, iou_thres=0.3)

import cv2 
cap = cv2.VideoCapture(1)
time.sleep(0.05)

for i in range(7):
    time.sleep(0.1)

    ret, frame = cap.read()

def capture_photo():
    if not cap.isOpened():
        raise IOError("Kamera açılamıyor")
    ret, frame = cap.read()
    if ret:
        print("Fotoğraf çekildi")
        cv2.imwrite("saved.jpg", frame)
    else:
        print("Fotoğraf çekilemedi.")


capture_photo()
img = cv2.imread("saved.jpg")

boxes, scores, class_ids = yolov8_detector(img)
print(class_ids)

combined_img = yolov8_detector.draw_detections(img)
cv2.imwrite("doc/img/detected_objects2.jpg", combined_img)

end_time2 = time.time()  
total_time2 = end_time2 - start_time2  
print(f"time çalışma süresi1: {total_time2} saniye")
