//KHỐI FSM ĐIỀU KHIỂN VÀ GIẢI MÃ ĐỊA CHỈ HỆ SỐ XOAY
//Quản lý trạng thái xử lý 7 tầng biến đổi của NTT/INTT (Stage 1 -> Stage 7).
// - Đếm 128 bước xử lý cho mỗi tầng (Tổng: 7 tầng * 128 bước = 896 chu kỳ clock).
// - Điều khiển cấu hình trễ cho khối NMI Reorder qua tín hiệu ctrl_d:
// + Stage 1: ctrl_d = 2'b00 (Trễ 4D)
// + Stage 2: ctrl_d = 2'b01 (Trễ 2D)
// + Stage 3 -> 7: ctrl_d = 2'b10 (Trễ 1D)

module ntt_fsm (
    input wire clk,
    input wire rst_n, 
    input wire start, //xung kích hoạt bắt đầu tính toán NTT/INTT 
    output reg [2:0] current_stage, //tầng biến đổi hiện tại (1 -> 7)
    output reg [1:0] ctrl_d, //cấu hình trễ đầu ra (1d, 2d, 4d)
    output reg done //báo hoàn thành 7 tầng tính toán
);
    localparam [1:0] S_IDLE = 2'b00;
    localparam [1:0] S_RUN = 2'b01;
    localparam [1:0] S_DONE = 2'b10;

    reg [1:0] state; 
    reg [6:0] step_cnt; //bộ đếm 128 bước xử lí trong 1 tầng

    //FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            step_cnt <= 7'd0;
            current_stage <= 3'd1;
            done <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    step_cnt <= 7'd0;
                    current_stage <= 3'd1;
                    if (start) state <= S_RUN;
                end

                S_RUN: begin
                    done <= 1'b0;
                    if (step_cnt == 7'd127) begin
                        step_cnt <= 7'd0;
                        if (current_stage == 3'd7) begin
                            state <= S_DONE;
                        end else begin
                            current_stage <= current_stage + 1'b1;
                        end
                    end else begin
                        step_cnt <= step_cnt + 1'b1;
                    end
                end

                S_DONE: begin
                    done <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    //cấu hình trễ từ trạng thái tầng hiện tại
    always @(*) begin
        case (current_stage) 
            3'd1: ctrl_d = 2'b00; //4D
            3'd2: ctrl_d = 2'b01; //2D
            default: ctrl_d = 2'b10;  //từ tâng 3-7 là 1D  
        endcase
    end
endmodule
