const ethers = require('ethers');
const daimAbi = require('../smart-contracts/daim/daim.abi.json');
const bookieAbi = require('../smart-contracts/daim/bookie.abi.json');
const marketsAbi = require('../smart-contracts/daim/daimarkets.abi.json');

const provider = new ethers.providers.JsonRpcProvider();
const address = '0x5FbDB2315678afecb367f032d93F642f64180aa3';

const accounts = [
  0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80n,
  0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690dn,
  0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365an,
  0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6n,
  0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926an,
  0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffban,
  0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564en,
  0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356n,
  0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97n,
  0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6n,
];

const markets = [
  {
    description: 'Who will win the Qatar 2022 World Cup?',
    category: 'Sports',
    betsCloseAt: getTimeInUnixEpochSeconds(10),
    readyForValidationAt: getTimeInUnixEpochSeconds(11),
    proposer: accounts[0],
    bets: ['portugal', 'brazil', 'spain', 'england'],
  },
  {
    description: 'Who will win the 2022 US elections?',
    category: 'Politics',
    betsCloseAt: getTimeInUnixEpochSeconds(10),
    readyForValidationAt: getTimeInUnixEpochSeconds(11),
    proposer: accounts[1],
    bets: ['democrats', 'republicans'],
  },
  {
    description: 'Will ETH trade at $5k in 2022?',
    category: 'Economy',
    betsCloseAt: getTimeInUnixEpochSeconds(100),
    readyForValidationAt: getTimeInUnixEpochSeconds(100),
    proposer: accounts[2],
    bets: ['yes', 'no'],
  },
  {
    description: 'Will we live in economic recession in 2023?',
    category: 'Economy',
    betsCloseAt: getTimeInUnixEpochSeconds(365 * 2),
    readyForValidationAt: getTimeInUnixEpochSeconds(365 * 2),
    proposer: accounts[3],
    bets: ['yes', 'no'],
  },
  {
    description: 'How many hurricans will hit Florida in 2023?',
    category: 'World Events',
    betsCloseAt: getTimeInUnixEpochSeconds(365 * 2),
    readyForValidationAt: getTimeInUnixEpochSeconds(365 * 2),
    proposer: accounts[4],
    bets: ['10', '20', '30', '50'],
  },
  {
    description:
      'Which month will the next album of Badjeka Badjouran be released?',
    category: 'Arts',
    betsCloseAt: getTimeInUnixEpochSeconds(100),
    readyForValidationAt: getTimeInUnixEpochSeconds(100),
    proposer: accounts[3],
    bets: ['May', 'June', 'August', 'December', 'January', 'March'],
  },
];

async function run() {
  const contract = new ethers.Contract(address, daimAbi, provider);
  const bookieAddress = await contract.bookie();
  let bookie = new ethers.Contract(bookieAddress, bookieAbi, provider);

  for (let i = 0; i < markets.length; i++) {
    const m = markets[i];
    const signerIndex = i % accounts.length;
    bookie = bookie.connect(provider.getSigner(signerIndex));

    console.log('PROPOSING:', m.description);
    const tx = await bookie[`propose(string,string,uint256,uint256)`](
      m.description,
      m.category,
      m.betsCloseAt,
      m.readyForValidationAt
    );

    const receipt = await tx.wait();
    const { args } = receipt.events[0];

    console.log('PLACING BETS ON:', m.description);
    await placeBets(args[0], m.bets);
  }
}

async function placeBets(marketId, bets) {
  const contract = new ethers.Contract(address, daimAbi, provider);
  const bookieAddress = await contract.bookie();
  let bookie = new ethers.Contract(bookieAddress, bookieAbi, provider);
  const numberOfBets = 10;

  for (let i = 0; i < bets.length; i++) {
    const bet = bets[i];

    for (let j = 0; j < numberOfBets; j++) {
      const signerIndex = Math.floor(Math.random() * accounts.length);
      bookie = bookie.connect(provider.getSigner(signerIndex));
      const stake = (Math.random() * 5).toFixed(4);

      console.log(`PLACING "${bet}" with stake ${stake}`);
      const tx = await bookie.placeBet(marketId, bet, {
        value: ethers.utils.parseEther(stake),
      });

      tx.wait();
    }
  }
}

async function getActiveMarkets() {
  const contract = new ethers.Contract(address, daimAbi, provider);
  const marketsAddress = await contract.bets();
  const markets = new ethers.Contract(marketsAddress, marketsAbi, provider);

  console.log(await markets.getActiveProposals());
}

// getActiveMarkets();
run();

function getTimeInUnixEpochSeconds(incrementDays) {
  return Math.round(new Date().getTime() / 1000) + incrementDays * 24 * 60 * 60;
}
