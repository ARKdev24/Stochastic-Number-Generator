import numpy as np
import matplotlib.pyplot as plt

def compute_cross_correlation(file_a, file_b, max_lag=20):
    # 1. Load bitstreams from text files
    stream_a = np.loadtxt(file_a, dtype=int)
    stream_b = np.loadtxt(file_b, dtype=int)

    # Align sequence lengths if they differ
    N = min(len(stream_a), len(stream_b))
    stream_a = stream_a[:N]
    stream_b = stream_b[:N]

    # 2. Zero-mean normalization
    mean_a = np.mean(stream_a)
    mean_b = np.mean(stream_b)
    std_a  = np.std(stream_a)
    std_b  = np.std(stream_b)

    a_norm = stream_a - mean_a
    b_norm = stream_b - mean_b

    lags = np.arange(-max_lag, max_lag + 1)
    cross_corr = []

    # 3. Calculate normalized cross-correlation coefficient for each lag k
    for k in lags:
        if k < 0:
            corr = np.mean(a_norm[:k] * b_norm[-k:]) / (std_a * std_b)
        elif k > 0:
            corr = np.mean(a_norm[k:] * b_norm[:-k]) / (std_a * std_b)
        else:
            corr = np.mean(a_norm * b_norm) / (std_a * std_b)
        cross_corr.append(corr)

    return lags, np.array(cross_corr), N

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================
if __name__ == "__main__":
    # Specify the two bitstream files to compare
    file_stream_1 = "bitstream_64n3.txt"  # First run (Seed 1)
    file_stream_2 = "bitstream_64n2.txt"  # Second run (Seed 2)

    lags, r_xy, N = compute_cross_correlation(file_stream_1, file_stream_2, max_lag=20)

    # Calculate 95% Confidence Bounds for independent white noise
    conf_bound = 1.96 / np.sqrt(N)

    # Display numeric output in console
    print(f"--- CROSS-CORRELATION RESULTS (N = {N}) ---")
    for lag, val in zip(lags, r_xy):
        print(f"Lag {lag:+3d} : {val:+.6f}")

    # Plot cross-correlation graph
    plt.figure(figsize=(10, 5))
    plt.stem(lags, r_xy, basefmt=" ")
    plt.axhline(0, color='black', linewidth=0.8)
    plt.axhline(conf_bound, color='red', linestyle='--', label=f'95% Confidence Bound (±{conf_bound:.4f})')
    plt.axhline(-conf_bound, color='red', linestyle='--')
    
    plt.title(f"Cross-Correlation R_XY(k) Between Two Independent Streams (N = {N})")
    plt.xlabel("Lag (k)")
    plt.ylabel("Cross-Correlation Coefficient R_XY")
    plt.ylim(-0.25, 0.25)
    plt.grid(True, linestyle=':', alpha=0.6)
    plt.legend()
    plt.tight_layout()
    plt.show()
