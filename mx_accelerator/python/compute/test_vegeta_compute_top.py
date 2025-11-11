# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0
# Simple tests for an adder module
import os
import random
import sys
from pathlib import Path
import numpy as np

import cocotb
from cocotb.runner import get_runner
from cocotb.triggers import Timer, ClockCycles
# if cocotb.simulator.is_running():
#     from vegeta_compute_top_model import vegeta_compute_top_model

def create_input_demand_matrix_ws(input_matrix):
    input_demand_matrix = []

    for i in range(len(input_matrix) + len(input_matrix[0]) - 1):
        cycle_input = []
        for j in range(len(input_matrix[0])):
            offset_index = i - j
            if offset_index >= 0 and offset_index < len(input_matrix):
                cycle_input.append(input_matrix[offset_index][j])
            else:
                cycle_input.append(0)
        input_demand_matrix.append(cycle_input)
    return input_demand_matrix

async def do_clock_cycle(dut, n=1):
    for _ in range(n):
        dut.clk.value = 0
        await Timer(10, units='ns')
        dut.clk.value = 1
        await Timer(10, units='ns')

async def load_weights(dut, weight_matrix, precision='bfp16'):
    load_cycles = int(cocotb.plusargs["X"])

    dut.mode.value = 0
    dut.weight_transferring_in.value=1
    dut.i_wb.value = 0
    for i in range(load_cycles):
        dut.weight_in.value = weight_matrix[-1 - i]
        await do_clock_cycle(dut)
    dut.weight_transferring_in.value = 0

async def stream_inputs (dut, input_matrix):
    
    dut.mode.value=2
    input_demand_matrix = create_input_demand_matrix_ws(input_matrix)
    for i in range(len(input_demand_matrix)):
        # print(f"Streaming {input_demand_matrix[i]}")
        dut.act_in.value = input_demand_matrix[i]
        await do_clock_cycle(dut)
    
#note: bfp16 exponent stuff not implemented yet, keep inputs within mantissa bits (2^7 for bfp16)
@cocotb.test(skip=True)
async def vegeta_compute_top_basic_3x3_test(dut):
    """Basic Test for when X and Y are both 3"""

    # set mode to dense
    dut.gemm_mode.value = 0

    weight_matrix = [[1, 2, 3],
                     [4, 5, 6],
                     [7, 8, 9]]
    
    input_matrix = [[1, 2, 3],
                    [4, 5, 6],
                    [7, 8, 9]]
    
    
    await load_weights(dut, weight_matrix, 'bfp16')

    print(create_input_demand_matrix_ws(input_matrix))

@cocotb.test(skip=True)
async def vegeta_compute_top_basic_2x1_test(dut):
    """Basic Test for when X=2 and Y=1"""


    # set mode to dense
    dut.gemm_mode.value = 0
    dut.acc_in.value = [0]

    weight_matrix = [[1],
                     [1]]
    
    input_matrix = [[1, 1]]

    dut.rst_n.value=0
    await do_clock_cycle(dut, 2)
    dut.rst_n.value=1
    await do_clock_cycle(dut)
    
    await load_weights(dut, weight_matrix)

    await stream_inputs(dut, input_matrix)
    #should only take 2 cycles for first output
    await ClockCycles(dut.clk, 2)
    assert dut.acc_out[0].value == 2

@cocotb.test(skip=True)
async def vegeta_compute_top_basic_1x1_test(dut):
    """Basic Test for when X and Y are 1 (good for testing PE)"""


    # set mode to dense
    dut.gemm_mode.value = 0
    dut.acc_in.value = [0]

    weight_matrix = [[1]]
    
    input_matrix = [[1]]

    dut.rst_n.value=0
    await do_clock_cycle(dut, 2)
    dut.rst_n.value=1
    await do_clock_cycle(dut)
    
    await load_weights(dut, weight_matrix)

    await stream_inputs(dut, input_matrix)
    #should only take 1 cycle for first output
    await ClockCycles(dut.clk, 1)
    assert dut.acc_out[0].value == 1



    # num_inputs = dut.NUM_DATA.value
    # data_width = dut.DATA_WIDTH.value
    # max_input_val = (2 ** (data_width - 1)) - 1

    # data_i = [1, 1]

    # max_error = float(cocotb.plusargs["max_error"])
    # for i in range(num_inputs - len(data_i)):
    #     data_i.append(0)

    # dut.data_i.value = data_i

    # await Timer(2, units="ns")
    # expecteds = l1norm_model(data_i, (max_input_val+1)/2)
    
    # actuals = dut.data_o.value
    # actuals = [cocotb.binary.BinaryValue(value=actual.binstr, bits=data_width, bigEndian=False, binaryRepresentation=2) for actual in actuals]
    # assert all([abs(actuals[i].signed_integer - expecteds[i]) <= max_error for i in range(2)]), f"L1Norm result is incorrect: {actuals} !~= {expecteds}"


# @cocotb.test()
# async def vegeta_compute_top_randomized_test(dut):
#     """Test for L1Norm N random numbers multiple times"""
#     np.random.seed(cocotb.RANDOM_SEED)
#     num_data = dut.NUM_DATA.value
#     data_width = dut.DATA_WIDTH.value

#     min_input_val = -(2 ** (data_width - 1))
#     max_input_val = (2 ** (data_width - 1)) - 1

#     max_error = float(cocotb.plusargs["max_error"])
#     iterations = int(cocotb.plusargs['rand_test_iterations'])
#     print(f"Testing {iterations} iterations of {num_data} inputs")
#     for i in range(iterations):

#         data_i = np.random.randint(low=min_input_val, high=max_input_val, size=num_data, dtype=int).tolist()
#         dut.data_i.value = [cocotb.binary.BinaryValue(value=x if x != 0 else '0', bits=data_width, bigEndian=False, binaryRepresentation=2) for x in data_i]
        
#         await Timer(2, units="ns")

#         expecteds = l1norm_model(data_i, (max_input_val+1)/2)
        
#         actuals = dut.data_o.value
#         actuals = [cocotb.binary.BinaryValue(value=actual.binstr, bits=data_width, bigEndian=False, binaryRepresentation=2) for actual in actuals]
#         actuals_integers = [actual.signed_integer for actual in actuals] 
#         assert all([abs(actuals_integers[i] - expecteds[i]) <= max_error for i in range(num_data)]), f"L1Norm result for {data_i} is incorrect: {actuals_integers} !~= {expecteds}"


# @cocotb.test(skip=True)
# async def vegeta_compute_top_manual_test(dut):
#     """Manual Testcase for debugging"""

#     num_inputs = dut.NUM_DATA.value
#     data_width = dut.DATA_WIDTH.value
#     max_input_val = (2 ** (data_width - 1)) - 1

#     data_i = [42, -74]

#     max_error = float(cocotb.plusargs["max_error"])
#     for i in range(num_inputs - len(data_i)):
#         data_i.append(0)

#     dut.data_i.value = data_i

#     await Timer(2, units="ns")
#     expecteds = l1norm_model(data_i, (max_input_val+1)/2)
    
#     actuals = dut.data_o.value
#     actuals = [cocotb.binary.BinaryValue(value=actual.binstr, bits=data_width, bigEndian=False, binaryRepresentation=2) for actual in actuals]
#     actuals_integers = [actual.signed_integer for actual in actuals]
#     assert all([abs(actuals_integers[i] - expecteds[i]) <= max_error for i in range(2)]), f"L1Norm result is incorrect: {actuals_integers} !~= {expecteds}"
            
# def test_adder_runner():
#     """Simulate the adder example using the Python runner.

#     This file can be run directly or via pytest discovery.
#     """
#     hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
#     sim = os.getenv("SIM", "icarus")

#     proj_path = Path(__file__).resolve().parent.parent.parent.parent.parent
#     # equivalent to setting the PYTHONPATH environment variable
#     sys.path.append(str(proj_path / "src" / "python" / "DE" / "adder_tree"))

#     verilog_sources = []
#     vhdl_sources = []

#     if hdl_toplevel_lang == "verilog":
#         verilog_sources = [proj_path / "src" / "adder.sv"]
#     else:
#         vhdl_sources = [proj_path / "hdl" / "adder.vhdl"]

#     build_test_args = []
#     if hdl_toplevel_lang == "vhdl" and sim == "xcelium":
#         build_test_args = ["-v93"]

#     # equivalent to setting the PYTHONPATH environment variable
#     sys.path.append(str(proj_path / "tests"))

#     runner = get_runner(sim)
#     runner.build(
#         verilog_sources=verilog_sources,
#         vhdl_sources=vhdl_sources,
#         hdl_toplevel="adder",
#         always=True,
#         build_args=build_test_args,
#     )
#     runner.test(
#         hdl_toplevel="adder", test_module="test_adder", test_args=build_test_args
#     )


# if __name__ == "__main__":
#     test_adder_runner()