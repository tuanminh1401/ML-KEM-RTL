// THUẬT TOÁN NHÂN RÚT GỌN MONTGOMERY (MONTGOMERY REDUCTION)
// 1.Tham số hệ thống:
// - Modulus nguyên tố: q = 3329 (12-bit)
// - Montgomery Radix: R = 2^16 = 65536
// - Hằng số nghịch đảo: q_inv = -q^-1 mod R = 62207 (16-bit)
// 2.Các bước toán học:
// - B1: Tính tích c = in_a * in_b
// - B2: Tính hệ số triệt tiêu m = (c mod R) * q_inv mod R = (c[15:0] * 62207) mod 2^16
// - B3: Tính t = (c + m * q) -> Đảm bảo t luôn chia hết cho R (16 bit thấp bằng 0)
// - B4: Chia cho R bằng phép dịch phải: t_high = t / R = t[31:16]
// - B5  Rút gọn điều kiện cuối: Nếu t_high >= q thì out_res = t_high - q, ngược lại lấy t_high

module mod_multiplier (
    input wire clk,
    input wire rst_n,
    input  wire [11:0] in_a,
    input  wire [11:0] in_b,
    output reg  [11:0] out_res
);
    localparam [15:0] Q = 16'd3329; //modulus nguyên tố của ML-KEM
    localparam [15:0] Q_INV = 16'd3327; //-Q^-1 mod 2^16
    
    reg [23:0] c;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c <= 24'd0;
        end else begin 
            c <= in_a * in_b;
        end
    end

    wire [15:0] m = (c[15:0] * Q_INV); // m = (c * Q_INV) mod 2^16: Lấy 16 bit thấp nhất để triệt tiêu 16 bit thấp của (c + m*Q)
    wire [31:0] t = (c + m * Q); // t = c + m * Q: Giá trị cực đại ~ 229,241,500 (< 2^28), biểu diễn đủ trong 32 bit
    wire [15:0] t_high = t[31:16]; //>>16 (chia cho 16) nên lấy 31:16
    wire [16:0] t_sub = {1'b0, t_high} - {1'b0, Q}; //nếu kết quả > 3329 thì trừ đi 3329, thêm 1 bit để làm bit dấu

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_res <= 12'd0;
        end else out_res <= t_sub[16] ? t_high[11:0] : t_sub[11:0]; //kết quả luôn từ 0 - 3328 (biểu diễn đúng 12 bit) nên cắt đi 4 bit cao
    end
endmodule
