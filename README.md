# SparseAccelerator-RTL
Accelerator RTL inspired by VEGETA [HPCA'23] and MicroScopiQ [ISCA'25]

## File Structure

- sparse_accelerator
  - arithmetic: code for bf16 multiplier and fp32 adder
  - compute: VEGETA top core
  - data_control: team designed weight, activation, accumulation, and output controller
  - memory: L1 buffers for controllers
  - testbenches: vcs compatible testbenches for the bf16 multiplier, fp32 adder, and VEGETA top

- mx_accelerator
  - arithmetic: code for bf16 multiplier and fp32 adder
  - compute: VEGETA top core
  - data_control: team designed weight, activation, accumulation, and output controller
  - memory: L1 buffers for controllers
  - testbenches: vcs compatible testbenches for the bf16 multiplier, fp32 adder, and VEGETA top

## Instructions for Running Simulation of Sparse Accelerator

Testbenches are found at:

- sparse_accelerator/testbench/
  - bf16_mult_tb
  - fp32_adder_tb
  - vegeta_top_tb
  
Run testbenches by typing:
``make``

The vegeta_top_tb has the following parameters:

- DEBUG: Enabled Debug messages
- VERBOSE: Increase tb verbosity, such as including passes and reasons for failures
- NUM_TRIALS: number of trails to run. Should be set to 1 if random_test is not 0
- ENABLE_DENSE_TESTS: enables dense testcases for the dut
- ENABLE_2X4SPARSE_TESTS: enables 2:4 sparsity testcases for the dut
- ENABLE_1X4SPARSE_TESTS: enables 1:4 sparsity testcases for the dut
- RANDOM_TESTS: enables random data values instead of set inputs

### Comprehensive testing
Set parameters as follows:

- DEBUG: 1
- VERBOSE: 1
- NUM_TRIALS: 1
- ENABLE_DENSE_TESTS: 1
- ENABLE_2X4SPARSE_TESTS: 1
- ENABLE_1X4SPARSE_TESTS: 1
- RANDOM_TESTS: 0

Run ``iterate.csh``
This script will test all configurations of the following parameters

- M: 4 8 16 32 64
- N: 4 8 16 32 64
- K: 4 8 16 32 64
- ALPHA: 1 2 4 8 16 32 64 (ALPHA < M)

where the weight matrix is dimensions (M x K), the activation matrix (K x N), and the output matrix is of shape (M x N)

## Instructions for Running Simulation of Sparse Accelerator

The verification testbench requires both modelsim and cocotb as well as being run under csh (run tcsh to enter csh).

#### Cocotb Installation
Cocotb can be installed either to a python virtual environment, or as a user package.

### Running
It is recommended to create a directory inside [sim](sim) (ex: /sim/compute/).

Within this directory symlink [this Makefile](Makefiles/compute/Makefile_sim_presyn) as Makefile.

The testbench can then be run with default parameters with:

    make

It is recommended to run make clean before running make again, especially if any changes are made.

## Acknowledgments

We would like to thank the students of GT ECE8803: Hardware for Machine Learning whose final projects helped with the RTL development.

## Citation

If you found this work helpful, please consider citing:

```bibtex
@inproceedings{jeong2023vegeta,
    title={Vegeta: Vertically-integrated extensions for sparse/dense gemm tile acceleration on cpus},
    author={Jeong, Geonhwa and Damani, Sana and Bambhaniya, Abhimanyu Rajeshkumar and Qin, Eric and Hughes, Christopher J and Subramoney, Sreenivas and Kim, Hyesoon and Krishna, Tushar},
    booktitle={2023 IEEE International Symposium on High-Performance Computer Architecture (HPCA)},
    pages={259--272},
    year={2023},
    organization={IEEE}
}

@inproceedings{ramachandran2025microscopiq,
    title={Microscopiq: Accelerating foundational models through outlier-aware microscaling quantization},
    author={Ramachandran, Akshat and Kundu, Souvik and Krishna, Tushar},
    booktitle={Proceedings of the 52nd Annual International Symposium on Computer Architecture},
    pages={1193--1209},
    year={2025}
}
```
