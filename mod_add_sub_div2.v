// KHỐI TÍNH TOÁN CỘNG, TRỪ VÀ CHIA ĐÔI MODULO 3329

module mod_add_sub_div2 (
    input wire [11:0] in_a,
    input wire [11:0] in_b,
    output wire [11:0] out_add,
    output wire [11:0] out_sub,
    output wire [11:0] out_div2
);
    localparam [11:0] Q = 12'd3329;
    
    // Tổng module, nếu tổng > 3329 thì trừ đi 3329 còn < 3329 thì giữ nguyên
    wire [12:0] sum_tmp = in_a + in_b;
    wire [12:0] sum_more_than_3329 = sum_tmp - Q;
    assign out_add = (sum_more_than_3329[12]) ? sum_tmp[11:0] : sum_more_than_3329[11:0];

    // Hiệu module, nếu hiệu < 0 -> cộng thêm 3329
    wire [12:0] sub_tmp = {1'b0, in_a} - {1'b0, in_b};
    assign out_sub = (sub_tmp[12]) ? (sub_tmp[11:0] + Q) : sub_tmp[11:0];

    // Tích chia 2, nếu tổng là chẵn thì chia 2, nếu tổng lẻ thì cộng thêm 3329 rồi chia 2
    wire [12:0] div_odd = out_add + Q;
    assign out_div2 = (out_add[0]) ? div_odd[12:1] : {1'b0, out_add[11:1]};  

endmodule