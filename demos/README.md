# Demo

## Demo purpose

The goal of this demo is to demonstrate that executing Solidity programs in the [K framework](https://kframework.org/) using the Solidity formal semantics achieves comparable efficiency with executing programs in Geth. Moreover, if one applies the so-called summarization optimization to the Solidity formal semantics and contract, running programs in K can become considerably faster than running them using Geth.
The measurements to support our claim can be found in the [Summary of measurements collected](##Summary-of-measurements-collected) section.

## On the semantics-based program execution
Semantics-based program execution brings not only efficiency promises, but also a correct-by-construction feature. The formal semantics of a programming language can be thought as a mathematical theory. When you feed such a mathematical theory and a specific program to K, the K framework transforms the execution of the program into a rigurous mathematical proof. Also, unlike Geth, which requires program compilation and is therefore susceptible to potential vulnerabilities from compiler bugs, semantics-based program execution removes the need for compilation. This minimizes exposure to such security risks and enhances system stability.
If you want to find more on how formal semantics will change the Web3 landscape, read our [blogpost](https://blog.pi2.network/how-formal-semantics-will-bring-more-developers-to-web3/).


## Uniswap 1k swaps with Geth and K

This section includes instructions to reproduce the measurements collected as seen in table seen at the end of this section. 
The benchmark program we measured on is the `testSwapLoop` (line 696 to 704 of [swaps.sol](../src/swaps.sol)). It is run on Geth 
and the different K semantics, i.e., K[EVM], K[Solidity] and K[Solidity[Uniswap]]. The test consists of setting up necessary 
mock token contracts and executing `testSwapSingleHopExactAmountIn` (line 706 to 723 of [swaps.sol](../src/swaps.sol)) 
1000 times via a `while` loop. The `testSwapSingleHopExactAmountIn` consists of setting up the necessary environment,
such as depositing, approving and transferring sufficient tokens in order to make the required `swapSingleHopExactAmountIn`
function call as seen in line 720 of [swaps.sol](../src/swaps.sol).

**NOTE:** You would require Docker to be [installed](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository) to run the following commands.

### GO Ethereum (Geth)

To build and execute the docker image for measuring UniSwap 1k swaps on Geth, run the following commands:
```bash
sudo docker build . --file=Docker/geth.Dockerfile -t uniswap02-on-geth
sudo docker run -t uniswap02-on-geth
```

### Solidity-Lite Semantics in K (K[Solidity] and K[Solidity[Uniswap]])

To build and execute the docker image for measuring UniSwap 1k swaps on Solidity-Lite Semantics with and without summarization/optimization, 
,i.e., K[Solidity[Uniswap]] (optimized for Uniswap) and K[Solidity], run the following commands:
```bash
sudo docker build . --file=Docker/solidity.Dockerfile -t uniswap-on-solidity
sudo docker run -t uniswap-on-solidity
```

### Summary of measurements collected
> Measurements were taken on 13th Gen Intel(R) Core(TM) i9-13900K 24-Core CPU (32 threads), with Intel® UHD Graphics 770 (Integrated with CPU) and 64GB RAM.

| Implementation | Time to run 1K swaps | Overhead | Speed |
| :- | :-: | :-: | :-: |
| **GETH** | 0.248s | 1x | 100% |
| **K[Solidity]** | 0.259s | 1.04x | 95.8% |
| **K[Solidity[Uniswap]]** | **0.152s** | **0.61x** | **163%** |

> **Note:**
> - The Overhead and Speed calculated are based on using Geth as baseline.
> - The lower the Overhead value is, the faster it is as compared to Geth.
> - The higher the Speed value is, the faster it is as compared to Geth.
> - Speed = 1 / Overhead

## Math Proof Generation (MPG) and its measurements

This section includes instructions to reproduce the tables as seen in the end of this section.
For each benchmark semantics, namely K[Solidity] and K[Solidity[Uniswap]], we measured on 3 different transaction programs:
- [uniswap_addLiquidity.txn](../src/uniswap_addLiquidity.txn)
- [uniswap_swapSingleHopExactAmountIn.txn](../src/uniswap_swapSingleHopExactAmountIn.txn)
- [uniswap_swapSingleHopExactAmountOut.txn](../src/uniswap_swapSingleHopExactAmountOut.txn)    
Each of the transaction programs consists of executing different test/function calls from the 
[UniswapV2SwapRenamed.sol](../src/UniswapV2SwapRenamed.sol) contract.

##########################################  
 👷 INSTRUCTIONS - WORKING IN PROGRESS 👷   
##########################################  

### Summary for measurements collected
> Measurements were taken on Intel Xeon Scalable (Sapphire Rapids) 96 vCPU with 384GB RAM.

#### K[Solidity] benchmark measurements
> Solidity-lite semantics in K

| S/No. | Program | Krun | Krun + LLVM | Krun + LLVM + Proof hints | o/h_Krun_w_hints | PP | PG_base | PG | o/h_PG |
| :-: | :- | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| 1 | uniswap_addLiquidity.txn | 0.125s | 0.267s | 3.066s | 20.711x | 58.443s | 2069.015s | 1932.652s | 0.9x | 
| 2 | uniswap_swapSingleHopExactAmountIn.txn | 0.128s | 0.261s | 2.720s | 19.488x | 48.703s | 1870.845s | 1695.647s | 0.9x | 
| 3 | uniswap_swapSingleHopExactAmountOut.txn | 0.127s | 0.261s | 2.804s | 19.977x | 51.424s | 1940.719s | 2225.302s | 1.1x | 


#### K[Solidity[Uniswap]] benchmark measurements
> Solidity-lite semantics in K with summarization/optimization on Uniswap

| S/No. | Program | Krun | Krun + LLVM | Krun + LLVM + Proof hints | o/h_Krun_w_hints | PP | PG_base | PG | o/h_PG |
| :-: | :- | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| 1 | uniswap_addLiquidity.txn | 0.132s | 0.266s | 1.367s | 9.216x | 23.043s | 836.493s | 981.924s | 1.2x | 
| 2 | uniswap_swapSingleHopExactAmountIn.txn | 0.127s | 0.263s | 0.931s | 5.911x | 16.616s | 528.551s | 704.850s | 1.3x | 
| 3 | uniswap_swapSingleHopExactAmountOut.txn | 0.129s | 0.263s | 1.122s | 7.410x | 20.734s | 614.201s | 746.447s | 1.2x | 


#### Definitions of measurements

- **Krun:** Time taken to parse a program using K
- **Krun + LLVM:** Time taken to parse and execute a program with LLVM backend using K
- **Krun + LLVM + Proof hints:** parse and execute a program with LLVM backend while generating its proof hints using K
- **o/h_Krun_w_hints:** Overhead caused by generating proof hints, given by ("Krun + LLVM + Proof hints" - "Krun")/("Krun + LLVM" - "Krun")- **PP:** Time taken to Pre-Process, PP, the proof hint file
- **PG_base:** Time taken to take in the pre-processed proof hint file and process the type of each of the hints, before discarding them
- **PG:** Time taken on Proof Generation, PG
- **o/h_PG:** Overhead caused by PG, given by (PG + PP)/(PG_base + PP)
