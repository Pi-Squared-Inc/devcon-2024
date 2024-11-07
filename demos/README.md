# Demo

> **NOTE:** The following are the instructions to set up for Pi-Squared-Inc developers only. Please set up executables so that the public users can run them without able to look at the codes. 

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

## Summary of benchmark measurements [TO BE UPDATED]

### K[IMP] benchmark measurements
> IMP semantics in K

| S/No. | Program | Krun | Krun + Proof hints | o/h Proof hints | PG_base | PG | o/h_PG |
| :-: | :- | :-: | :-: | :-: | :-: | :-: | :-: |
| 1 | erc20transfer_success | 1.225s | 1.299s | 1.0x | 0.101s | 1.560s | 6.0x |  


### K[IMP[Transfer]] benchmark measurements
> IMP semantics in K with summarization/optimization

| S/No. | Program | Krun | Krun + Proof hints | o/h Proof hints | PG_base | PG | o/h_PG |
| :-: | :- | :-: | :-: | :-: | :-: | :-: | :-: |
| 1 | erc20transfer_success | 1.264s | 1.234s | 1.0x | 0.027s | 0.987s | 10.2x | 


### K[Solidity] benchmark measurements
> Solidity-lite semantics in K

| S/No. | Program | Krun | Krun + Proof hints | o/h Proof hints | PG_base | PG | o/h_PG |
| :-: | :- | :-: | :-: | :-: | :-: | :-: | :-: |
| 1 | uniswap_addLiquidity.txn | 0.219s | 3.482s | 15.8x | 2898.241s | _TBC_ | _TBC_ |  
| 2 | uniswap_swapSingleHopExactAmountIn.txn | 0.217s | 3.058s | 14.0x | 2590.308s | 3313.402s | 1.3x | 
| 3 | uniswap_swapSingleHopExactAmountOut.txn | 0.217s | 3.131s | 14.4x | 2769.396s | _TBC_ | _TBC_ | 


### K[Solidity[Uniswap]] benchmark measurements
> Solidity-lite semantics in K with summarization/optimization

| S/No. | Program | Krun | Krun + Proof hints | o/h Proof hints | PG_base | PG | o/h_PG |
| :-: | :- | :-: | :-: | :-: | :-: | :-: | :-: |
| 1 | uniswap_addLiquidity.txn | 0.222s | 1.440s | 6.4x | 1554.702s | 1452.360s | 0.9x | 
| 2 | uniswap_swapSingleHopExactAmountIn.txn | 0.217s | 0.973s | 4.4x | 729.427s | 1520.758s | 2.1x | 
| 3 | uniswap_swapSingleHopExactAmountOut.txn | 0.217s | 1.209s | 5.5x | 1068.381s | 1678.967s | 1.6x |  


#### Definitions of measurements

- **Krun:** Time taken to run a program using K
- **Krun + Proof hints:** Time taken to run a program and generate its proof hints using K
- **o/h Proof hints:** Overhead caused by generating of proof hints, given by (Krun + Proof hints)/Krun
- **PG_base:** Time taken to take in the pre-processed proof hint file and process the type of each of the hints, before discarding them
- **PG:** Time taken on PG with 21 cores working on it (as the rest of the cores are assigned for Proof 
- **o/h_PG:** Overhead caused by PG, given by (PG + PP)/(PG_base + PP)
