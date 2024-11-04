FROM ubuntu:noble

# Setting the environment variables
ARG GETH_VERSION=1.13.14
ARG GO_VERSION=1.22.0

# Install the dependencies
RUN apt-get update && apt-get install -y wget cmake build-essential git bc

# Set the working directory
WORKDIR /workspace

# Retrieve GETH repo
RUN git clone https://github.com/ethereum/go-ethereum.git

# Checkout the correct version
WORKDIR /workspace/go-ethereum
RUN git checkout v${GETH_VERSION}

# Setup the ethereum tests submodule to the correct commit
RUN git submodule update --init --recursive
RUN cd tests/testdata && \
    git fetch origin dec74b8f0c2f1c1c65e327ace9446769d21279db && \
    git checkout dec74b8f0c2f1c1c65e327ace9446769d21279db

# Apply the patch to GETH
RUN wget https://gist.githubusercontent.com/Robertorosmaninho/e4f690b95c72f25adcb12410b21fbc23/raw/0542e94183bf682c9e28282b34f52bde86e30aa8/geth.patch -O geth.patch
RUN patch -p1 < geth.patch

# Install Go
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O go${GO_VERSION}.linux-amd64.tar.gz
RUN rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

# Add Go to the PATH
ENV PATH=$PATH:/usr/local/go/bin

# Build GETH
RUN export PATH=$PATH:/usr/local/go/bin && make all

# Create a new test directory inside the go-ethereum directory
RUN mkdir tests/uniswap02

# Download the test file
RUN wget https://raw.githubusercontent.com/Pi-Squared-Inc/solidity-demo-semantics/refs/heads/main/test/retesteth/swaps/filled/uniswap02.json -O tests/uniswap02/uniswap02.json

# Run the test
RUN cd tests && go test -timeout 60m -v -bench ./uniswap02 -run TestUniSwap

# Output the sum of hook_times.txt in seconds
CMD ["sh", "-c", "echo 'Time to Execute uniswap02.json using GETH 0'$(echo \"scale=3; $(cat tests/hook_times.txt)/1000000000\" | bc) 'seconds'"]