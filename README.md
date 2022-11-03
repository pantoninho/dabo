# DABO - Decentralized Autonomous Betting Organization
# DAVO - Decentralized Autonomous Validation Organization?
DABO validates bets in return for a fee.

Users may open bets about anything and a decentraliatzed group of validators will validate who's the winner. Smart contracts guarantee that winners will get their share of the bet pool and collect fees back to the organization.

## **Domain**

DABO is composed by two different actors:
* **Betters**: place bets by staking ether
* **Validators**: validates bets by staking DAB tokens

### **Betters**
Anyone can place bets on the system. Bets may be placed in a new bet or an existing one.

#### **Creating a Bet**
To create a bet, users needs to provide ether as stake and define the following fields:

* **description** (string): the *bet* itself. a string describing what's the bet. *e.g: Who will win the 2022 World Cup?*
* **bet** (string): your bet. a string describing what you bet on. *e.g Portugal*
* **closingDate** (date): the deadline for placing bets
* **validationDate** (date): the date after which the bet may be validated
* **minimumStake** ?

Creating a bet creates a pool where all the staked ether for this bet will be locked.

#### **Placing in existing bet (is this correct english?)**
Users may place their bet in an ongoing bet by staking ether. Staked ether will be locked in the bet's pool.

#### **Claiming Prizes**
If DABO validators reach consensus on a bet outcome, the users who betted on the right answer are eligible to claim their share of the bet pool. Winners who staked more ether are eligible to a bigger share of the pool.

If DABO validators reach consensus that the bet's outcome cannot be validated, all betters may withdraw their share of the pool, although fees will still be collected. This is to deincentivize the creation of hard/impossible to validate bets.

If DABO validators do not reach consensus, fees won't be collected and betters may withdraw their share of the pool. DABO treasury may also cover gas costs of all bets in order to completely refund betters.

#### **Bet Pool Distribution**
Although winners get the majority of the pool, the staked ether is distributed between 4 entities: 
* bet winners (bigger stake == bigger share)
* bet creator (to incentivize bet creation)
* validators (bigger stake == bigger share)
* DABO treasury

The share assigned to each entity is defined by DABO's decentralized governance.

### **Validators**
Anyone can be a DABO validator by staking DAB tokens. Staking DAB is basically accepting a job offer: you are responsible for validating bets and getting a share of the fees everytime a bet is validated.

#### **Validating Bets**
Validators receive bets to validate within a deadline defined by governance. To validate a bet, validators select which bet entries are correct. Validators may also mark the bet as unverifiable if they are unable to validate the outcome.

Not validating within the estipulated timeframe or wrongly validating bets is punished by slashing a portion of the staked DAB tokens.

#### **Validation Process**

* A bet that is ready to be validated is assigned to a random group of validators (**validation round**)
* A consensus in the **validation round** is reached if at least X% of the random group total staked DAB has validated the same outcome
* There needs to be at least X consecutive successful **validation rounds** for a bet to be considered **validated**
* If there X consecutive consensus do not occur within X **validation rounds**, the bet is considered **unvalidated**
* If the consensus was that the bet was unverifiable, the bet is considered **unverifiable**
* After the bet is considered **validated**, all validators that validated differently in the **validation rounds** are punished by burning a portion of staked DAB

### **DABO Treasury**
The treasury is the entity that manages **DAB** tokens and holds the value of the DABO. It is responsible for minting and burning tokens and maintaining the price of each **DAB**. It is also reponsible for holding staked **DAB**s and claimable rewards.

A share of each bet fee is always sent to the treasury.

### **DAB Office**?
The office is the entity that manages validators. Validators may get a list of pending validations and act upon them by interacting with the office contract.

It is responsible for managing the validation process for each bet and collecting the fees. Office communicates with the treasury to transfer fees and request slashes to staked **DAB**.

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
#### **DABOTreasury**
#### **DABOffice**