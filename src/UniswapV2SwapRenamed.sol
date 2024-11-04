// SPDX-License-Identifier: MIT

// The source code of this contract uses the following contracts
// UniswapV2SwapExamples: https://solidity-by-example.org/defi/uniswap-v2/
// For the Router: https://github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router02.sol
// For the Pairs: https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol

pragma solidity ^0.8.24;

interface iERC20 {
    function balanceOf(address owner) external returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

contract uniswapV2Swap {

    iERC20 public weth;
    iERC20 public dai;
    iERC20 public usdc;
    uniswapV2Router02 public router;

    constructor(address vidWeth, address vidDai, address vidUsdc){
        weth = iERC20(vidWeth);
        dai = iERC20(vidDai);
        usdc = iERC20(vidUsdc);
        router = new uniswapV2Router02();
        router.setLocalPair(vidWeth, vidDai);
        router.setLocalPair(vidWeth, vidUsdc);
        router.setLocalPair(vidUsdc, vidDai);
    }

    function swapSingleHopExactAmountIn(uint256 amountIn, uint256 amountOutMin)
        external
        returns (uint256 amountOut)
    {
        weth.transferFrom(msg.sender, address(this), amountIn);
        weth.approve(address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(dai);

        uint256[] memory amounts = router.swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender);

        return amounts[1];
    }

    function swapMultiHopExactAmountIn(uint256 amountIn, uint256 amountOutMin)
        external
        returns (uint256 amountOut)
    {
        dai.transferFrom(msg.sender, address(this), amountIn);
        dai.approve(address(router), amountIn);

        address[] memory path = new address[](3);
        path[0] = address(dai);
        path[1] = address(weth);
        path[2] = address(usdc);

        uint256[] memory amounts = router.swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender);

        return amounts[2];
    }

    function swapSingleHopExactAmountOut(
        uint256 amountOutDesired,
        uint256 amountInMax
    ) external returns (uint256 amountOut) {
        weth.transferFrom(msg.sender, address(this), amountInMax);
        weth.approve(address(router), amountInMax);

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(dai);

        uint256[] memory amounts = router.swapTokensForExactTokens(amountOutDesired, amountInMax, path, msg.sender);

        if (amounts[0] < amountInMax) {
            weth.transfer(msg.sender, amountInMax - amounts[0]);
        }

        return amounts[1];
    }

    function swapMultiHopExactAmountOut(
        uint256 amountOutDesired,
        uint256 amountInMax
    ) external returns (uint256 amountOut) {
        dai.transferFrom(msg.sender, address(this), amountInMax);
        dai.approve(address(router), amountInMax);

        address[] memory path = new address[](3);
        path[0] = address(dai);
        path[1] = address(weth);
        path[2] = address(usdc);

        uint256[] memory amounts = router.swapTokensForExactTokens(amountOutDesired, amountInMax, path, msg.sender);

        if (amounts[0] < amountInMax) {
            dai.transfer(msg.sender, amountInMax - amounts[0]);
        }

        return amounts[2];
    }
}

contract uniswapV2Router02 {

    mapping (address pairEl1 => mapping (address pairEl2 => address)) public localPairs;

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external returns (uint[] memory amounts) {
        amounts = uniswapV2LibraryGetAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        iERC20(path[0]).transferFrom(msg.sender, uniswapV2LibraryPairFor(path[0], path[1]), amounts[0]);
        fidSwap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to
    ) external returns (uint[] memory amounts) {
        amounts = uniswapV2LibraryGetAmountsIn(amountOut, path);
        require(amounts[0] <= amountInMax, "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT");
        iERC20(path[0]).transferFrom(msg.sender, uniswapV2LibraryPairFor(path[0], path[1]), amounts[0]);
        fidSwap(amounts, path, to);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external returns (uint[] memory amountsLiq) {
        amountsLiq = new uint[](3);

        uint[] memory amounts = fidAddLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );

        amountsLiq[0] = amounts[0];
        amountsLiq[1] = amounts[1];

        address pair = uniswapV2LibraryPairFor(tokenA, tokenB);
        iERC20(tokenA).transferFrom(msg.sender, pair, amounts[0]);
        iERC20(tokenB).transferFrom(msg.sender, pair, amounts[1]);
        amountsLiq[2] = uniswapV2Pair(pair).mint(to);
    }

    function fidAddLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint[] memory amounts) {
        amounts = new uint[](2);

        require(getLocalPair(tokenA, tokenB) != address(0));

        uint[] memory reserves = uniswapV2LibraryGetReserves(tokenA, tokenB);
        if (reserves[0] == 0 && reserves[1] == 0) {
            amounts[0] = amountADesired;
            amounts[1] = amountBDesired;
        } else {
            uint amountBOptimal = uniswapV2LibraryQuote(
                amountADesired,
                reserves[0],
                reserves[1]
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "UniswapV2Router: INSUFFICIENT_B_AMOUNT"
                );
                amounts[0] = amountADesired;
                amounts[1] = amountBOptimal;
            } else {
                uint amountAOptimal = uniswapV2LibraryQuote(
                    amountBDesired,
                    reserves[1],
                    reserves[0]
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "UniswapV2Router: INSUFFICIENT_A_AMOUNT"
                );
                amounts[0] = amountAOptimal;
                amounts[1] = amountBDesired;
            }
        }
    }


    function setLocalPair(address tokenA, address tokenB) public{
        address[] memory tokens = uniswapV2LibrarySortTokens(tokenA, tokenB);
        localPairs[tokens[0]][tokens[1]] = address(new uniswapV2Pair(address(tokens[0]), address(tokens[1])));
    }

    function getLocalPair(address tokenA, address tokenB) public returns(address pair){
        address[] memory tokens = uniswapV2LibrarySortTokens(tokenA, tokenB);
        pair = localPairs[tokens[0]][tokens[1]];
    }

    function syncLocalPair(address tokenA, address tokenB) public{
        address[] memory tokens = uniswapV2LibrarySortTokens(tokenA, tokenB);
        uniswapV2Pair(localPairs[tokens[0]][tokens[1]]).sync();
    }

    function fidSwap(uint[] memory amounts, address[] memory path, address vidTo) private {
        for (uint i; i < path.length - 1; i++) {
            address input = path[i];
            address output = path[i + 1];
            address[] memory tokens = uniswapV2LibrarySortTokens(input, output);
            uint amountOut = amounts[i + 1];
            
            uint amount0Out = input == tokens[0] ? uint(0) : amountOut;
            uint amount1Out = input == tokens[0] ? amountOut : uint(0);
            address to = i < path.length - 2 ? uniswapV2LibraryPairFor(output, path[i + 2]) : vidTo;
            uniswapV2Pair(uniswapV2LibraryPairFor(input, output)).swap(
                amount0Out, amount1Out, to);
        }
    }

    function uniswapV2LibraryPairFor(address tokenA, address tokenB) private returns (address pair) {
        address[] memory tokens = uniswapV2LibrarySortTokens(tokenA, tokenB);
        pair = localPairs[tokens[0]][tokens[1]];
    }

    function uniswapV2LibrarySortTokens(address tokenA, address tokenB) private returns (address[] memory tokens) {
        tokens = new address[](2);
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        tokens[0] = tokenA < tokenB ? tokenA : tokenB;
        tokens[1] = tokenA < tokenB ? tokenB : tokenA;
        require(tokens[0] != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    function uniswapV2LibraryGetAmountsOut(uint amountIn, address[] memory path) private returns (uint[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            uint[] memory reserves = uniswapV2LibraryGetReserves(path[i], path[i + 1]);
            amounts[i + 1] = uniswapV2LibraryGetAmountOut(amounts[i], reserves[0], reserves[1]);
        }
    }

    function uniswapV2LibraryGetAmountOut(uint amountIn, uint reserveIn, uint reserveOut) private returns (uint amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn*997;
        uint numerator = amountInWithFee*reserveOut;
        uint denominator = reserveIn*1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function uniswapV2LibraryGetReserves(address tokenA, address tokenB) private returns (uint[] memory reserves) {
        reserves = new uint[](2);
        address[] memory tokens = uniswapV2LibrarySortTokens(tokenA, tokenB);
        uint112[] memory pairReserves = uniswapV2Pair(uniswapV2LibraryPairFor(tokenA, tokenB)).getReserves();
        reserves[0] = tokenA == tokens[0] ? pairReserves[0] : pairReserves[1];
        reserves[1] = tokenA == tokens[0] ? pairReserves[1] : pairReserves[0];
    }
    
    function uniswapV2LibraryGetAmountsIn(uint amountOut, address[] memory path) private returns (uint[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            uint[] memory reserves = uniswapV2LibraryGetReserves(path[i - 1], path[i]);
            amounts[i - 1] = uniswapV2LibraryGetAmountIn(amounts[i], reserves[0], reserves[1]);
        }
    }

    function uniswapV2LibraryGetAmountIn(uint amountOut, uint reserveIn, uint reserveOut) private returns (uint amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn*amountOut*1000;
        uint denominator = (reserveOut-amountOut)*997;
        amountIn = denominator != 0 ? (numerator / denominator) + 1 : 1;
    }

    function uniswapV2LibraryQuote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) internal returns (uint amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * reserveB) / reserveA;
    }
}

contract uniswapV2Pair{

    uint256 private constUINT112MAX = 0xffffffffffffffffffffffffffff;

    address public token0;
    address public token1;

    uint112 private reserve0;           
    uint112 private reserve1;           
    uint32  private blockTimestampLast; 

    uint public constMINIMUMLIQUIDITY = 10**3;
    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public totalSupply;
    uint public kLast; 
    
    mapping(address act => uint) public balanceOf;
    
    event syncEvent(uint112 reserve0, uint112 reserve1);
    event swapEvent(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event mintEvent(address indexed sender, uint amount0, uint amount1);

    constructor(address vidToken0, address vidToken1) {
        token0 = vidToken0;
        token1 = vidToken1;
    }

    function swap(uint amount0Out, uint amount1Out, address to) external {
        require(amount0Out > 0 || amount1Out > 0, "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT");
        uint112[] memory reserves = getReserves(); // gas savings
        require(amount0Out < reserves[0] && amount1Out < reserves[1], "UniswapV2: INSUFFICIENT_LIQUIDITY");

        uint balance0;
        uint balance1;
        { // scope for vidToken{0,1}, avoids stack too deep errors
            address vidToken0 = token0;
            address vidToken1 = token1;
            require(to != vidToken0 && to != vidToken1, "UniswapV2: INVALID_TO");
            if (amount0Out > 0) iERC20(vidToken0).transfer(to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) iERC20(vidToken1).transfer(to, amount1Out); // optimistically transfer tokens
            balance0 = iERC20(vidToken0).balanceOf(address(this));
            balance1 = iERC20(vidToken1).balanceOf(address(this));
        }
        uint amount0In = balance0 > reserves[0] - amount0Out ? balance0 - (reserves[0] - amount0Out) : 0;
        uint amount1In = balance1 > reserves[1] - amount1Out ? balance1 - (reserves[1] - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "UniswapV2: INSUFFICIENT_INPUT_AMOUNT");
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = (balance0*1000)-(amount0In*3);
            uint balance1Adjusted = (balance1*1000)-(amount1In*3);
            require(balance0Adjusted*balance1Adjusted >= uint(reserves[0])*reserves[1]*(1000**2), "UniswapV2: K");
        }

        fidUpdate(balance0, balance1, reserves[0], reserves[1]);
        emit swapEvent(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function mint(address to) external returns (uint liquidity) {
        uint112[] memory pairReserves = getReserves();
        uint balance0 = iERC20(token0).balanceOf(address(this));
        uint balance1 = iERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - pairReserves[0];
        uint amount1 = balance1 - pairReserves[1];

        //bool feeOn = fidMintFee(pairReserves[0], pairReserves[1]);
        uint vidTotalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in fidMintFee
        if (vidTotalSupply == 0) {
            liquidity = mathSqrt(amount0 * amount1) - constMINIMUMLIQUIDITY;
            totalSupply = totalSupply + constMINIMUMLIQUIDITY;
            balanceOf[address(0)] = balanceOf[address(0)] + constMINIMUMLIQUIDITY;
        } else {
            liquidity = mathMin(
                (amount0 * vidTotalSupply) / pairReserves[0],
                (amount1 * vidTotalSupply) / pairReserves[1]
            );
        }
        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        totalSupply = totalSupply + liquidity;
        balanceOf[to] = balanceOf[to] + liquidity;

        fidUpdate(balance0, balance1, pairReserves[0], pairReserves[1]);
        //if (feeOn) kLast = uint(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit mintEvent(msg.sender, amount0, amount1);
    }

    function sync() external {
        fidUpdate(iERC20(token0).balanceOf(address(this)), iERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
   
    function getReserves() public returns (uint112[] memory reserves) {
        reserves = new uint112[](3);
        reserves[0] = reserve0;
        reserves[1] = reserve1;
        reserves[2] = blockTimestampLast;
    }

    function mathMin(uint x, uint y) internal returns (uint z) {
        z = x < y ? x : y;
    }

    function mathSqrt(uint y) internal returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function fidUpdate(uint balance0, uint balance1, uint112 vidReserve0, uint112 vidReserve1) private {
        require(balance0 <= constUINT112MAX && balance1 <= constUINT112MAX, "UniswapV2: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && vidReserve0 != 0 && vidReserve1 != 0) {
            price0CumulativeLast = price0CumulativeLast + (vidReserve1/vidReserve0) * timeElapsed;
            price1CumulativeLast = price1CumulativeLast + (vidReserve0/vidReserve1) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit syncEvent(reserve0, reserve1);
    } 
}

contract wETHMock {

    uint256 private constUINT256MAX = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    mapping (address wethact => uint256) public balanceOf;
    mapping (address wethownr => mapping (address wethspdr => uint256)) public allowance;
    
    event approvalEvent(address indexed owner, address indexed spender, uint256 value);
    event transferEvent(address indexed from, address indexed to, uint256 value);

    function decimals() external returns (uint8) {
        return 18;
    }

    function deposit() external payable {
        balanceOf[msg.sender] = balanceOf[msg.sender] + msg.value;
        emit transferEvent(address(0), msg.sender, msg.value);
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit approvalEvent(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        if (to != address(0) && to != address(this)) { // Transfer
            uint256 balance = balanceOf[msg.sender];
            require(balance >= value, "WETH: transfer amount exceeds balance");

            balanceOf[msg.sender] = balance - value;
            balanceOf[to] = balanceOf[to] + value;
            emit transferEvent(msg.sender, to, value);
        } else { // Withdraw
            uint256 balance = balanceOf[msg.sender];
            require(balance >= value, "WETH: burn amount exceeds balance");
            balanceOf[msg.sender] = balance - value;
            emit transferEvent(msg.sender, address(0), value);

            (bool success, ) = msg.sender.call{value: value}("");
            require(success, "WETH: ETH transfer failed");
        }

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != constUINT256MAX) {
                require(allowed >= value, "WETH: request exceeds allowance");
                uint256 reduced = allowed - value;
                allowance[from][msg.sender] = reduced;
                emit approvalEvent(from, msg.sender, reduced);
            }
        }

        if (to != address(0) && to != address(this)) { 
            uint256 balance = balanceOf[from];
            require(balance >= value, "WETH: transfer amount exceeds balance");

            balanceOf[from] = balance - value;
            balanceOf[to] = balanceOf[to] + value;
            emit transferEvent(from, to, value);
        } else { 
            uint256 balance = balanceOf[from];
            require(balance >= value, "WETH: burn amount exceeds balance");
            balanceOf[from] = balance - value;
            emit transferEvent(from, address(0), value);

            (bool success, ) = msg.sender.call{value: value}("");
            require(success, "WETH: ETH transfer failed");
        }

        return true;
    }
}

contract dAIMock {

    uint private constUINTMAX = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 public totalSupply;

    mapping (address daiact => uint)                      public balanceOf;
    mapping (address daiownr => mapping (address daispdr => uint)) public allowance;

    event approvalEvent(address indexed src, address indexed guy, uint wad);
    event transferEvent(address indexed src, address indexed dst, uint wad);

    function decimals() external returns (uint8) {
        return 18;
    }

    function mint(address usr, uint wad) public {
        balanceOf[usr] = balanceOf[usr] + wad;
        totalSupply    = totalSupply + wad;
        emit transferEvent(address(0), usr, wad);
    }

    function mintOnDeposit(address usr, uint wad) public {
        mint(usr, wad);
    }
    
    function burn(address usr, uint wad) public {
        if(balanceOf[usr] >=  wad){
            balanceOf[usr] = balanceOf[usr] - wad;
            totalSupply    = totalSupply - wad;
        }
    }

    function approve(address usr, uint wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit approvalEvent(msg.sender, usr, wad);
        return true;
    }

    
    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public returns (bool)
    {
        require(balanceOf[src] >= wad, "Dai/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != constUINTMAX) {
            require(allowance[src][msg.sender] >= wad, "Dai/insufficient-allowance");
            allowance[src][msg.sender] = allowance[src][msg.sender] - wad;
        }
        balanceOf[src] = balanceOf[src] - wad;
        balanceOf[dst] = balanceOf[dst] + wad;
        emit transferEvent(src, dst, wad);
        return true;
    }

    function safeTransferFrom(address from, address to, uint256 value) external{
        transferFrom(from, to, value);
    }


}

contract uSDCMock {
    uint256 private constUINT256MAX = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 private vidTotalSupply;
        
    mapping(address account => uint256) private vidBalances;  
    mapping(address account => mapping(address spender => uint256)) private vidAllowances;

    event transferEvent(address indexed from, address indexed to, uint256 value);
    event approvalEvent(address indexed owner, address indexed spender, uint256 value);

    function decimals() external returns (uint8) {
        return 18;
    }

    function mint(address account, uint256 value) public {
        require(account != address(0), "USDC: invalid receiver");
        fidUpdate(address(0), account, value);
    }

    function balanceOf(address account) public returns (uint256) {
        return vidBalances[account];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        address owner = msg.sender;
        fidTransfer(owner, to, value);
        return true;
    }

    function allowance(address owner, address spender) public returns (uint256) {
        return vidAllowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        address owner = msg.sender;
        fidApprove(owner, spender, value, true);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        address spender = msg.sender;
        fidSpendAllowance(from, spender, value);
        fidTransfer(from, to, value);
        return true;
    }

    function fidTransfer(address from, address to, uint256 value) private {
        require(from != address(0), "USDC: invalid sender");
        require(to != address(0), "USDC: invalid receiver");
        fidUpdate(from, to, value);
    }

    function fidUpdate(address from, address to, uint256 value) private {
        if (from == address(0)) {
            vidTotalSupply = vidTotalSupply + value;
        } else {
            uint256 fromBalance = vidBalances[from];
            require(fromBalance >= value, "USDC: insufficient balance");
            vidBalances[from] = fromBalance - value;
            
        }

        if (to == address(0)) {
            vidTotalSupply = vidTotalSupply - value;
            
        } else {
            vidBalances[to] = vidBalances[to] + value;
        }

        emit transferEvent(from, to, value);
    }


    function fidApprove(address owner, address spender, uint256 value, bool emitEvent) private {
        require(owner != address(0), "USDC: invalid approver");
        require(spender != address(0), "USDC: invalid spender");
        vidAllowances[owner][spender] = value;
        if (emitEvent) {
            emit approvalEvent(owner, spender, value);
        }
    }

    function fidSpendAllowance(address owner, address spender, uint256 value) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != constUINT256MAX) {
            require(currentAllowance >= value, "USDC: insufficient allowance");
            fidApprove(owner, spender, currentAllowance - value, false);
            
        }
    }
    
    
}

contract uniswapV2SwapTest {

    uniswapV2Swap private vidUni;
    uniswapV2Router02 private vidRouter;
    wETHMock private vidWeth;
    dAIMock private vidDai;
    uSDCMock private vidUsdc;

    function setUp() public {
        vidWeth = new wETHMock();
        vidDai = new dAIMock();
        vidUsdc = new uSDCMock();
        vidUni = new uniswapV2Swap(address(vidWeth), address(vidDai), address(vidUsdc));
    }

    function testSwapSingleHopExactAmountIn() public {
        uint256 wethAmount = 1e18;
        vidWeth.deposit{value: 2*wethAmount}();
        vidWeth.approve(address(vidUni), 2*wethAmount);
        vidDai.mint(address(this), wethAmount);
        vidDai.approve(address(vidUni), wethAmount);
        
        vidWeth.transfer(vidUni.router().getLocalPair(address(vidWeth), address(vidDai)), wethAmount);
        vidDai.transfer(vidUni.router().getLocalPair(address(vidWeth), address(vidDai)), wethAmount);

        vidUni.router().syncLocalPair(address(vidWeth), address(vidDai));

        uint256 daiAmountMin = 1;
        uint256 daiAmountOut = vidUni.swapSingleHopExactAmountIn(wethAmount, daiAmountMin);

        assert(daiAmountOut >= daiAmountMin);
    }

    function testSwapMultiHopExactAmountIn() public {
        uint256 wethAmount = 1e18;
        
        vidWeth.deposit{value: 4*wethAmount}();
        vidWeth.approve(address(vidUni), 8*wethAmount);
        vidDai.mint(address(this), 3*wethAmount);
        vidDai.approve(address(vidUni), 3*wethAmount);
        vidUsdc.mint(address(this), 2*wethAmount);
        vidUsdc.approve(address(vidUni), 2*wethAmount);

        vidWeth.transfer(vidUni.router().getLocalPair(address(vidWeth), address(vidDai)), wethAmount);
        vidDai.transfer(vidUni.router().getLocalPair(address(vidWeth), address(vidDai)), wethAmount);

        vidUni.router().syncLocalPair(address(vidWeth), address(vidDai));

        uint256 daiAmountMin = 1;
        vidUni.swapSingleHopExactAmountIn(wethAmount, daiAmountMin);

        uint256 daiAmountIn = 1e18;
        
        vidDai.transfer(vidUni.router().getLocalPair(address(vidDai), address(vidWeth)), daiAmountIn);
        vidWeth.transfer(vidUni.router().getLocalPair(address(vidDai), address(vidWeth)), daiAmountIn);
        vidWeth.transfer(vidUni.router().getLocalPair(address(vidWeth), address(vidUsdc)), daiAmountIn);
        vidUsdc.transfer(vidUni.router().getLocalPair(address(vidWeth), address(vidUsdc)), daiAmountIn);

        vidUni.router().syncLocalPair(address(vidDai), address(vidWeth));
        vidUni.router().syncLocalPair(address(vidWeth), address(vidUsdc));

        uint256 usdcAmountOutMin = 1;
        uint256 usdcAmountOut =
            vidUni.swapMultiHopExactAmountIn(daiAmountIn, usdcAmountOutMin);

        assert(usdcAmountOut >= usdcAmountOutMin);
    }

    function testSwapSingleHopExactAmountOut() public {
        uint256 wethAmount = 1e18;
        vidWeth.deposit{value: 10*wethAmount}();
        vidWeth.approve(address(vidUni), 6*wethAmount);
        vidDai.mint(address(this), 10*wethAmount);
        vidDai.approve(address(vidUni), 4*wethAmount);
        
        vidWeth.transfer(vidUni.router().getLocalPair(address(vidWeth), address(vidDai)), 4*wethAmount);
        vidDai.transfer(vidUni.router().getLocalPair(address(vidWeth), address(vidDai)), 4*wethAmount);

        vidUni.router().syncLocalPair(address(vidWeth), address(vidDai));

        uint256 daiAmountDesired = 1e18;
        uint256 daiAmountOut =
            vidUni.swapSingleHopExactAmountOut(daiAmountDesired, 2*wethAmount);

        assert(daiAmountOut == daiAmountDesired);
    }

    function testSwapMultiHopExactAmountOut() public {
        uint256 wethAmount = 1e18;
        vidWeth.deposit{value: 20*wethAmount}();
        vidWeth.approve(address(vidUni), 20*wethAmount);
        vidDai.mint(address(this), 20*wethAmount);
        vidDai.approve(address(vidUni), 20*wethAmount);
        vidUsdc.mint(address(this), 10*wethAmount);
        vidUsdc.approve(address(vidUni), 10*wethAmount);

        vidWeth.transfer(vidUni.router().getLocalPair(address(vidWeth), address(vidDai)), 8*wethAmount);
        vidDai.transfer(vidUni.router().getLocalPair(address(vidWeth), address(vidDai)), 8*wethAmount);

        vidUni.router().syncLocalPair(address(vidWeth), address(vidDai));

        uint256 daiAmountOut = 2 * 1e18;
        vidUni.swapSingleHopExactAmountOut(daiAmountOut, 4*wethAmount);
        
        vidDai.transfer(vidUni.router().getLocalPair(address(vidDai), address(vidWeth)), 2*daiAmountOut);
        vidWeth.transfer(vidUni.router().getLocalPair(address(vidDai), address(vidWeth)), 2*daiAmountOut);
        vidWeth.transfer(vidUni.router().getLocalPair(address(vidWeth), address(vidUsdc)), 2*daiAmountOut);
        vidUsdc.transfer(vidUni.router().getLocalPair(address(vidWeth), address(vidUsdc)), 2*daiAmountOut);
        vidUni.router().syncLocalPair(address(vidDai), address(vidWeth));
        vidUni.router().syncLocalPair(address(vidWeth), address(vidUsdc));

        uint256 amountOutDesired = 1e6;
        uint256 amountOut =
            vidUni.swapMultiHopExactAmountOut(amountOutDesired, daiAmountOut);

        assert(amountOut == amountOutDesired);
    }

    function testRouterAddLiquidity() public {
        uint256 testAmount = 131072; // Hex: 0x20000
        uint desiredA = 10000; 
        uint desiredB = 10000; 
        uint minA = 0; 
        uint minB = 0; 

        vidRouter = new uniswapV2Router02();

        vidRouter.setLocalPair(address(vidWeth), address(vidDai));
        vidRouter.setLocalPair(address(vidWeth), address(vidUsdc));
        vidRouter.setLocalPair(address(vidUsdc), address(vidDai));

        vidDai.mint(address(this), testAmount);
        vidDai.approve(address(vidRouter), testAmount);
        vidUsdc.mint(address(this), testAmount);
        vidUsdc.approve(address(vidRouter), testAmount);

        vidRouter.addLiquidity(address(vidDai), address(vidUsdc), desiredA, desiredB, minA, minB, address(this));
   
        assert(vidDai.balanceOf(address(this)) == 121072);
        assert(vidUsdc.balanceOf(address(this)) == 121072);
        assert(vidDai.balanceOf(vidRouter.getLocalPair(address(vidDai), address(vidUsdc))) == 10000);
        assert(vidUsdc.balanceOf(vidRouter.getLocalPair(address(vidDai), address(vidUsdc))) == 10000);
        assert(uniswapV2Pair(vidRouter.getLocalPair(address(vidDai), address(vidUsdc))).balanceOf(address(this)) == 9000);
    }
}
