module spi_slave_twiddle (
    input  wire clk,  //clock nội
    input  wire rst_n,         

    // Các chân vật lý kết nối ra ngoài PAD của chip (Giao tiếp SPI)
    input  wire sclk, // SPI Serial Clock do master cấp
    input  wire cs_n, // Chip Select Kéo xuống 0 để bắt đầu truyền
    input  wire mosi, // Master Out Slave In: Đường truyền dữ liệu bit nối tiếp

    // output cho khối NTT
    output reg [11:0] twiddle_data,  // Bus dữ liệu song song 12-bit chứa hệ số xoay zeta (0 <= zeta < 3329)
    output reg twiddle_valid  // Xung báo hệ số mới đã sẵn sàng
);

    //Đồng bộ xung clock nội (CDC)
    reg [2:0] sclk_sync; //3 tầng flipflop, tầng 0 nhận giá trị bên ngoài (chấp nhận metastability), tầng 1 save, tầng 2 để so sánh xem đã có rising edge chưa
    reg [1:0] cs_n_sync; 
    reg [1:0] mosi_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync <= 3'b000;
            cs_n_sync <= 2'b11; // Mặc định khi reset thì cs_n ở mức cao (không truyền)
            mosi_sync <= 2'b00;
        end else begin
            // Dịch bit liên tục ở mỗi cạnh lên xung clk nội
            sclk_sync <= {sclk_sync[1:0], sclk};
            cs_n_sync <= {cs_n_sync[1:0], cs_n};
            mosi_sync <= {mosi_sync[1:0], mosi};
        end
    end

    wire sclk_rising = (sclk_sync[2:1] == 2'b01); // Phát hiện risingedge của xung SCLK: tầng 2 là 0 và tầng 1 là 1

    wire cs_active = ~cs_n_sync[1]; // Kiểm tra trạng thái kích hoạt của chip: CS_N tầng 1 ở mức thấp (lấy [1] để đảm bảo đồng bộ xung)

    reg [15:0] shift_reg; // Thanh ghi dịch 16-bit (trong đó 4 bit cao padding 0000, 12bit cho output của twiddle)
    reg [3:0] bit_cnt;   // Bộ đếm 4-bit (đếm 16 bit dịch)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 16'd0;
            bit_cnt <= 4'd0;
            twiddle_data <= 12'd0;
            twiddle_valid <= 1'b0;
        end else begin
            twiddle_valid <= 1'b0;
            if (!cs_active) begin
                bit_cnt <= 4'd0; //nếu cs_n = 1 thì hủy truyền
            end else if (sclk_rising) begin
                shift_reg <= {shift_reg[14:0], mosi_sync[1]}; // Tại mỗi cạnh lên của SCLK sẽ đẩy bit MOSI mới nhất vào LSB, dịch trái toàn bộ                
                if (bit_cnt == 4'd15) begin // Kiểm tra khi đã nhận đủ 16 bit
                    bit_cnt <= 4'd0; 
                    twiddle_data <= {shift_reg[10:0], mosi_sync[1]}; //vì gán nonblocking nên ở thời điểm bit_cnt = 15 vẫn còn 1 bit ở mosi_sync nên ghép vào nốt
                    twiddle_valid <= 1'b1; //cờ báo hợp lệ
                end else begin
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end
        end
    end

endmodule