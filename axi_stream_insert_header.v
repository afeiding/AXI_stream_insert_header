`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 10:23:49
// Design Name: 
// Module Name: axi_stream_insert_header
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


module axi_stream_insert_header #(
    parameter DATA_WD = 32,
    parameter DATA_BYTE_WD  = DATA_WD/8,
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
)(
input clk,
input rst_n,
// AXI Stream input original data
input valid_in,
input [DATA_WD-1 : 0] data_in,
input [DATA_BYTE_WD-1 : 0] keep_in,
input last_in,
output ready_in,
// AXI Stream output with header inserted
output valid_out,
output [DATA_WD-1 : 0] data_out,
output [DATA_BYTE_WD-1 : 0] keep_out,
output last_out,
input ready_out,
// The header to be inserted to AXI Stream input
input valid_insert,
input [DATA_WD-1 : 0] data_insert,
input [DATA_BYTE_WD-1 : 0] keep_insert,
input [BYTE_CNT_WD-1 : 0] byte_insert_cnt,
output ready_insert
    );
    
reg [DATA_WD-1:0] header_reg;
reg [DATA_BYTE_WD-1 : 0] keep_insert_reg;

//����˿�reg
reg valid_out_r;
reg last_out_r;
reg ready_insert_r;
reg [DATA_WD-1 : 0] data_out_r;
reg [DATA_BYTE_WD-1 : 0] keep_out_r;

assign    ready_insert = ready_insert_r;
assign    valid_out = valid_out_r;
assign    last_out = last_out_r;
assign    data_out =  data_out_r;
assign    keep_out = keep_out_r;
assign    ready_in = ready_out && ~ready_insert_r;     //����ģ���ܽ���������headͨ�����ֳɹ�֮�� data_in ���ܿ�ʼ��������

//header insertͨ����buf
reg [DATA_WD-1 : 0] data_insert_buf;
reg [DATA_BYTE_WD-1 : 0] keep_insert_buf;
reg [BYTE_CNT_WD-1 : 0] byte_insert_cnt_buf;
//�ж�burst��Ҫ�õı���
reg  overflow;
reg [DATA_BYTE_WD-1:0] last_keep;
reg [DATA_WD-1 : 0]    last_data_out;

//header insert dataͨ��
always@(posedge clk)begin
    if(!rst_n)begin
        ready_insert_r <= 0;
        keep_insert_buf <= 0;
        byte_insert_cnt_buf <= 0;
    end
    else if(ready_insert_r && valid_insert)begin
        ready_insert_r <= 0;
        keep_insert_buf <= keep_insert;
        byte_insert_cnt_buf <= byte_insert_cnt;
    end
    else if(last_out)begin
        ready_insert_r <= 1;
        keep_insert_buf <= 0;
        byte_insert_cnt_buf <= 0;
    end
    else begin
        ready_insert_r <= ready_insert;
        keep_insert_buf <= keep_insert_buf;
        byte_insert_cnt_buf <= byte_insert_cnt_buf;
    end
end
always@(posedge clk)begin
    if(!rst_n)begin
        data_insert_buf <= 0;
    end
    else if(ready_insert && valid_insert)begin
        data_insert_buf <= data_insert;
    end
    else if(ready_in && valid_in)begin
        data_insert_buf <= data_in;
    end
    else begin
        data_insert_buf <= data_insert_buf;
    end
end
//�ж�burst���һ��������Ҫ����
always @(posedge clk)       begin
    if(!rst_n)      begin        
        overflow <= 0;
        last_keep <= 0;    
        last_data_out <= 0;
    end
    else if(valid_in && ready_in && last_in)        begin
        if((keep_in & keep_insert_buf) == 0)    begin           // ���һ��data_inһ�ľ��ܴ���ȥ
            overflow <= 0;
            last_keep <= 0;
            last_data_out <= 0;
        end
        else        begin                                       // ���һ��data_inҪ�����ķ���        
            overflow <= 1;
            last_keep <= (keep_in & keep_insert_buf) << DATA_BYTE_WD - byte_insert_cnt_buf;        // 1110 & 0011 = 0010 << 2 ---> 1000
            last_data_out <= data_in << (DATA_BYTE_WD - byte_insert_cnt_buf) * 8;
        end
    end
    else        begin       
        overflow <= 0;
        last_keep <= 0;    
        last_data_out <= 0;
    end
end
//burst����߼�
always@(posedge clk)begin
    if(!rst_n)begin
        data_out_r <= 0;
        valid_out_r <= 0;
        keep_out_r <= 0;
        last_out_r <= 0;
    end
    else if(ready_in && valid_in)begin
        data_out_r <= (data_insert_buf << (DATA_WD - byte_insert_cnt_buf * 8))|(data_in >> (byte_insert_cnt_buf * 8));
        valid_out_r <= valid_in;
        keep_out_r <= (keep_insert_buf << (DATA_BYTE_WD - byte_insert_cnt_buf)) | (keep_in >> byte_insert_cnt_buf);
        last_out_r <= ((keep_in & keep_insert_buf) == 0) ? 1 : 0;
    end
    else if(overflow) begin
        data_out_r <= last_data_out;
        valid_out_r <= 1'b1;
        keep_out_r <= last_keep;
        last_out_r <= 1'b1;
    end
    else if(last_out_r)begin
        data_out_r <= 0;
        valid_out_r <= 1'b0;
        keep_out_r <= 0;
        last_out_r <= 1'b0;
    end
    else begin
        data_out_r <= data_out_r;
        valid_out_r <= (valid_in == 0)? 0 :valid_out_r;
        keep_out_r <= keep_out_r;
        last_out_r <= last_out_r;
    end
end

endmodule
