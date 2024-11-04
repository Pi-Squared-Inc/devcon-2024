# Demo

## Set up

[Insert prerequisite set up]

## Uniswap 1k swaps with Geth and K

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
### Solidity-Lite Semantics (K[Solidity] and K[Solidity[Uniswap]])

To build and execute the docker image for measuring UniSwap 1k swaps on Solidity-Lite Semantics with and without summarization/optimization, 
,i.e., K[Solidity] and K[Solidity[Uniswap]], run the following commands:
```bash
docker build . --file=Docker/solidity.Dockerfile -t uniswap-on-solidity
docker run -t uniswap-on-solidity
```

### Summary of measurements collected

| Implementation | Time to run 1K swaps | Overhead | Speed |
| :- | :-: | :-: | :-: |
| **GETH** | 0.248s | 1x | 100% |
| **KEVM** | 8.444s | 34x | 2.9% |
| **Solidity-lite without summary** | 0.259s | 1.04x | 95.8% |
| **Solidity-lite with summary** | **0.152s** | **0.61x** | **163%** |

> **Note:**
> - The Overhead and Speed calculated are based on using Geth as baseline.
> - The lower the Overhead value is, the faster it is as compared to Geth.
> - The higher the Speed value is, the faster it is as compared to Geth.
> - Speed = 1 / Overhead

## Proof hint generation of IMP version of ERC20 transfer

[Insert instructions]

## Math proof generation of IMP version of ERC20 transfer

[Insert instructions]
