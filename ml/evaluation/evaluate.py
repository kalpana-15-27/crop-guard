"""CropGuard AI: Model Evaluation and Inference Benchmarking Script

Evaluates trained YOLO11s weights against the held-out test split.
Outputs Precision, Recall, F1-Score, mAP@50, mAP@50:95, and latency benchmarks.
"""

import time
import argparse
import logging
import numpy as np

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("CropGuard.Evaluation")


def run_evaluation(weights_path: str, data_config: str, device: str = "cpu"):
    try:
        from ultralytics import YOLO
    except ImportError:
        logger.error("Ultralytics package not installed.")
        return

    logger.info(f"Loading trained weights from: {weights_path}")
    model = YOLO(weights_path)

    # 1. Validation on Test Split
    logger.info(f"Running validation on test split defined in {data_config}...")
    metrics = model.val(
        data=data_config,
        split="test",
        device=device,
        verbose=True
    )

    # Extract comprehensive metrics
    mp = metrics.box.mp           # Mean precision
    mr = metrics.box.mr           # Mean recall
    map50 = metrics.box.map50     # mAP @ IoU 0.50
    map = metrics.box.map         # mAP @ IoU 0.50:0.95
    f1 = 2 * (mp * mr) / (mp + mr + 1e-8)

    print("\n" + "=" * 60)
    print("           CROPGUARD AI — YOLO11s EVALUATION SUMMARY           ")
    print("=" * 60)
    print(f"Overall Mean Precision (P) : {mp * 100:.2f}%")
    print(f"Overall Mean Recall (R)    : {mr * 100:.2f}%")
    print(f"Overall Harmonic F1-Score  : {f1 * 100:.2f}%")
    print(f"mAP @ 0.50                 : {map50 * 100:.2f}%")
    print(f"mAP @ 0.50:0.95            : {map * 100:.2f}%")
    print("-" * 60)

    # Per-Class Metrics
    print("PER-CLASS EVALUATION BREAKDOWN:")
    for i, cname in model.names.items():
        try:
            cp = metrics.box.p[i]
            cr = metrics.box.r[i]
            cmap50 = metrics.box.ap50[i]
            cf1 = 2 * (cp * cr) / (cp + cr + 1e-8)
            print(f"  [{i}] {cname:<24} | P: {cp*100:5.1f}% | R: {cr*100:5.1f}% | F1: {cf1*100:5.1f}% | mAP50: {cmap50*100:5.1f}%")
        except Exception:
            pass
    print("=" * 60 + "\n")

    # 2. Latency Benchmarking (100 synthetic iterations)
    logger.info("Running inference latency benchmark (100 iterations)...")
    dummy_input = np.random.randint(0, 255, (640, 640, 3), dtype=np.uint8)

    # Warmup
    for _ in range(10):
        model.predict(dummy_input, verbose=False, device=device)

    times = []
    for _ in range(100):
        t0 = time.perf_counter()
        model.predict(dummy_input, verbose=False, device=device)
        times.append(time.perf_counter() - t0)

    mean_latency_ms = float(np.mean(times) * 1000)
    std_latency_ms = float(np.std(times) * 1000)
    fps = 1000.0 / mean_latency_ms

    print("-" * 60)
    print(f"Device                     : {device.upper()}")
    print(f"Average Inference Latency : {mean_latency_ms:.2f} ms (+/- {std_latency_ms:.2f} ms)")
    print(f"Throughput                 : {fps:.1f} FPS")
    print("-" * 60 + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Evaluate YOLO11s Model")
    parser.add_argument("--weights", type=str, default="../weights/best.pt", help="Path to best.pt weights")
    parser.add_argument("--data", type=str, default="../configs/dataset.yaml", help="Path to dataset.yaml")
    parser.add_argument("--device", type=str, default="cpu", help="Device: 'cpu' or '0'")

    args = parser.parse_args()
    run_evaluation(weights_path=args.weights, data_config=args.data, device=args.device)
