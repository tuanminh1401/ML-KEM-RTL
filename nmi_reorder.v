// KHỐI SẮP XẾP LẠI DỮ LIỆU TUẦN HOÀN NMI
// 1.Mục tiêu:
// - Thay thế hoàn toàn bộ nhớ đệm SRAM/BRAM bằng mảng trễ dịch chuyển tối ưu.
// - Cấu hình linh hoạt 3 chế độ trễ tương ứng với 7 tầng biến đổi của Kyber:
// + Tầng 1: Chế độ 4D (trễ 4 chu kỳ).
// + Tầng 2: Chế độ 2D (trễ 2 chu kỳ).
// + Tầng 3 -> 7: Chế độ 1D (trễ 1 chu kỳ).
// 2. Cơ chế MUX xen kẽ
// - Tầng 1D_a: Nạp data_in trực tiếp từ ngõ ra Butterfly.
// - MUX 0: Nếu ở chế độ 1D, nạp tín hiệu hồi tiếp fb_in vào chuỗi để bảo toàn dữ liệu, ngược lại tiếp tục dịch reg_1d_a sang reg_1d_b.      
// - MUX 1: Nếu ở chế độ 2D, nạp fb_in vào chuỗi, ngược lại tiếp tục dịch reg_1d_b sang reg_2d_a.          
// - Tầng 2D_a -> 2D_b: Tạo thêm 2 nhịp trễ để hoàn thành tổng trễ 4D.
// - MUX ngõ ra: Chọn trích xuất tại điểm trễ tương ứng theo ctrl_d.

module nmi_reorder (
    input  wire clk,
    input  wire rst_n,
    input  wire en, //tín hiệu cho phép dịch tín hiệu, giống clock gating để tối ưu dynamic pơer
    input  wire [1:0]  ctrl_d, // 00: 4D, 01: 2D, 10: 1D
    input  wire [11:0] data_in, //dữ liệu từ khối single_butterfly đưa vào
    input  wire [11:0] fb_in, //đường dẫn hồi tiếp từ nhánh trước
    output reg  [11:0] data_out //dữ liệu sau khi tính toán trễ 
);
    //4 thanh ghi trễ
    reg [11:0] reg_1d_a; //trễ 1 chu kì 1D
    reg [11:0] reg_1d_b; //trễ 2 chu kì 2D
    reg [11:0] reg_2d_a, reg_2d_b; //tạo thêm 2 nhịp trễ -> 4D

    //khối mux giữa các tầng để giảm sử dụng dịch bit (>>)
    wire [11:0] mux0_out = (ctrl_d == 2'b10) ? fb_in : reg_1d_a; //mux sau khối 1d_a để chọn nếu chọn 1D thì đẩy ra fb còn nếu chọn cái sau thì đầu ra sẽ là thanh ghi hiện tại
    wire [11:0] mux1_out = (ctrl_d == 2'b01) ? fb_in : reg_1d_b; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_1d_a <= 12'd0;
            reg_1d_b <= 12'd0;
            reg_2d_a <= 12'd0;
            reg_2d_b <= 12'd0;
        end else if (en) begin
            reg_1d_a <= data_in;
            reg_1d_b <= mux0_out;
            reg_2d_a <= mux1_out;
            reg_2d_b <= reg_2d_a;
        end
    end

    //MUX ngõ ra
    always @(*) begin
        case (ctrl_d) //mux chọn 3 loại
            2'b00: data_out = reg_2d_b; //trễ 4D (tầng 1)
            2'b01: data_out = reg_1d_b; //trễ 2D (tầng 2)
            2'b10: data_out = reg_1d_a; //trễ 1D (tầng 3-7)
            default: data_out = reg_2d_b;
        endcase
    end
endmodule
            
//chỉ tốn 48 DFF