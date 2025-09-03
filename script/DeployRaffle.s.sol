//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscriptions, FundSubscription, AddConsumer} from "./interactions.s.sol";

contract DeployRaffle is Script {
    // Deploy the Raffle contract
    function run() external {}

    function DeployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        // config object has struct NetworkConfig declaration
        HelperConfig.NetworkConfig memory configr = helperConfig.getConfig();

        // we need to get subscribtion so
        if (configr.subscriptionId == 0) {
            // make new subscribtion
            CreateSubscriptions createSub = new CreateSubscriptions();
            (configr.subscriptionId, configr.vrfCoordinator) = createSub
                .createSubscribtions(configr.vrfCoordinator);

            // fund and create consumer
            FundSubscription fundsubscription = new FundSubscription();
            fundsubscription.fundSubscription(
                configr.vrfCoordinator,
                configr.subscriptionId,
                configr.link
            );
        }
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            configr.interval,
            configr.entranceFee,
            configr.vrfCoordinator,
            configr.gasLane,
            configr.subscriptionId,
            configr.callbackGasLimit
        );
        vm.stopBroadcast();
        // we make it without broadcast because we already have 2 broadcasts in function
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            configr.vrfCoordinator,
            configr.subscriptionId,
            address(raffle)
        );

        return (raffle, helperConfig);
    }
}
