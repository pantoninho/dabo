// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {DAIM} from "../src/DAIM.sol";

contract DAIMScript is Script {
    DAIM daim;

    struct Bet {
        uint256 pkey;
        string bet;
        uint256 stake;
    }

    function setUp() public {}

    function run() public returns (DAIM _daim) {
        vm.startBroadcast(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        );
        daim = new DAIM();
        vm.stopBroadcast();

        Bet[] memory bets1 = new Bet[](5);
        bets1[0] = Bet(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80,
            "Portugal",
            1 ether
        );

        bets1[1] = Bet(
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d,
            "Spain",
            1 ether
        );

        bets1[2] = Bet(
            0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a,
            "Brazil",
            2 ether
        );

        bets1[3] = Bet(
            0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6,
            "Brazil",
            0.5 ether
        );

        bets1[4] = Bet(
            0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6,
            "England",
            0.5 ether
        );

        addProposal(
            "Who will win the World Cup 2022?",
            "Sports",
            block.timestamp + 1 days,
            block.timestamp + 1 days,
            bets1
        );

        Bet[] memory bets2 = new Bet[](5);
        bets2[0] = Bet(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80,
            "Trump",
            4 ether
        );

        bets2[1] = Bet(
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d,
            "Obama",
            1 ether
        );

        bets2[2] = Bet(
            0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a,
            "Obama",
            2 ether
        );

        bets2[3] = Bet(
            0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6,
            "Obama",
            1 ether
        );

        bets2[4] = Bet(
            0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6,
            "Trump",
            0.5 ether
        );

        addProposal(
            "Who will win the US Elections?",
            "Politics",
            block.timestamp + 1 days,
            block.timestamp + 1 days,
            bets2
        );

        Bet[] memory bets3 = new Bet[](5);
        bets3[0] = Bet(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80,
            "Yes",
            1 ether
        );

        bets3[1] = Bet(
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d,
            "Yes",
            1 ether
        );

        bets3[2] = Bet(
            0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a,
            "Yes",
            2 ether
        );

        bets3[3] = Bet(
            0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6,
            "No",
            1 ether
        );

        bets3[4] = Bet(
            0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6,
            "No",
            0.5 ether
        );

        addProposal(
            "Will ETH trade at $5k in 2023?",
            "Economy",
            block.timestamp + 1 days,
            block.timestamp + 1 days,
            bets3
        );

        vm.stopBroadcast();
        return daim;
    }

    function addProposal(
        string memory description,
        string memory category,
        uint256 betsClosedAt,
        uint256 readyForValidationAt,
        Bet[] memory bets
    ) internal {
        vm.startBroadcast(
            0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
        );
        uint256 id = daim.bookie().propose(
            description,
            category,
            betsClosedAt,
            readyForValidationAt
        );
        vm.stopBroadcast();

        for (uint256 i = 0; i < bets.length; i++) {
            vm.startBroadcast(bets[i].pkey);
            placeBet(id, bets[i].bet, bets[i].stake);
            vm.stopBroadcast();
        }
    }

    function placeBet(
        uint256 proposalId,
        string memory bet,
        uint256 stake
    ) internal {
        daim.bookie().placeBet{value: stake}(proposalId, bet);
    }
}
