`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 16:28:18
// Design Name: 
// Module Name: axi_insert_header_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi_insert_header_tb;

    parameter DATA_WD = 32;
    parameter DATA_BYTE_WD = DATA_WD / 8;
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD);
    
    reg                                     clk;
    reg                                     rst_n;
    
    // Data_inͨ���˿�
    reg                                     valid_in;
    reg         [DATA_WD-1:0]               data_in;
    reg         [DATA_BYTE_WD-1:0]          keep_in;
    reg                                     last_in;
    wire                                    ready_in;
    
    // Data_outͨ���˿�
    wire        [DATA_WD-1:0]               data_out;
    wire                                    valid_out;
    wire        [DATA_BYTE_WD-1:0]          keep_out;
    wire                                    last_out;
    reg                                     ready_out;
    
    // Head_insert ͨ���˿�
    reg                                     valid_insert;
    reg         [DATA_WD-1:0]               data_insert;
    reg         [DATA_BYTE_WD-1:0]          keep_insert;
    reg         [BYTE_CNT_WD:0]             byte_insert_cnt;
    wire                                    ready_insert;
    
axi_stream_insert_header #(
     .DATA_WD (DATA_WD),
     .DATA_BYTE_WD(DATA_BYTE_WD),
     .BYTE_CNT_WD (BYTE_CNT_WD)
) axi_stream_insert_header_U1 (
        .clk                    (   clk             ),
        .rst_n                  (   rst_n           ),   
        .valid_in               (   valid_in        ),
        .data_in                (   data_in         ),
        .keep_in                (   keep_in         ),
        .last_in                (   last_in         ),
        .ready_in               (   ready_in        ),
        .valid_out              (   valid_out       ),
        .data_out               (   data_out        ),
        .keep_out               (   keep_out        ),
        .last_out               (   last_out        ),
        .ready_out              (   ready_out       ),
        .valid_insert           (   valid_insert    ),
        .data_insert            (   data_insert     ),
        .keep_insert            (   keep_insert     ),
        .byte_insert_cnt        (   byte_insert_cnt ),
        .ready_insert           (   ready_insert    )    
);
always #10 clk = ~clk;
//��λ
initial begin
    clk = 0;
    rst_n = 0;
    valid_in = 0;
    data_in = 0;
    keep_in = 0;
    last_in = 0;
    ready_out = 0;
    valid_insert = 0;
    data_insert = 0;
    keep_insert = 0;
    byte_insert_cnt = 0;
    #20
    rst_n = 1;
end
    reg         [DATA_BYTE_WD-1:0]      valid_random;
always@(posedge clk)    begin
        valid_random = {$random}%10;
        if(ready_in)    begin
            repeat (valid_random) @(posedge clk);
            valid_in <= 0;
            repeat (1) @(posedge clk);
            valid_in <= 1;
        end
        else    begin                       // ����ʧ��ʱvalid_inҪ���ֲ���
            valid_in <= valid_in;
        end
end
// ������� ready_out
    reg     [DATA_BYTE_WD-1:0]      ready_out_random;
    always@(posedge clk)    begin
         ready_out_random = $random % 10;
         repeat (ready_out_random) @(posedge clk);
         ready_out <= 0;
         repeat (1) @(posedge clk);
         ready_out <= 1;
    end
    
    reg         [DATA_BYTE_WD-1:0]      burst_trans_cnt;            // һ��ͻ�����䴫�ݼ������ݣ���20�����ڣ�
    reg                                 start_burst;                // ��ʼͻ������ı�־
    reg         [DATA_BYTE_WD-1:0]      trans_cnt;                  //  �Ѿ�����ĸ���
    
always@(posedge clk)    begin
        if(!rst_n)      burst_trans_cnt <= 0;
        else if((trans_cnt == 0) && ready_in && valid_in)   burst_trans_cnt <= {$random}%20;     // ����burst���䣬����һ��burst_trans_cnt
        else            burst_trans_cnt <= burst_trans_cnt;
    end
    
    // �������last_data��keep
    reg         [BYTE_CNT_WD:0]         last_keep_cnt;
    always @(posedge clk)   begin   
        if(!rst_n)      last_keep_cnt <= 0;
        else if(trans_cnt == 0)     last_keep_cnt <= {$random}%4;
        else            last_keep_cnt <= last_keep_cnt;
    end
    
always @(posedge clk)   begin
        if(!rst_n)  begin
            data_in <= 0;
            last_in <= 0;
            trans_cnt <= 0;    
            keep_in <= 4'b1111;
            start_burst <= 0;  
        end
        else if(ready_in && valid_in)   begin                       // ���ֳɹ�
            trans_cnt <= trans_cnt + 1;     
            if(trans_cnt == burst_trans_cnt + 1)  begin             // ���һ��data_in
                    data_in <= {$random}%2**(DATA_WD-1)-1;  
                    keep_in <= 4'b1111 << (4 - last_keep_cnt);
                    last_in <= 1;
                    start_burst <= 1;  
            end
            else if(start_burst)    begin                              // һ��burst������ɺ�
                    data_in <= 0;  
                    last_in <= 0;
                    keep_in <= 4'b1111;
                    trans_cnt <= 0;
                    start_burst <= 0;      
            end
            else    begin
                    data_in <= {$random}%2**(DATA_WD-1)-1; 
                    keep_in <= 4'b1111;
                    last_in <= 0;
                    start_burst <= 0;      
            end
        end
        else    begin                       // ����ʧ�ܣ����β��ܽ������ݣ��������ݱ��ֲ���
            data_in <= data_in;
            keep_in <= keep_in;
            last_in <= last_in; 
            trans_cnt <= trans_cnt; 
            start_burst <= start_burst;     
        end
    end
      
    ///////////////////////////////  Head_inset ͨ���ļ��� ///////////////////////// 
    
    reg         [DATA_BYTE_WD-1:0]      insert_valid_random;
always@(posedge clk)    begin
        insert_valid_random = {$random}%10;
        if(ready_insert)    begin
            repeat (insert_valid_random) @(posedge clk);
            valid_insert <= 0;
            repeat (1) @(posedge clk);
            valid_insert <= 1;
        end
        else    begin                           // ����ʧ��ʱvalid_insertҪ���ֲ���
            valid_insert <= valid_insert;
        end
    end
    
    // �������byte_insert_cnt 
always @(posedge clk)   begin
        if(!rst_n)  begin
            data_insert <= {$random}%2**(DATA_WD-1)-1;
            keep_insert <= 4'b0111;
            byte_insert_cnt <= 1;
        end
        else if(valid_insert && ready_insert)   begin       // ���ֳɹ�������ֵ
            data_insert <= {$random}%2**(DATA_WD-1)-1;
            keep_insert <= 4'b0011;
            byte_insert_cnt <= 2;
        end
        else    begin               // ����ʧ�ܣ����ֲ���
            data_insert <= data_insert; 
            keep_insert <= keep_insert;
            byte_insert_cnt <= byte_insert_cnt;
        end     
    end


endmodule
