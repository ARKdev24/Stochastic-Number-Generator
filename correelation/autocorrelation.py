import numpy as np
import matplotlib.pyplot as plt

def load_bitstream(file_path):
    with open(file_path, 'r') as f:
        content = f.read().strip()
        bits = [int(b) for b in content if b in ('0', '1')]
    return np.array(bits, dtype=np.int8)

def compute_autocorrelation(stream, max_lag=20):
    """
    Computes normalized autocorrelation for Lags 0 to max_lag.
    """
    mean = np.mean(stream)
    variance = np.var(stream)
    
    if variance == 0:
        return np.array([1.0] + [0.0] * max_lag)
    
    stream_centered = stream - mean
    n = len(stream)
    
    autocorr = [1.0] # Lag 0 is always 1.0
    for lag in range(1, max_lag + 1):
        # Calculate covariance at lag k
        cov = np.sum(stream_centered[:-lag] * stream_centered[lag:]) / n
        r_k = cov / variance
        autocorr.append(r_k)
        
    return np.array(autocorr)

# --- MAIN EXECUTION ---
if __name__ == "__main__":
    file_name = "bitstream_64n2.txt"
    max_lag = 20
    
    try:
        bits = load_bitstream(file_name)
        N = len(bits)
        
        # Calculate Autocorrelation
        acf = compute_autocorrelation(bits, max_lag=max_lag)
        
        print("=" * 50)
        print(f"       AUTOCORRELATION RESULTS (N = {N} bits)       ")
        print("=" * 50)
        print(f"Stream Probability P(1): {np.mean(bits):.4f}")
        print("-" * 50)
        for lag in range(max_lag + 1):
            print(f"  Lag {lag:2d} : {acf[lag]:+.6f}")
        print("=" * 50)
        
        # Plotting the Autocorrelation Function (ACF)
        plt.figure(figsize=(8, 4))
        plt.stem(range(max_lag + 1), acf)
        plt.axhline(0, color='black', linewidth=0.8, linestyle='--')
        
        # 95% Confidence Bounds for Noise (1.96 / sqrt(N))
        conf_limit = 1.96 / np.sqrt(N)
        plt.axhline(conf_limit, color='red', linestyle=':', label=f'95% Confidence Threshold (±{conf_limit:.4f})')
        plt.axhline(-conf_limit, color='red', linestyle=':')
        
        plt.title(f"Autocorrelation Function (ACF) of Hybrid SNG (N = {N})")
        plt.xlabel("Lag (Clock Cycles)")
        plt.ylabel("Autocorrelation Coefficient r(k)")
        plt.ylim(-0.2, 1.1)
        plt.grid(True, linestyle=':', alpha=0.6)
        plt.legend(loc="upper right")
        plt.tight_layout()
        
        # Save figure for paper
        plt.savefig("autocorrelation_plot.png", dpi=300)
        print("\n[SUCCESS] Plot saved as 'autocorrelation_plot.png'")
        plt.show()

    except FileNotFoundError:
        print(f"Error: Could not find '{file_name}'. Please ensure Vivado generated it.")
