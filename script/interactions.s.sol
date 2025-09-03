// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Raffle} from "src/raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscriptions is Script {
    // making subscribtion from vrfcordinator
    function createSubscribtionConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfcoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSubscribtions(vrfcoordinator);
        return (subId, vrfcoordinator);
    }

    function createSubscribtions(
        address vrfcoordinator
    ) public returns (uint256, address) {
        console.log("Creating subscribtion on chain ID ", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfcoordinator)
            .createSubscription();
        vm.stopBroadcast();

        console.log("Subscribtion ID is ", subId);
        return (subId, vrfcoordinator);
    }

    function run() external returns (uint256, address) {
        return createSubscribtionConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        if (subscriptionId == 0) {
            CreateSubscriptions createSub = new CreateSubscriptions();
            (uint256 updatedSubId, address updatedVRFv2) = createSub.run();
            subscriptionId = updatedSubId;
            vrfCoordinator = updatedVRFv2;
            console.log(
                "New SubId Created! ",
                subscriptionId,
                "VRF Address: ",
                vrfCoordinator
            );
        }

        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address linkToken
    ) public {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On chainId: ", block.chainid);
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT * 1000
            );
            vm.stopBroadcast();
        } else {
            console.log(LinkToken(linkToken).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(linkToken).balanceOf(address(this)));
            console.log(address(this));
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script, CodeConstants {
    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;

        console.log("Raffle address: ", raffle);
        console.log("VRF Coordinator: ", vrfCoordinator);
        console.log("Subscription ID: ", subId);

        addConsumer(vrfCoordinator, subId, raffle);
    }

    function addConsumer(
        address vrfCoordinator,
        uint256 subscriptionId,
        address consumer
    ) public {
        console.log("Adding consumer to subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On chainId: ", block.chainid);
        vm.startBroadcast();
        // addconsumer in mock contract not this
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            consumer
        );
        vm.stopBroadcast();
    }

    function run() public {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }
}
