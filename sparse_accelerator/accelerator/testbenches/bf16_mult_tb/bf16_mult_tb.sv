//////////////////////////////////////////////////////////
// Copyright Ethan Weinstock, Garrett Botkin, Jingsong Guo
// Random testing of the bf16 multiplier against
// vcs shortreal (fp32) datatypes
//////////////////////////////////////////////////////////
`timescale 1ns/1ps

`define vegeta_clog2(NUM) ((NUM) > 1 ? $clog2((NUM)) : 1)
module bf16_mult_tb();

    localparam DEBUG_MSG  = 1;
    localparam REPEAT     = 100_000_000;
    // localparam REPEAT     = 158;
    localparam VERBOSE    = 0;

    localparam MANUAL_TESTCASES = 1;
    localparam RANDOM_TESTCASES = 1;

    logic [15:0] A; // Input A
    logic [15:0] B; // Input B
    logic [31:0] O; // Output

    shortreal float_A, float_B, float_O, float_expected_O;
    logic [31:0] Expected_O, truncated_expected_O;
    logic [31:0] bits;

    int fails_manual, fail_random, pass_manual, pass_random;

    bfp16_mult bfp16_mult (
        .A(A),
        .B(B),
        .O(O)
    );

    function logic [15:0] random_bf16();
        logic [31:0] random_32;
        begin
            random_32 = $urandom();
            return random_32[15:0];
        end
    endfunction : random_bf16

    function shortreal int_to_bf16(logic [15:0] random_bf16);
        begin
            return shortreal'($bitstoshortreal({random_bf16, 16'b0}));
        end
    endfunction

    function shortreal int_to_fp32(logic [31:0] random_fp32);
        begin
            return shortreal'($bitstoshortreal(random_fp32));
        end
    endfunction

    initial begin
        // $vcdpluson;   
        // $vcdplusmemon;
        // Manual Test Cases

        if (MANUAL_TESTCASES) begin
            fails_manual = 0;
            pass_manual = 0;
            $displayh("\n\033[1m\033[34mManual Tests...\033[0m\n");

            // BF16 -> Sign_Exponent_Mantissa -> 0_00000000_0000000

            // Edge Case 1: A is NAN

            A = 16'b0_11111111_0000001;
            B = 16'b0_00000000_0000000;
            Expected_O = 32'b0_11111111_1111111_1111111111111111;
            run_test("A is NAN");

            // Edge Case 2: B is NAN

            A = 16'b0_00000000_0000000;
            B = 16'b0_11111111_0000001;
            Expected_O = 32'b0_11111111_1111111_1111111111111111;
            run_test("B is NAN");

            // Edge Case 3: A&B is NAN

            A = 16'b0_11111111_0000001;
            B = 16'b0_11111111_0000010;
            Expected_O = 32'b0_11111111_1111111_1111111111111111;
            run_test("A&B is NAN");

            // Edge Case 4: A is Inf

            A = 16'b0_11111111_0000000;
            B = 16'b0_00000001_0000000;
            Expected_O = 32'b0_11111111_0000000_0000000000000000;
            run_test("A is INF");

            // Edge Case 5: B is Inf

            A = 16'b0_00000001_0000000;
            B = 16'b0_11111111_0000000;
            Expected_O = 32'b0_11111111_0000000_0000000000000000;
            run_test("B is INF");

            // Edge Case 6: A&B is Inf

            A = 16'b0_11111111_0000000;
            B = 16'b0_11111111_0000000;
            Expected_O = 32'b0_11111111_0000000_0000000000000000;
            run_test("A&B is INF");

            // Edge Case 7: A is 0

            A = 16'b0_00000000_0000000;
            B = 16'b0_00000001_0000000;
            Expected_O = 32'b0_00000000_0000000_0000000000000000;
            run_test("A is 0");

            // Edge Case 8: B is 0

            A = 16'b0_00000001_0000000;
            B = 16'b0_00000000_0000000;
            Expected_O = 32'b0_00000000_0000000_0000000000000000;
            run_test("B is 0");

            // Edge Case 9: A&B is 0

            A = 16'b0_00000000_0000000;
            B = 16'b0_00000000_0000000;
            Expected_O = 32'b0_00000000_0000000_0000000000000000;
            run_test("A&B is 0");

            // Edge Case 10: A&B is 0

            A = 16'b0_00000000_0000000;
            B = 16'b0_11111111_0000000;
            Expected_O = 32'b0_11111111_1111111_1111111111111111;
            run_test("A is 0, B is inf");

            // Edge Case 11: A&B is 0

            A = 16'b0_11111111_0000000;
            B = 16'b0_00000000_0000000;
            Expected_O = 32'b0_11111111_1111111_1111111111111111;
            run_test("A is inf, B is 0");

            // Manual Case 1: 

            A = 16'b0_01111111_0000000;
            B = 16'b0_01111111_0000000;
            Expected_O = 32'b0_01111111_0000000_0000000000000000;
            run_test("A&B are 1");

            A = 16'b0_10000000_0000000;
            B = 16'b0_10000000_0000000;
            Expected_O = 32'b0_10000001_0000000_0000000000000000;
            run_test("A&B are 2");

            A = 16'b0_01111111_0000000;
            B = 16'b0_10000000_0000000;
            Expected_O = 32'b0_10000000_0000000_0000000000000000;
            run_test("A&B are 1,2");

            A = 16'b0_01111110_0000000;
            B = 16'b0_10000000_0000000;
            Expected_O = 32'b0_01111111_0000000_0000000000000000;
            run_test("A&B are 0.5,2");

            A = 16'b0_01111101_0000000;
            B = 16'b0_10000001_0000000;
            Expected_O = 32'b0_01111111_0000000_0000000000000000;
            run_test("A&B are 0.25,4");

            A = 16'b0_01111111_0000000;
            B = 16'b0_00000000_1111111;
            Expected_O = 32'b0_00000000_1111111_0000000000000000;
            run_test("A is 1, B is max subnormal");

            A = 16'b0_01111111_0000000;
            B = 16'b0_00000000_0000001;
            Expected_O = 32'b0_00000000_0000001_0000000000000000;
            run_test("A is 1, B is min subnormal");

            A = 16'b0_00000000_1111111;
            B = 16'b0_01111111_0000000;
            Expected_O = 32'b0_00000000_1111111_0000000000000000;
            run_test("A is max subnormal, B is 1");

            A = 16'b0_00000000_0000001;
            B = 16'b0_01111111_0000000;
            Expected_O = 32'b0_00000000_0000001_0000000000000000;
            run_test("A is min subnormal, B is 1");

            A = 16'b0_01111111_0000000;
            B = 16'b0_00000000_0001000;
            Expected_O = 32'b0_00000000_0001000_0000000000000000;
            run_test("A is 1, B is random subnormal");

            A = 16'b0_00000000_0000100;
            B = 16'b0_00000000_0001000;
            Expected_O = 32'b0_00000000_0000000_0000000000000000;
            run_test("A is random subnormal, B is random subnormal");

            A = 16'b0_01111100_0000000;
            B = 16'b0_00000001_0000000;
            Expected_O = 32'b0_00000000_0010000_0000000000000000;
            run_test("A is normal, B is normal, O is subnormal");

            A = 16'b0_00000001_0000000;
            B = 16'b0_01101000_0000000;
            Expected_O = 32'b0_00000000_0000000_0000000000000001;
            run_test("Output is min subnormal");
        end

            

        // Random Test Cases

        if (RANDOM_TESTCASES) begin

            fail_random = 0;
            pass_random = 0;
            $displayh("\n\033[1m\033[34mRandom Tests...\033[0m\n");

            for (int i = 0; i < REPEAT; i ++) begin
                run_random_test(i);
            end
        end


        if (fail_random == 0) begin
            $write("\033[1;32mPASSED %d Random tests! \033[0m\n", pass_random);
        end else
            $write("\033[1;31mFAILED %d random tests.\033[0m\n", fail_random);
        if (fails_manual == 0) begin
            $write("\033[1;32mPASSED %d manual tests! \033[0m\n", pass_manual);
        end else
            $write("\033[1;31mFAILED %d manual tests.\033[0m\n", fails_manual);

        #1000 $finish;
    end

    task run_test(string msg);
        #1 if (Expected_O == O) begin
            if (VERBOSE == 1)
                $write("\t\033[1;32m%s PASSED! \033[0m\n", msg);
            pass_manual++;
        end else begin
            fails_manual++;            
            $write("\t\033[1;31m%s FAILED.\033[0m\n", msg);
            if (DEBUG_MSG) begin
                $displayh("A: ", A);
                $displayh("B: ", B);
                $displayh("O: ", O);
                $displayh("Expected O: ", Expected_O);
            end
        end
    endtask

    task run_random_test(int i);
        A = random_bf16();
        B = random_bf16();

        float_A = int_to_bf16(A);
        float_B = int_to_bf16(B);
        float_expected_O = float_A * float_B;
        bits = $shortrealtobits(shortreal'(float_expected_O));
        truncated_expected_O = bits;
        // can't handle NaN
        if ((A[14:7] == 255 && A[6:0] != 0) || 
            (B[14:7] == 255 && B[6:0] != 0)) 
        begin
            truncated_expected_O = {1'b0, 8'd255, 23'd8388607};
        end

        #1 if (truncated_expected_O == O) begin
            pass_random++;
        end else begin
            fail_random++;
            $write("\t\033[1;31mFAILED %d.\033[0m\n", i+1);
            if (DEBUG_MSG) begin
                $displayh("A: ", A);
                $display("bf16 A: ", shortreal'(float_A));
                $displayh("B: ", B);
                $display("bf16 B: ", shortreal'(float_B));
                $displayh("O: ", O);
                float_O = int_to_fp32(O);
                $display("bf16 O: ",shortreal'(float_O));
                $display("bf16 Expected O: ",float_expected_O);
                $displayh("Expected bits: ", bits);
                $displayh("\n");
            end
        end
    endtask
endmodule