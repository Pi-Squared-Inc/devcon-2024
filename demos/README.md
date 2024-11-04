# Demo

## Set up

[Insert prerequisite set up]

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
docker run -t uniswap02-on-geth
```

### EVM Semantics in K (K[EVM])

To build and execute the docker image for measuring UniSwap 1k swaps on K[EVM], run the following commands:
```bash
docker build --build-arg HOME=$HOME . --file=Docker/kevm.Dockerfile -t uniswap02-on-kevm
docker run -t uniswap02-on-kevm
```
### Solidity-Lite Semantics in K (K[Solidity] and K[Solidity[Uniswap]])

To build and execute the docker image for measuring UniSwap 1k swaps on Solidity-Lite Semantics with and without summarization/optimization, 
,i.e., K[Solidity[Uniswap]] (optimized for Uniswap) and K[Solidity], run the following commands:
```bash
docker build . --file=Docker/solidity.Dockerfile -t uniswap-on-solidity
docker run -t uniswap-on-solidity
```

### Summary of measurements collected

| Implementation | Time to run 1K swaps | Overhead | Speed |
| :- | :-: | :-: | :-: |
| **GETH** | 0.248s | 1x | 100% |
| **K[EVM]** | 8.444s | 34x | 2.9% |
| **K[Solidity]** | 0.259s | 1.04x | 95.8% |
| **K[Solidity[Uniswap]]** | **0.152s** | **0.61x** | **163%** |

> **Note:**
> - The Overhead and Speed calculated are based on using Geth as baseline.
> - The lower the Overhead value is, the faster it is as compared to Geth.
> - The higher the Speed value is, the faster it is as compared to Geth.
> - Speed = 1 / Overhead

## Proof hint generation of a given program

[Insert instructions]

## Math proof generation (MPG) of MetaMath (MM) proof/s from a given proof hint

[Insert instructions]

## End-to-end MPG from a given program to MM proof/s

[Insert instructions]

## Summary of benchmark measurements

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
