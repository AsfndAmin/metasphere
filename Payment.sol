// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./IPayment.sol"; 

contract payment is IPayment {
    address private _admin;
    mapping(uint8 => address) private _addresses;

    constructor(address admin) {
        _admin = admin;
    }

    function getPaymentToken(uint8 pt)
        external
        view
        override
        returns (address)
    {
        return _addresses[pt];
    }

    /**
     * @dev set ERC-20 token to be used as payment currency
     * in vRent co
eyf-aadn-afq
