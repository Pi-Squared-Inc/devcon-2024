# $\pi^2$ Devcon 7 Demo

- [$\\pi^2$ Devcon 7 Demo](#pi2-devcon-7-demo)
  - [Demo purpose](#demo-purpose)
  - [On the semantics-based program execution](#on-the-semantics-based-program-execution)
  - [Set up](#set-up)
  - [Uniswap 1k swaps with Geth and K](#uniswap-1k-swaps-with-geth-and-k)
    - [GO Ethereum (Geth)](#go-ethereum-geth)
    - [Solidity-Lite Semantics in K (K\[Solidity\] and K\[Solidity\[Uniswap\]\])](#solidity-lite-semantics-in-k-ksolidity-and-ksolidityuniswap)
    - [Summary of measurements collected](#summary-of-measurements-collected)
  - [Generating Metamath proofs for arbitrary programs](#generating-metamath-proofs-for-arbitrary-programs)
  - [Benchmark measurements generation](#benchmark-measurements-generation)
- [Summary for Devcon benchmark measurements](#summary-for-devcon-benchmark-measurements)
    - [K\[Solidity\] benchmark measurements](#ksolidity-benchmark-measurements)
    - [K\[Solidity\[Uniswap\]\] benchmark measurements](#ksolidityuniswap-benchmark-measurements)
    - [Definitions of measurements](#definitions-of-measurements)

## Demo purpose

The goal of this demo is to demonstrate that executing Solidity programs in the [K framework](https://kframework.org/) using the Solidity formal semantics achieves comparable efficiency with executing programs in Geth. Moreover, if one applies the so-called summarization optimization to the Solidity formal semantics and contract, running programs in K can become considerably faster than running them using Geth.
The measurements to support our claim can be found in the [Summary of measurements collected](##Summary-of-measurements-collected) section.

## On the semantics-based program execution
Semantics-based program execution brings not only efficiency promises, but also a correct-by-construction feature. The formal semantics of a programming language can be thought as a mathematical theory. When you feed such a mathematical theory and a specific program to K, the K framework transforms the execution of the program into a rigurous mathematical proof. Also, unlike Geth, which requires program compilation and is therefore susceptible to potential vulnerabilities from compiler bugs, semantics-based program execution removes the need for compilation. This minimizes exposure to such security risks and enhances system stability.
If you want to find more on how formal semantics will change the Web3 landscape, read our [blogpost](https://blog.pi2.network/how-formal-semantics-will-bring-more-developers-to-web3/).

## Set up

In order to run our demos, you should make sure you have a working installation of Docker. If not, follow the instructions provided [here](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

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

## Generating Metamath proofs for arbitrary programs
Before you start, pull the Docker image that contains the $\pi^2$ proof generation executables:
```bash
docker pull ghcr.io/pi-squared-inc/pi2-mpg-image:latest
```

Math proof generation begins with the definition of a programming language semantics in K, and a program written in that language. As K executes the program using the semantics, $\pi^2$ translates its execution trace to a formal mathematical proof written in Metamath.

If you want a high-level view of the process, you can simply execute:
```bash
docker run --rm -it ghcr.io/pi-squared-inc/pi2-mpg-image \
    pi2 imp generation/k-benchmarks/imp/erc20transfer_success.imp -o IMP -v
```

By running this, we are creating the formal proof of an ERC20-like program in the simple imperative language IMP.

You will see an output like this:
```
> Running kompile...
> Generating hints...
> Generating proof...
```

These are the three stages of $\pi^2$ proof generation. First, we compile the formal semantics of IMP to an executable interpreter. Then, we invoke the interpreter on our program and we output its execution trace. For us, this execution trace gives *hints* about how the final mathematical proof should be constructed. Finally, we use these hints to generate the proof.

The more curious-minded are welcome to attach to a shell in the Docker container and explore around:
```bash
docker run --rm -it --entrypoint bash ghcr.io/pi-squared-inc/pi2-mpg-image
```

Once here, you can execute the same command as above, and perhaps make it more verbose:
```bash
pi2 imp generation/k-benchmarks/imp/erc20transfer_success.imp -o IMP -vvv
```

At the end of the run, all results of execution will be located under a new directory named `IMP`, with the following structure:
```
IMP
|-kompiled
|-proof-hints
|-mm-proofs
|---erc20transfer_success
```
The `kompiled` folder stores the compiled semantics. The `proof-hints` folder contains the execution trace in binary format. Finally, under `mm-proofs` you will find 45 Metamath files generated by our process.

Each Metamath file proves the correctness of a single *execution step* -- that is, a single change in interpreter state. This technique of decomposing the proof into small pieces is essential for making proof checking fast and parallelizable.

Feel free to peek at the formal semantics of IMP located in `generation/k-benchmarks/imp/imp.k`, and at the program it has proved, `generation/k-benchmarks/imp/erc20transfer_success.imp`.

## Benchmark measurements generation
We support not just IMP, but real-world languages like Solidity. Under `generation/solidity-benchmarks`, you will find a Uniswap contract, and various transactions we execute on it.

The following command (ran on the host) will run all our performance benchmarks on Solidity, and output an execution report:
```bash
docker run --rm -it ghcr.io/pi-squared-inc/pi2-mpg-image bash -c \
    "devcon-measurements --output-directory . ; \
    cat devcon_measurements.json"
```

Our report can be found in `generation/src/measurements/docs/devcon_report.md`, and is summarized below.

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

