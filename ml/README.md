# CropGuard AI: Machine Learning & YOLO11s Training Pipeline

This directory contains the complete dataset configurations, training scripts, evaluation utilities, and notebooks for the **CropGuard AI** pest detection model.

---

## 1. Directory Structure

```text
ml/
├── configs/
│   ├── dataset.yaml        # YOLO dataset configuration (6 target pest classes)
│   └── hyp_cropguard.yaml  # Field-resilience fine-tuning hyperparameters
├── notebooks/
│   └── cropguard_yolo11s_training.ipynb  # End-to-end Google Colab GPU training notebook
├── training/
│   ├── dataset_prep.py     # Annotation validation and 70/20/10 split pipeline
│   └── train_yolo.py       # Fine-tuning training script
├── evaluation/
│   └── evaluate.py         # Precision, Recall, F1, mAP@50, mAP@50:95, and latency benchmarks
├── weights/
│   ├── best.pt             # Trained YOLO11s PyTorch model weights
│   └── best.onnx           # Exported ONNX runtime weights
└── README.md
```

---

## 2. Target Pest Categories (6 Harmful Classes)

| Class ID | Common Name | Scientific Name | Target Crop Association |
|---|---|---|---|
| **0** | **Aphids** | *Aphis gossypii* | Cotton, Chilli, Tomato |
| **1** | **Whitefly** | *Bemisia tabaci* | Cotton, Tomato, Chilli |
| **2** | **Brown Planthopper** | *Nilaparvata lugens* | Paddy / Rice |
| **3** | **Yellow Stem Borer** | *Scirpophaga incertulas* | Paddy / Rice |
| **4** | **Thrips** | *Scirtothrips dorsalis* | Chilli, Cotton, Tomato |
| **5** | **Helicoverpa armigera** | *Helicoverpa armigera* | Tomato, Cotton, Chilli |

---

## 3. How to Train the Model on Google Colab GPU

Since fine-tuning deep learning object detection models on high-resolution images requires dedicated NVIDIA CUDA cores:

1. Open Google Colab: [https://colab.research.google.com](https://colab.research.google.com)
2. Click **File > Upload Notebook** and select [`ml/notebooks/cropguard_yolo11s_training.ipynb`](file:///c:/Users/Dell/Desktop/crop_guard/ml/notebooks/cropguard_yolo11s_training.ipynb).
3. Under **Runtime > Change runtime type**, select **T4 GPU** (Hardware Accelerator) and click **Save**.
4. Click **Runtime > Run all**.
5. Once training completes (approx. 20–35 minutes for 75 epochs), Colab will automatically prompt you to download `best.pt` and `best.onnx`.
6. Save the downloaded `best.pt` file into [`ml/weights/best.pt`](file:///c:/Users/Dell/Desktop/crop_guard/ml/weights/best.pt).
