ARG K_VERSION=7.1.149
FROM runtimeverificationinc/kframework-k:ubuntu-noble-${K_VERSION}

# Install the dependencies
RUN apt-get update && apt-get install -y wget cmake build-essential git bc multitime

# Set the working directory
WORKDIR /workspace

# Retrieve the Solidity repo
RUN git clone https://github.com/Pi-Squared-Inc/solidity-demo-semantics.git

# Setup Solidity as the working directory
WORKDIR /workspace/solidity-demo-semantics

# Be sure that everything is up-to-date
RUN git submodule update --init --recursive

# Setup Solidity as the working directory
WORKDIR /workspace/solidity-demo-semantics

# Build the Solidy Semantics
RUN make build

# Run the test of 1000 Swap without Summarization
RUN bin/krun-sol test/regression/swaps.sol test/regression/swaps.txn --dry-run > swap_command_without_summarization
RUN multitime -n 10 $(cat swap_command_without_summarization) 2> time_to_execute_1000_swap_without_summary.txt

# Run the test of 1000 Swaps with Summarization
RUN bin/krun-sol \
    test/examples/swaps/UniswapV2SwapRenamed.sol             \
    test/transactions/swaps/UniswapV2SwapRenamed/Swaps1K.txn \
    test/transactions/swaps/UniswapV2SwapRenamed/Swaps1K.smr --dry-run > swap_command_without_summarization
RUN multitime -n 10 $(cat swap_command_without_summarization) 2> time_to_execute_1000_swaps_with_summary.txt


# Output the time of the test executions
CMD ["sh", "-c", "echo 'Time to Execute test/regression/swaps.txn using Solidity-Lite Semantics: ' && \
                  tail -n 4 time_to_execute_1000_swap_without_summary.txt && \
                  echo '' && \
                  echo 'Time to Execute test/transactions/swaps/UniswapV2SwapRenamed/Swaps1K.txn using Solidity-Lite Semantics: ' && \
                  tail -n 4 time_to_execute_1000_swaps_with_summary.txt"]
