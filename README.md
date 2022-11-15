# DAIM - Decentralized Autonomous Information Markets
DAIM is a DAO that validates information in exchange for a fee, providing a platform for open and uncensored information markets created by the users themselves.

Anyone may propose or validate information markets to earn a share of the fees.
Anyone may place bets on active markets by staking ether. Winners take all.

DAIM has its own FACT token for governance and validation. Tokenomics ensure FACT price increases everytime a market is sucessfully validated which also makes it a good asset for investors.

## **Domain**

DABO is composed by:
* **Players**: place bets by staking ether
* **Validators**: validates bets by staking DAB tokens
*Proposers: creates betting proposals? by staking tokens? (<-- investigate this idea. will influence tokenomics)*

### **Players**
Players create **betting proposals** and place **bets** on existing proposals by staking ether. Winning **bets** makes players eligible to **claim rewards**. Losing **bets** lose their staked ether.

#### **Proposing Bets**
// TODO: description of a betting proposal? not easy

##### **Betting Proposal model**
* **description** (string): the proposal itself. a string describing what's the bet about. *e.g: Who will win the 2022 World Cup?*
* **closeBetsDate** (date): the deadline for placing bets
* **readyForValidationAt** (date): the date after which the bets may be validated
* **minimumStake** (uint): minimum stake for a bet *should this be included?*

#### **Placing bets**
Players may place their **bet** in active proposals by staking ether and describing his prediction. Staked ether is held in a pool: the **bet pool**.

When the proposal is validated, winners may claim their share of the **bet pool**. The bigger the stake, the bigger the share.

##### **Bet model**
* **bet** (string): player's bet. a string describing what's the predicted outcome. *e.g Portugal*
* **value** (uint): ether to stake

### **Validators**
Anyone can be a DABO validator by staking DAB tokens. Staking DAB is basically accepting a job offer: you are responsible for validating bets and getting a share of the fees everytime a bet is validated.

#### **Validating Bets**
Validators receive proposals to validate within a deadline defined by governance. To validate a bet, validators select which bets are correct. Validators may also mark the bet as unverifiable if they are unable to validate the outcome.

Not validating within the estipulated timeframe or wrongly validating bets is punished by slashing a portion of the staked DAB tokens.

#### **Claiming**
If DABO validators reach consensus on a bet outcome, the users who betted on the right outcome are eligible to claim their share of the **bet pool**. Winners who staked more ether are eligible to a bigger share of the pool.

If DABO validators reach consensus that the bet's outcome cannot be validated, all betters may withdraw their share of the pool, although fees will still be collected. This is to deincentivize the creation of hard/impossible to validate proposals.

If DABO validators do not reach consensus, fees won't be collected and betters may withdraw their share of the pool. DABO treasury may also cover gas costs of all bets in order to completely refund betters.

#### **Bet Pool Distribution**
Although winners get the majority of the pool, the staked ether is distributed between 4 entities: 
* winners (bigger stake == bigger share)
* proposer (to incentivize proposal creation)
* validators (bigger stake == bigger share)
* DABO treasury

The share assigned to each entity is defined by DABO's decentralized governance.

#### **Validation Process**

* A proposal that is ready to be validated is assigned to a random group of validators (**validation round**)
* A consensus in the **validation round** is reached if at least X% of the random group total staked DAB has validated the same bets
* There needs to be at least X consecutive successful **validation rounds** for the proposal to be considered **validated**
* If there X consecutive consensus do not occur within X **validation rounds**, the proposal is considered **unvalidated**
* If the consensus was that the bet was unverifiable, the proposal is considered **unverifiable**
* After the proposal is considered **validated**, all validators that validated differently in the **validation rounds** are punished by burning a portion of staked DAB

## **Tokenomics**
**DAB** is a ERC20 token that is used for governance and validating bets. It acts as shares in the DABO.

**DAB** tokens may be purchased and sold for **ETH** through the DABO treasury.

**DAB** tokens price is always defined by `ETH in treasury` / `issued DAB tokens`. This means the first purchase will define the initial price of **DAB**. As bets get validated, ETH in treasury will increase (due to collected fees) which will increase the price of each **DAB** token. The price does not change when purchasing or selling **DAB**s through the treasury.

As **DAB** tokens potentially increase in value, investors may buy and sell for a profit without having to actively participate as validators. The incentive for staking your **DAB** to be an active validator is a proportional share of the fees generated by each validated bet. This accumulating value is in ETH and may be claimed at any time by the validator.

The **DABO** is only open for bets if there are at least X active validators with no more than X% staked **DAB**.

A curious consequence from these tokenomics is that if the DABO is failing and everyone sells their share, the price of the **DAB** may be redefined and DABO may ressurect with a different group of people.

TODO: supply

## **Software Architecture**

### **Smart Contracts**
#### **DAB**
TODO: description
TODO: state
TODO: API

#### **DAIMTreasury**
TODO: description
TODO: state
TODO: API

#### **DAIBookie**
This is the smart contract that players mostly interact with. It is responsible for:
* creating and placing bets
* holding player stakes
* transfering winning shares to rewards claimers

##### **State**
* `DAIMarkets bets`: bet catalogue
* `mapping(uint => string[])`: bets per proposal
* `mapping(uint => uint) betPools`: total staked ether per proposal
* `mapping(address => mapping(uint => uint)) playerStakes`: stakes per placed bet per address
* `uint minStake`: minimum stake to create and place a bet

##### **API**
* `propose(string description, uint betsClosedAt, uint readyForValidationAt) => uint proposalId`
* `payable propose(string description, uint betsClosedAt, uint readyForValidationAt, string bet) => uint proposalId`
* `payable place(string bet, uint proposalId)`
* `claimRewards(uint proposalId)`

#### **DAIMarkets**
This smart contracts acts as the bet catalogue. It allows `DAIBookie` to create new bets but is read-only to any other caller. It is responsible for:
* adding bets from `DAIBookie` to the catalogue
* getting bet details

##### **State**
* `DAIBookie bookie`
* `mapping(uint => Proposal) proposals`

##### **API**
* `create(Bet bet) => uint`
* `get(uint id) => Bet`


## doubts
* new contracts vs structs
* erc4646 
* multiple inheritance