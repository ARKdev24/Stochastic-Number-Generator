import numpy as np

def calculate_scc(sn_x, sn_y):
    """
    Calculates the Stochastic Correlation (SCC) between two stochastic bitstreams.
    
    Parameters:
        sn_x (array-like): First stochastic bitstream (0s and 1s)
        sn_y (array-like): Second stochastic bitstream (0s and 1s)
        
    Returns:
        float: SCC value bounded between -1.0 (maximal negative correlation) 
               and +1.0 (maximal positive correlation).
    """
    sn_x = np.asarray(sn_x, dtype=int)
    sn_y = np.asarray(sn_y, dtype=int)
    
    if len(sn_x) != len(sn_y):
        raise ValueError(f"Bitstream lengths do not match ({len(sn_x)} vs {len(sn_y)}).")
        
    n = len(sn_x)
    
    # 1. Count overlap occurrences (a, b, c, d)
    a = np.sum((sn_x == 1) & (sn_y == 1))  # Both 1
    b = np.sum((sn_x == 1) & (sn_y == 0))  # SN_x = 1, SN_y = 0
    c = np.sum((sn_x == 0) & (sn_y == 1))  # SN_x = 0, SN_y = 1
    d = np.sum((sn_x == 0) & (sn_y == 0))  # Both 0
    
    # 2. Compute ad and bc terms
    ad = float(a * d)
    bc = float(b * c)
    numerator = ad - bc
    
    # 3. Apply Eq. 1 conditional logic
    if ad > bc:
        denominator = n * min(a + b, a + c) - (a + b) * (a + c)
    else:
        denominator = (a + b) * (a + c) - n * max(a - d, 0)
        
    # Guard against division by zero (e.g., if one bitstream is entirely all 0s or all 1s)
    if denominator == 0:
        return 0.0
        
    return numerator / denominator


# ==============================================================================
# EXAMPLE USAGE WITH YOUR 100,000 BIT FILES
# ==============================================================================
if __name__ == "__main__":
    # Load your generated bitstreams
    stream_A = np.loadtxt("bitstream_64n3.txt", dtype=int)
    stream_B = np.loadtxt("bitstream_64n2.txt", dtype=int)
    
    scc_val = calculate_scc(stream_A, stream_B)
    
    print("\n" + "="*45)
    print("--- STOCHASTIC CORRELATION (SCC) RESULTS ---")
    print("="*45)
    print(f"Stream Length (n) : {len(stream_A):,}")
    print(f"Calculated SCC    : {scc_val:+.6f}")
    print("="*45)
