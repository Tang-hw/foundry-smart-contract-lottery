// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        //这句就会自动把block chainId 注入到getConfigByChainId方法里
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        //creata subscription 如果订阅Id为0，就创建一个新的订阅，获取ID和地址
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (
                config.subscriptionId,
                config.vrfCoordinatorV2_5
            ) = createSubscription.createSubscription(
                config.vrfCoordinatorV2_5,
                config.account
            );
        }
        //fund subscription 给订阅充钱
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(
            config.vrfCoordinatorV2_5,
            config.subscriptionId,
            config.link,
            config.account
        );

        //deploy contract Raffle
        vm.startBroadcast();
        Raffle raffe = new Raffle(
            config.raffleEntranceFee,
            config.automationUpdateInterval,
            config.vrfCoordinatorV2_5,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        //add customer address 添加消费合约地址
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffe),
            config.vrfCoordinatorV2_5,
            config.subscriptionId,
            config.account
        );

        return (raffe, helperConfig);
    }

    function run() public {
        deployContract();
    }
}
