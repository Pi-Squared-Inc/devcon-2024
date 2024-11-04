ARG Z3_VERSION=4.13.0
ARG K_VERSION=7.1.166
ARG BASE_DISTRO=noble

FROM runtimeverificationinc/z3:ubuntu-${BASE_DISTRO}-${Z3_VERSION} as z3

FROM runtimeverificationinc/kframework-k:ubuntu-${BASE_DISTRO}-${K_VERSION}

COPY --from=z3 /usr/bin/z3 /usr/bin/z3

ARG LLVM_VERSION=16
ARG POETRY_VERSION=1.8.3

# Add the deadsnakes PPA to install Python 3.10
RUN apt-get install -y --no-install-recommends software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa

# Install the dependencies
RUN    apt-get update                  \
    && apt-get upgrade --yes           \
    && apt-get install --yes           \
    clang-${LLVM_VERSION}      \
    git                        \
    cmake                      \
    wget                       \
    bc                         \
    curl                       \
    debhelper                  \
    libboost-test-dev          \
    libcrypto++-dev            \
    libsecp256k1-dev           \
    libssl-dev                 \
    libyaml-dev                \
    llvm-${LLVM_VERSION}-dev   \
    llvm-${LLVM_VERSION}-tools \
    maven                      \
    python3.10                 \
    python3.10-venv            \
    python3.10-dev             \
    python3-pip

ARG HOME

## Install Poetry
RUN curl -sSL https://install.python-poetry.org -o install-poetry.py
RUN python3 install-poetry.py --version ${POETRY_VERSION} && rm install-poetry.py
ENV PATH=$HOME/.local/bin:$PATH

# Set the working directory
WORKDIR /workspace

## Retrieve the KEVM repo
RUN git clone https://github.com/Pi-Squared-Inc/evm-semantics.git

# Setup KEVM as the working directory
WORKDIR /workspace/evm-semantics
RUN git submodule update --init --recursive

# Apply the patch to KEVM
RUN wget https://gist.githubusercontent.com/Robertorosmaninho/3d872ca85fcb9170ad18ee7ebfebd31e/raw/71e66037f711ade13942b0aae62f1207142b5ea8/kevm.patch -O kevm.patch
RUN patch -p1 < kevm.patch

# Build KEVM
RUN make poetry
RUN CXX=clang++-${LLVM_VERSION} poetry -C kevm-pyk run kdist --verbose build -j`nproc` evm-semantics.kllvm evm-semantics.kllvm-runtime evm-semantics.llvm

# Download the test file
RUN wget https://raw.githubusercontent.com/Pi-Squared-Inc/solidity-demo-semantics/refs/heads/main/test/retesteth/swaps/filled/uniswap02.json -O uniswap02.json

# Run the test
RUN poetry -C kevm-pyk run kevm-pyk run --target llvm --mode NORMAL --schedule SHANGHAI --chainid 1 --output kore ./uniswap02.json

# Output the sum of hook_times.txt in seconds
CMD ["sh", "-c", "echo 'Time to Execute uniswap02.json using KEVM '$(echo \"scale=3; $(cat hook_times.txt)/1000000000\" | bc) 'seconds'"]