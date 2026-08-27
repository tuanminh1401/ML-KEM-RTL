//KHỐI TÍNH TOÁN NTT VÀ INTT
//Công thức NTT: (mode 0) với ngõ vào a, b và hệ số xoay zeta
// - y_0 = a + (b x zeta) (mod q)
// - y_1 = a - (b x zeta) (mod q)
// -> Nhân trước cộng trừ sau (u_post)

//Công thức INTT: (mode 1) với ngõ vào a, b và hệ số xoay nghịch w = zeta^-1;
// - y_0 = (a + b) / 2 (mod q)
// - y_1 = ((a - b) / 2) x w (mod q) = (a - b) x zeta (mod q)
// -> cộng trừ trước (u_pre) -> nhân sau

module single_butterfly (
    input  wire clk,
    input  wire rst_n,
    input  wire mode,   // 0: NTT (CT), 1: INTT (GS)
    input  wire [11:0] in_a,
    input  wire [11:0] in_b,
    input  wire [11:0] in_twiddle, //Hệ số xoay tùy biến (có thể là w hoặc zeta)
    output wire [11:0] out_y0,
    output wire [11:0] out_y1
);
    //Khối xử lí trước để lấy pre_sub_res và pre_div2_res cho tác vụ sau
    wire [11:0] pre_add_res, pre_sub_res, pre_div2_res;  
    mod_add_sub_div2 u_pre (
        .in_a    (in_a),
        .in_b    (in_b),
        .out_add (pre_add_res),
        .out_sub (pre_sub_res),
        .out_div2(pre_div2_res)
    );

    wire [11:0] mul_op_b = mode ? pre_sub_res : in_b; //nếu mode = 1 (INTT) lấy giá trị a - b, nếu mode = 0 lấy giá trị b
    wire [11:0] mul_out;
    mod_multiplier u_mul (
        .clk(clk),
        .rst_n(rst_n),
        .in_a(in_twiddle),
        .in_b(mul_op_b),
        .out_res(mul_out) //kết quả: nếu mode = 1 (INTT) -> (a - b) * (w * 2^-1 = zeta) còn nếu mode = 0 -> b * zeta
    );

    //2 tầng flipflop mục đích đồng bộ trễ với khối mod_multiplier
    reg [11:0] in_a_ff1, in_a_ff2; //2 tầng flipflop cho tín hiệu in_a (in_b và sub không cần 2ff vì đã được đưa thẳng vào mod_multiplier ở trên)
    reg [11:0] div2_ff1, div2_ff2; //2 tầng flipflop cho đầu ra div2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_a_ff1 <= 12'd0;
            in_a_ff2 <= 12'd0;
            div2_ff1 <= 12'd0;
            div2_ff2 <= 12'd0;
        end else begin
            in_a_ff1 <= in_a;
            in_a_ff2 <= in_a_ff1;
            div2_ff1 <= pre_div2_res;
            div2_ff2 <= div2_ff1;
        end
    end

    //Khối xử lí sau để lấy post_sub_res và post_add_res
    wire [11:0] post_add_res, post_sub_res, post_div2_res; 
    mod_add_sub_div2 u_post (
        .in_a(in_a_ff2),
        .in_b(mul_out),
        .out_add(post_add_res),
        .out_sub(post_sub_res),
        .out_div2(post_div2_res)
    );

    assign out_y0 = mode ? div2_ff2 : post_add_res; //lấy thẳng div2_ff2 mà không lấy post_div2_res vì mod_multiplier đã cấu hình cho đầu ra khối div2 là (a + b) / 2
    assign out_y1 = mode ? mul_out : post_sub_res;
endmodule

    