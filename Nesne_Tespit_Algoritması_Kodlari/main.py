import time
import serial
start_time2 = time.time()
import Jetson.GPIO as GPIO
import cv2
import numpy as np
from yolov8 import YOLOv8

bluetoothSerial = serial.Serial('/dev/ttyTHS1', 9600)
print("kod basladi")

model_path = "model9.onnx"
yolov8_detector = YOLOv8(model_path, conf_thres=0.75, iou_thres=0.3)
print("model yuklendi")

cap = cv2.VideoCapture(0)
time.sleep(0.05)

for i in range(7):
    time.sleep(0.1)
    ret, frame = cap.read()
    print("on foto cekildi " + str(i))

cap.release()
counter = 0
def gonder(meyve_dizisi):
    meyve_dizisi_str = np.array2string(meyve_dizisi, separator=',') + '\n'
    bluetoothSerial.write(meyve_dizisi_str.encode('utf-8'))
    print("Mesaj gonderildi:", meyve_dizisi_str)

def capture_photo(counter):
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        raise IOError("Kamera acilamiyor")
    ret, frame = cap.read()
    if ret:
        print("fotograf cekildi")
        cv2.imwrite("saved" + str(counter) + ".jpg", frame)
        cap.release()
    else:
        print("Fotograf cekilemedi.")

input_pin = 12
GPIO.setmode(GPIO.BOARD)
GPIO.setup(input_pin, GPIO.IN)
print("arduino ok")
result_array = np.array([0, 0, 0, 0, 0, 0])
result_array2 = np.array([0, 0, 0, 0, 0,0])

end_time2 = time.time()
total_time2 = end_time2 - start_time2
print(f"time çalışma süresi1: {total_time2} saniye")

def foo():
    prev_value = None

    print("Starting demo now! Press CTRL+C to exit")
    try:
        while True:
            value = GPIO.input(input_pin)
            if value != prev_value:
                if value == GPIO.HIGH:
                    value_str = "HIGH"
                    print(value_str)
                    capture_photo(counter)
                    img = cv2.imread("saved" + str(counter) + ".jpg")
                    boxes, scores, class_ids = yolov8_detector(img)
                    print(class_ids)

                    object_counter = 0
                    for i in class_ids:
                        result_array[i] += 1
                        result_array2[i] += 1
                        object_counter += 1

                    if object_counter < 3:
                        result_array[5] += (3 - object_counter)
                        result_array2[5] += (3 - object_counter)
                    
                    send_array = np.concatenate((result_array, result_array2), axis=0)
                    gonder(send_array)
                    time.sleep(2)
                    result_array2.fill(0)
                    
                    print(send_array)
                    
                else:
                    value_str = "LOW"
                    print(value_str)
                #print("Value read from pin {} : {}".format(input_pin, value_str))
                prev_value = value
            time.sleep(1)
    except KeyboardInterrupt:
        print("Program sonlandirildi")
    finally:
        GPIO.cleanup()
        bluetoothSerial.close()
foo()
cap.release()


