// KHỐI TOP-LEVEL

module ntt_top (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire mode,
    input wire [11:0] data_in,
    output wire [11:0] data_out,
    output wire done //cờ báo hoàn thành 7 tầng biến đổi
);
    wire [2:0] current_stage;
    wire [1:0] ctrl_d;
    wire [6:0] twiddle_addr;
    wire [11:0] twiddle_data;

    wire [11:0] out_y0, out_y1;
    wire [11:0] reorder_out; //dữ liệu trích xuất sau nmi rồi vòng lại vào single-butterfly

    //Khối fsm và rom hệ số xoay
    ntt_fsm_rom u_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .current_stage(current_stage),
        .ctrl_d(ctrl_d),
        .twiddle_addr(twiddle_addr),
        .twiddle_data(twiddle_data),
        .done(done)
    );

    //Khối single-butterfly
    single_butterfly u_butterfly (
        .clk(clk),
        .rst_n(rst_n),
        .mode(mode),
        .in_a(reorder_out), //sau khi qua nmi 7 tầng sẽ vòng lại in_a của single-butterfly để tính toán lại từ đầu
        .in_b(data_in),
        .in_twiddle(twiddle_data),
        .out_y0(out_y0),
        .out_y1(out_y1)
    );

    //Khối NMI
    nmi_reorder u_reorder (
        .clk(clk),
        .rst_n(rst_n),
        .en(!done), // en kích hoạt khi hệ thống đang chạy để tiết kiệm năng lượng
        .ctrl_d(ctrl_d),
        .data_in(out_y0),
        .fb_in(out_y1),
        .data_out(reorder_out)
    );

    assign data_out = out_y1;
endmodule

