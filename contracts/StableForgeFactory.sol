// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./EUSD.sol";
import "./Bootstrapper.sol";

contract StableForgeFactory {
    address public aavePool;
    address public aerodromeRouter;
    address public aerodromeFactory;
    address public usdc;
    address public creator;

    event TokenDeployed(address token, string name, string symbol, uint256 supply);
    event BootstrapperDeployed(address bootstrapper);

    constructor(
        address aavePool_,
        address aerodromeRouter_,
        address aerodromeFactory_,
        address usdc_,
        address creator_
    ) {
        aavePool = aavePool_;
        aerodromeRouter = aerodromeRouter_;
        aerodromeFactory = aerodromeFactory_;
        usdc = usdc_;
        creator = creator_;
    }

    function deployToken(
        string memory name_,
        string memory symbol_,
        uint256 supply_
    ) external returns (address) {
        // Fees: 2% initial, 0.5% skim
        EUSD token = new EUSD(name_, symbol_, creator, supply_, 200, 50);
        emit TokenDeployed(address(token), name_, symbol_, supply_);
        return address(token);
    }

    function deployBootstrapper() external returns (address) {
        Bootstrapper b = new Bootstrapper(aerodromeRouter, creator, 50);
        emit BootstrapperDeployed(address(b));
        return address(b);
    }
}

