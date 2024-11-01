// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC4907} from "../interfaces/IERC4907.sol";
import {IERC5006} from "../interfaces/IERC5006.sol";
import {ERC4907} from "../src/ERC4907.sol";
import {ERC5006} from "../src/ERC5006.sol";
import {PoplusERC721} from "../src/PoplusERC721.sol";
import {PoplusERC1155} from "../src/PoplusERC1155.sol";

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {OwnableUpgradeable} from "../upgradeable/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "../upgradeable/ReentrancyGuardUpgradeable.sol";

import {Create2} from "openzeppelin-contracts/contracts/utils/Create2.sol";

contract NftFactory is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct NftInfo {
        string name;
        string symbol;
        string uri;
        uint256 recordLimit;
        uint8 nftType; // 1: ERC721, 2: ERC1155, 3: ERC4907, 4: ERC5006
    }

    event NftDeployed(
        address indexed contractAddress,
        bytes32 indexed salt,
        uint8 nftType
    );

    /// @notice 초기화 함수
    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev NFT 계약을 배포합니다.
     * @param info 배포할 NFT의 정보
     * @param salt 배포에 사용할 salt 값
     * @return contractAddress 배포된 NFT 계약의 주소
     */
    function deployNft(
        NftInfo memory info,
        uint256 salt
    ) external nonReentrant returns (address contractAddress) {
        bytes32 computedSalt = bytes32(salt);

        address addr = computeAddress(info, salt);
        uint256 codeSize = addr.code.length;

        require(codeSize == 0, "Contract already deployed with this salt");

        if (info.nftType == 1) {
            contractAddress = _deploy721(computedSalt, info.name, info.symbol);
        } else if (info.nftType == 2) {
            contractAddress = _deploy1155(
                computedSalt,
                info.uri,
                info.name,
                info.symbol
            );
        } else if (info.nftType == 3) {
            contractAddress = _deploy4907(computedSalt, info.name, info.symbol);
        } else if (info.nftType == 4) {
            contractAddress = _deploy5006(
                computedSalt,
                info.recordLimit,
                info.uri,
                info.name,
                info.symbol
            );
        }

        emit NftDeployed(contractAddress, computedSalt, info.nftType);
    }

    /**
     * @dev 배포될 NFT 계약의 주소를 예측합니다.
     * @param info NFT의 정보
     * @param salt 배포에 사용할 salt 값
     * @return predicted 예측된 계약 주소
     */
    function computeAddress(
        NftInfo memory info,
        uint256 salt
    ) public view returns (address predicted) {
        bytes32 computedSalt = bytes32(salt);
        bytes memory bytecode;

        if (info.nftType == 1) {
            bytecode = abi.encodePacked(
                type(PoplusERC721).creationCode,
                abi.encode(info.name, info.symbol)
            );
        } else if (info.nftType == 2) {
            bytecode = abi.encodePacked(
                type(PoplusERC1155).creationCode,
                abi.encode(info.name, info.symbol, info.uri)
            );
        } else if (info.nftType == 3) {
            bytecode = abi.encodePacked(
                type(ERC4907).creationCode,
                abi.encode(info.name, info.symbol)
            );
        } else if (info.nftType == 4) {
            bytecode = abi.encodePacked(
                type(ERC5006).creationCode,
                abi.encode(info.name, info.symbol, info.uri, info.recordLimit)
            );
        } else {
            revert("Invalid NFT type");
        }

        bytes32 bytecodeHash = keccak256(bytecode);
        predicted = Create2.computeAddress(
            computedSalt,
            bytecodeHash,
            address(this)
        );
    }

    /**
     * @dev PoplusERC721 계약을 배포합니다.
     * @param _salt 배포에 사용할 salt 값
     * @param _name PoplusERC721 계약의 이름
     * @param _symbol PoplusERC721 계약의 심볼
     * @return contractAddress 배포된 PoplusERC721 계약의 주소
     */
    function _deploy721(
        bytes32 _salt,
        string memory _name,
        string memory _symbol
    ) private returns (address contractAddress) {
        bytes memory bytecode = abi.encodePacked(
            type(PoplusERC721).creationCode,
            abi.encode(_name, _symbol)
        );

        contractAddress = Create2.deploy(0, _salt, bytecode);
    }

    /**
     * @dev ERC4907 계약을 배포합니다.
     * @param _salt 배포에 사용할 salt 값
     * @param _name ERC4907 계약의 이름
     * @param _symbol ERC4907 계약의 심볼
     * @return contractAddress 배포된 ERC4907 계약의 주소
     */
    function _deploy4907(
        bytes32 _salt,
        string memory _name,
        string memory _symbol
    ) private returns (address contractAddress) {
        bytes memory bytecode = abi.encodePacked(
            type(ERC4907).creationCode,
            abi.encode(_name, _symbol)
        );

        contractAddress = Create2.deploy(0, _salt, bytecode);
    }

    /**
     * @dev PoplusERC1155 계약을 배포합니다.
     * @param _salt 배포에 사용할 salt 값
     * @param _uri PoplusERC1155 계약의 URI
     * @param _name PoplusERC1155 계약의 이름
     * @param _symbol PoplusERC1155 계약의 심볼
     * @return contractAddress 배포된 PoplusERC1155 계약의 주소
     */
    function _deploy1155(
        bytes32 _salt,
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) private returns (address contractAddress) {
        bytes memory bytecode = abi.encodePacked(
            type(PoplusERC1155).creationCode,
            abi.encode(_name, _symbol, _uri)
        );

        contractAddress = Create2.deploy(0, _salt, bytecode);
    }

    /**
     * @dev ERC5006 계약을 배포합니다.
     * @param _salt 배포에 사용할 salt 값
     * @param _limit ERC5006 계약의 recordLimit
     * @param _uri ERC5006 계약의 URI
     * @param _name ERC5006 계약의 이름
     * @param _symbol ERC5006 계약의 심볼
     * @return contractAddress 배포된 ERC5006 계약의 주소
     */
    function _deploy5006(
        bytes32 _salt,
        uint256 _limit,
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) private returns (address contractAddress) {
        bytes memory bytecode = abi.encodePacked(
            type(ERC5006).creationCode,
            abi.encode(_name, _symbol, _uri, _limit)
        );

        contractAddress = Create2.deploy(0, _salt, bytecode);
    }
}
