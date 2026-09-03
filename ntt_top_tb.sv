`timescale 1ns/1ps

module ntt_top_tb;
    timeunit 1ns;
    timeprecision 1ps;

    //khai báo
    logic clk;
    logic rst_n;
    logic start;
    logic mode;
    logic sclk;
    logic cs_n;
    logic mosi;
    logic [11:0] data_in;
    logic [11:0] data_out;
    logic done;

    //T = 10ns (100MHz) clk nội
    always #5ns clk = ~clk;

    ntt_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .mode(mode),
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .data_in(data_in),
        .data_out(data_out),
        .done(done)
    );

    //nạp vector chuẩn từ c2sp cctv (mk-kem-512)
    //bảng 256 đa thức đầu vào
    logic [11:0] poly_in_mem [0:255] = '{
        1, 0, 3328, 1, 3328, 0, 0, 2, 0, 3328, 1, 0, 2, 2, 0, 3328, 3328, 2, 1, 3328, 
        3328, 1, 3328, 1, 0, 0, 1, 3328, 3328, 1, 3327, 0, 3328, 0, 1, 1, 0, 1, 0, 0, 
        3328, 3327, 1, 0, 3328, 0, 1, 1, 3328, 0, 3328, 2, 1, 0, 0, 2, 1, 2, 1, 3328, 
        0, 1, 3326, 3327, 1, 0, 0, 2, 3326, 3328, 0, 3328, 3328, 3327, 1, 3328, 3328, 
        3327, 0, 0, 1, 2, 3, 2, 1, 3327, 3328, 0, 3, 1, 0, 0, 2, 1, 0, 0, 3328, 3327, 
        0, 0, 1, 1, 0, 1, 1, 3328, 3327, 1, 1, 3328, 0, 0, 0, 3327, 3328, 2, 1, 0, 
        3328, 1, 3327, 1, 0, 0, 3327, 3328, 2, 0, 0, 0, 1, 0, 1, 3328, 0, 1, 0, 3328, 
        3328, 1, 1, 1, 3328, 2, 1, 1, 1, 3328, 3328, 3328, 3328, 3328, 2, 1, 1, 3328, 
        1, 0, 0, 1, 3328, 1, 3328, 1, 1, 2, 3, 0, 0, 0, 3328, 0, 0, 1, 2, 3328, 3327, 
        3327, 1, 1, 3328, 3328, 3328, 1, 1, 2, 0, 3328, 1, 3328, 3328, 3327, 0, 0, 0, 
        3328, 3328, 1, 0, 1, 3326, 3327, 3328, 3327, 1, 2, 3326, 3328, 1, 0, 0, 0, 1, 
        0, 0, 3, 3, 3327, 1, 3328, 3328, 0, 0, 2, 1, 3328, 0, 0, 0, 0, 0, 0, 3328, 0, 
        0, 1, 0, 0, 0, 3328, 3328, 3328, 0, 3327, 0, 1, 3328, 3328, 0, 3328, 0, 2, 0, 
        0, 1, 3328
    };

    int in_idx; //con trỏ duyệt mảng đa thức từ 0 -> 255
    int cycle_count;
    bit counting; //báo hiệu đang tính toán

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_idx <= 1'b0;
            data_in <= 12'd0;
        end else if (counting) begin
            data_in <= poly_in_mem[in_idx[7:0]];
            in_idx <= in_idx + 1;
        end else begin
            in_idx <= 1'b0;
            data_in <= poly_in_mem[0];
        end
    end

    //đo độ trễ từ start -> done
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= 0;
            counting <= 1'b0;
        end else begin
            if (start) begin
                counting <= 1'b1;
                cycle_count <= 0;
            end else if (done) begin
                counting <= 1'b0;
            end else if (counting) begin
                cycle_count++; //tăng mỗi rising edge của clk nội
            end
        end
    end

    //cấu hình spi mode 0 (CPOL = 0, CPHA = 0)-> khi rỗi (IDLE) sclk = 0, dữ liệu mosi được master thay đổi ở cạnh xuống, slave lấy dự liệu tại cạnh lên của sclk
    task automatic run_test(
        input logic [11:0] twiddle_value
    );
    logic [15:0] spi_frame; //khung truyền 16bit
    spi_frame = {4'b0000, twiddle_value};
    cs_n = 1'b0; //bắt đầu truyền
    #20ns;

    for (int i = 15; i >= 0; i--) begin
        mosi = spi_frame[i];
        sclk = 1'b0;
        #20ns;
        sclk = 1'b1; //rising edge để chốt bit
        #20ns;
    end
    
    sclk = 1'b0; //trả sclk về mức thấp
    #20ns;
    cs_n = 1'b1; // hoàn tất truyền
    #40ns;
    endtask
    
    localparam int Q = 3329;
    localparam logic [11:0] exp_data_out = 12'd2594; //chuẩn đầu ra với zeta = 1665

    function automatic int golden_model_mul(int a, int b);
        longint prod;
        prod = (longint'(a) * longint'(b)) % Q;
        return int'(prod);
    endfunction

    function automatic void golden_ct_butterfly (
        input int a,
        input int b,
        input int zeta,
        output int exp_y0,
        output int exp_y1
    );
        int term;
        term = golden_model_mul(b, zeta);
        exp_y0 = (a + term) % Q;
        exp_y1 = (a - term) % Q;
        if (exp_y1 < 0) exp_y1 += Q;
    endfunction

    int exp_y0, exp_y1;

    //kiểm thử
    initial begin
        clk = 1'b0;
        rst_n = 1'b0; //băt đầu ở reset
        start = 1'b0;
        mode = 1'b0; // NTT
        sclk = 1'b0;
        cs_n = 1'b1; // không truyền
        mosi = 1'b0;

        #40ns;
        rst_n = 1'b1;
        #40ns;

        $display("=================================================");
        $display("Khoi tao vector da thuc dau vao s[0]");
        $display("- s[0][0] = %0d", poly_in_mem[0]);
        $display("- s[0][255] = %0d", poly_in_mem[255]);
        $display("=================================================");

        //nạp hệ số xoay 1665 
        run_test(12'd1665);
        $display("Nap thanh cong he so xoay: zeta = 1665");

        golden_ct_butterfly (
            .a(int'(poly_in_mem[0])),
            .b(int'(poly_in_mem[1])),
            .zeta(1665),
            .exp_y0(exp_y0),
            .exp_y1(exp_y1)
        );
        $display(" - Kiem tra canh buom don vi: y0 = %0d, y1 = %0d", exp_y0, exp_y1);

        $display("kich hoat xung start, loi NTT bat dau xu li 7 tang");
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        
        //đơi done
        @(posedge done);
        @(posedge clk); //đợi 1 chu kì để data_out ổn định

        $display("=================================================");
        $display("Ket qua");
        $display("Phat hien xung done -> hoan thanh thuat toan");
        $display("Tong thoi gian: %0d chu ki clock", cycle_count);
        $display(" - Gia tri ngõ ra RTL : %0d", data_out);
        $display(" - Gia tri moc ky vong: %0d", exp_data_out);

        //check xem có đúng 128 x 7 = 896 chu kì không
        assert (cycle_count == 896)
            $display("PASS ASSERTION!");
        else
            $error("FAIL ASSERTION!");
        
        //check kết quả sau 7 tầng
        assert (data_out == exp_data_out)
            $display("Gia tri data_out = Ky vong (%0d == %0d)!", data_out, exp_data_out);
        else
            $error("Sai gia tri: RTL = %0d != Ky vong = %0d", data_out, exp_data_out);

        // Xác minh tính toàn vẹn 
        assert (data_out < Q)
            $display("Gia tri hop le trong truong (0 <= %0d < 3329)", data_out);
        else
            $error("Gia tri vuot bien modulo: %0d >= 3329", data_out);

        $display("=================================================");

        #100ns;
        $stop;
        
    end
endmodule