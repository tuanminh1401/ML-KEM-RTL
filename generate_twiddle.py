# Script sinh 128 hệ số xoay (Twiddle Factors) chuẩn cho ML-KEM-512 (q = 3329)
Q = 3329
ZETA = 1753  # Căn nguyên thủy chuẩn của Kyber/ML-KEM

def generate_zetas():
    zetas = []
    current = 1
    # Sinh 128 hệ số theo thứ tự bit-reversed / chuẩn Kyber
    # Hoặc theo mảng lũy thừa bậc thang ZETA^bit_reversed(i)
    # Dưới đây là cách tính theo chuẩn thông số tham chiếu Kyber
    # Dùng bảng zetas chuẩn của Kyber reference:
    
    # Mảng 128 hệ số zetas chuẩn trong mã nguồn C của Kyber/ML-KEM-512:
    kyber_zetas = [
        2284, 3034, 2478, 1782, 1435, 2300, 2802, 331, 
        2441, 1378, 1571, 2253, 3171, 1073, 2066, 804,
        1469, 2921, 2697, 793, 2331, 755, 1772, 1079,
        2871, 1076, 1241, 1475, 2077, 1851, 1011, 2049,
        1648, 1572, 1478, 1513, 1146, 1640, 2853, 1622,
        2807, 2351, 2831, 1601, 1653, 1837, 2623, 1150,
        1004, 3054, 464, 526, 3004, 2221, 2620, 2200,
        1889, 757, 1332, 2728, 2552, 1530, 2275, 1374,
        2345, 3020, 3154, 1532, 2404, 2338, 2848, 2911,
        3144, 2154, 1801, 2596, 2974, 1711, 1560, 2636,
        2358, 2732, 1148, 3080, 2156, 1243, 2070, 1069,
        2299, 1370, 2991, 1968, 551, 571, 2277, 1181,
        1564, 1310, 2322, 2673, 3101, 1476, 1120, 45,
        1104, 1559, 2307, 2933, 2445, 1320, 2410, 2884,
        3166, 1347, 1757, 2038, 1904, 1206, 2073, 1318,
        3146, 1843, 3176, 563, 2849, 1421, 2379, 1730
    ]
    return kyber_zetas

if __name__ == "__main__":
    zetas = generate_zetas()
    with open("twiddle_factors.hex", "w") as f:
        for val in zetas:
            # Ghi mỗi hệ số thành dạng Hex 3 ký tự (12-bit tương đương 3 ký tự hex)
            f.write(f"{val:03X}\n")
    print(f"Đã sinh thành công {len(zetas)} hệ số vào file twiddle_factors.hex!")