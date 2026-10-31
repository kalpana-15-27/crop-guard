"""CropGuard AI: YOLO11s Fine-Tuning Execution Script

Fine-tunes pretrained YOLO11s on the verified 6-class agricultural pest dataset.
Exports optimized PyTorch weights (best.pt) and ONNX runtime weights.
"""

import os
import argparse
import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("CropGuard.Train")


def run_training(
    data_config: str,
    epochs: int = 50,
    batch_size: int = 16,
    imgsz: int = 640,
    device: str = "0",
    weights_output_dir: str = "../weights"
):
    try:
        from ultralytics import YOLO
    except ImportError:
        logger.error("Ultralytics package is not installed. Please run on Colab GPU or install 'ultralytics'.")
        return

    logger.info("Initializing YOLO11s model from pretrained weights (yolo11s.pt)...")
    model = YOLO("yolo11s.pt")

    logger.info(f"Starting fine-tuning with config={data_config}, epochs={epochs}, batch={batch_size}, imgsz={imgsz}...")
    results = model.train(
        data=data_config,
        epochs=epochs,
        batch=batch_size,
        imgsz=imgsz,
        device=device,
        patience=15,          # Early stopping patience
        save=True,
        save_period=10,
        cache=True,
        workers=4,
        project="cropguard_training",
        name="yolo11s_pests",
        exist_ok=True,
        verbose=True
    )

    # Locate and copy best weights
    best_weights_path = Path("cropguard_training/yolo11s_pests/weights/best.pt")
    os.makedirs(weights_output_dir, exist_ok=True)
    target_best = os.path.join(weights_output_dir, "best.pt")

    if best_weights_path.exists():
        import shutil
        shutil.copy2(best_weights_path, target_best)
        logger.info(f"Saved best model weights to: {target_best}")

        # Export to ONNX for cross-platform high-efficiency runtime
        logger.info("Exporting trained model to ONNX format...")
        trained_model = YOLO(target_best)
        trained_model.export(format="onnx", dynamic=False, simplify=True)
        logger.info(f"Exported ONNX weights to: {os.path.join(weights_output_dir, 'best.onnx')}")
    else:
        logger.warning(f"Expected weights at {best_weights_path} not found.")

    return results


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train YOLO11s for CropGuard AI")
    parser.add_argument("--data", type=str, default="../configs/dataset.yaml", help="Path to dataset.yaml")
    parser.add_argument("--epochs", type=int, default=50, help="Number of training epochs")
    parser.add_argument("--batch", type=int, default=16, help="Batch size")
    parser.add_argument("--imgsz", type=int, default=640, help="Image resolution")
    parser.add_argument("--device", type=str, default="0", help="GPU device index or 'cpu'")
    parser.add_argument("--output", type=str, default="../weights", help="Weights output directory")

    args = parser.parse_args()
    run_training(
        data_config=args.data,
        epochs=args.epochs,
        batch_size=args.batch,
        imgsz=args.imgsz,
        device=args.device,
        weights_output_dir=args.output
    )
