# Demo

> **NOTE:** The following are the instructions to set up for Pi-Squared-Inc developers only. Please set up executables so that the public users can run them without able to look at the codes. 


## Demo purpose

The goal of this demo is to demonstrate that executing Solidity programs in the [K framework](https://kframework.org/) using the Solidity formal semantics achieves comparable efficiency with executing programs in Geth. Moreover, if one applies the so-called summarization optimization to the Solidity formal semantics and contract, running programs in K can become considerably faster than running them using Geth.
The measurements to support our claim can be found in the [Summary of measurements collected](##Summary-of-measurements-collected) section.

## On the semantics-based program execution
Semantics-based program execution brings not only efficiency promises, but also a correct-by-construction feature. The formal semantics of a programming language can be thought as a mathematical theory. When you feed such a mathematical theory and a specific program to K, the K framework transforms the execution of the program into a rigurous mathematical proof. Also, unlike Geth, which requires program compilation and is therefore susceptible to potential vulnerabilities from compiler bugs, semantics-based program execution removes the need for compilation. This minimizes exposure to such security risks and enhances system stability.
If you want to find more on how formal semantics will change the Web3 landscape, read our [blogpost](https://blog.pi2.network/how-formal-semantics-will-bring-more-developers-to-web3/).

## Set up

1. Install Docker (if necessary) - Follow the instructions provided [here](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

2. Install `make`
    ```
    sudo apt install make
    ```

3. Install `pip`
    ```
    sudo apt install python3-pip    
    ```

4. Install `poetry`
   ```
   sudo apt install python3-poetry
   curl -sSL https://install.python-poetry.org | python3 - # to install the latest version of Poetry
   ```
   **NOTE:** After which, add `PATH="$HOME/.local/bin:$PATH"` above `PATH="$HOME/bin:$PATH"` in `~/.profile` before running `source ~/.profile`.
   
5. Install K version 7.1.158

    ```
    bash <(curl https://kframework.org/install)
    kup install k --version v7.1.158
    ```

## Uniswap 1k swaps with Geth and K
> Dockerfiles and instructions in this section are written by @Robertorosmaninho

This section includes instructions to run `testSwapLoop` (line 696 to 704 of [swaps.sol](../src/swaps.sol)) on Geth and
the different K semantics, i.e., K[EVM], K[Solidity] and K[Solidity[Uniswap]]. The test consists of setting up necessary 
mock token contracts and executing `testSwapSingleHopExactAmountIn` (line 706 to 723 of [swaps.sol](../src/swaps.sol)) 
1000 times via a `while` loop. The `testSwapSingleHopExactAmountIn` consists of setting up the necessary environment,
such as depositing, approving and transferring sufficient tokens in order to make the required `swapSingleHopExactAmountIn`
function call as seen in line 720 of [swaps.sol](../src/swaps.sol).

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

## Set up to run proof generation and its measurements

1. Clone the [pi2](https://github.com/Pi-Squared-Inc/pi2) repository.
    ```
    git clone https://github.com/Pi-Squared-Inc/pi2.git
    cd pi2
    ```

2. Build the environment.
    ```
    ./Test make build
    ```
    **NOTE:** If the command returns error, just follow the recommended actions suggested by the error output. For example, on the first run of the above command, it may ask you to instal Metamath via `sudo apt install metamath`.


## Proof hint generation from a given program

[Insert instructions]

## Math proof generation (MPG) of ProofExpr from a given proof hint

[Insert instructions]

## End-to-end MPG from a given program to ProofExpr

[Insert instructions]

## Benchmark measurements generation

1. Set up
    ```
    source ~/.profile # to use the latest Peotry
    git fetch origin dev/jin/2024-10-29/devcon-report
    git checkout dev/jin/2024-10-29/devcon-report
    ```

2. Command to run
    ```
    ./Test grun python -Om generation.src.measurements.devcon_measurements --fresh-build --gc-disable
    ```

The report generated can be found in `generation/src/measurements/docs/devcon_report.md`.

# Summary for Devcon benchmark measurements
> Measurements were taken on 2024-11-07 using Intel Xeon Scalable (Sapphire Rapids) 96 vCPU with 384GB RAM

### K[Solidity] benchmark measurements
> Solidity-lite semantics in K

| S/No. | Program | Krun | Krun + LLVM | Krun + LLVM + Proof hints | o/h_Krun_w_hints | PP | PG_base | PG | o/h_PG |
| :-: | :- | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| 1 | uniswap_addLiquidity.txn | 0.125s | 0.267s | 3.066s | 24.498x | 58.443s | 2069.015s | 1932.652s | 0.9x | 
| 2 | uniswap_swapSingleHopExactAmountIn.txn | 0.128s | 0.261s | 2.720s | 21.319x | 48.703s | 1870.845s | 1695.647s | 0.9x | 
| 3 | uniswap_swapSingleHopExactAmountOut.txn | 0.127s | 0.261s | 2.804s | 22.105x | 51.424s | 1940.719s | 2225.302s | 1.1x | 


### K[Solidity[Uniswap]] benchmark measurements
> Solidity-lite semantics in K with summarization/optimization

| S/No. | Program | Krun | Krun + LLVM | Krun + LLVM + Proof hints | o/h_Krun_w_hints | PP | PG_base | PG | o/h_PG |
| :-: | :- | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| 1 | uniswap_addLiquidity.txn | 0.132s | 0.266s | 1.367s | 10.331x | 23.043s | 836.493s | 981.924s | 1.2x | 
| 2 | uniswap_swapSingleHopExactAmountIn.txn | 0.127s | 0.263s | 0.931s | 7.320x | 16.616s | 528.551s | 704.850s | 1.3x | 
| 3 | uniswap_swapSingleHopExactAmountOut.txn | 0.129s | 0.263s | 1.122s | 8.680x | 20.734s | 614.201s | 746.447s | 1.2x | 


### Definitions of measurements

- **Krun:** Time taken to run a program using K
- **Krun + LLVM:** Time taken to run a program with LLVM execution
- **Krun + LLVM + Proof hints:** Time taken to run a program with LLVM execution and generate its proof hints using K
- **o/h_Krun_w_hints:** Overhead caused by generating proof hints, given by (Krun + LLVM + Proof hints)/Krun- **PP:** Time taken to Pre-Process, PP, the proof hint file
- **PG_base:** Time taken to take in the pre-processed proof hint file and process the type of each of the hints, before discarding them
- **PG:** Time taken on Proof Generation, PG
- **o/h_PG:** Overhead caused by PG, given by (PG + PP)/(PG_base + PP)
