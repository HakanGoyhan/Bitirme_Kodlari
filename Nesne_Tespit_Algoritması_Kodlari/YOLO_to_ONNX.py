from ultralytics import YOLO

model = YOLO("model11.pt")

model.export(format="onnx")


