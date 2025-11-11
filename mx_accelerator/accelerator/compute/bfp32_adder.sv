/*
======================= START OF LICENSE NOTICE =======================
    Copyright (C) 2025 Akshat Ramachandran (GT), Souvik Kundu (Intel), Tushar Krishna (GT). All Rights Reserved

    NO WARRANTY. THE PRODUCT IS PROVIDED BY DEVELOPER "AS IS" AND ANY
    EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
    PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL DEVELOPER BE LIABLE FOR
    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
    GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
    IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
    OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THE PRODUCT, EVEN
    IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
======================== END OF LICENSE NOTICE ========================
    Primary Author: Akshat Ramachandran (GT)

*/
module bfp32_adder
(
    input logic [31:0] A, 
    input logic [15:0] B, 
    output logic [31:0] O
);

wire logic a_sign;
wire logic b_sign;

wire logic [7:0] a_exponent;
wire logic [23:0] a_mantissa; // plus one bit

wire logic [7:0] b_exponent; 
wire logic [23:0] b_mantissa; // plus one bit 

logic o_sign;
logic [7:0] o_exponent;
logic [24:0] o_mantissa;  // plus two bits

wire logic [31:0] adder_out;


assign a_sign = A[31];
assign a_exponent[7:0] = A[30:23];
assign a_mantissa[23:0] = {1'b1, A[22:0]};

assign b_sign = B[15];
assign b_exponent[7:0] = B[14:7];
assign b_mantissa[23:0] = {1'b1, B[6:0],16'b0};

general_adder gAdder (
    .a(A),
    .b(B),
    .out(adder_out)
);

//covers corner cases and uses general adder logic
always_comb
begin
    //a is NaN or b is zero return a
    if ((a_exponent == 255 && a_mantissa[22:0] != 0) || (b_exponent == 0) && (b_mantissa[22:0] == 0)) begin
        o_sign = a_sign;
        o_exponent = a_exponent;
        o_mantissa = a_mantissa;
        O = {o_sign, o_exponent, o_mantissa[22:0]};
        //b is NaN or a is zero return b
    end else if ((b_exponent == 255 && b_mantissa[22:0] != 0) || (a_exponent == 0) && (a_mantissa[22:0] == 0)) begin
        o_sign = b_sign;
        o_exponent = b_exponent;
        o_mantissa = b_mantissa;
        O = {o_sign, o_exponent, o_mantissa[22:0]};
        //a and b is inf return inf
    end else if ((a_exponent == 255) || (b_exponent == 255)) begin
        o_sign = a_sign ^ b_sign;
        o_exponent = 255;
        o_mantissa = 0;
        O = {o_sign, o_exponent, o_mantissa[22:0]};
    end else begin // Passed all corner cases
        //adder_a_in = A;
        //adder_b_in = B;
        o_sign = adder_out[31];
        o_exponent = adder_out[30:23];
        o_mantissa = adder_out[22:0];
        O = {o_sign, o_exponent, o_mantissa[22:0]};
    end
end  

endmodule