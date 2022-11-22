const ethers = require('ethers');
const daimAbi = require('../smart-contracts/daim/daim.abi.json');
const bookieAbi = require('../smart-contracts/daim/bookie.abi.json');

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

run();

async function run() {
  await addMarket({
    description: 'Who will win the 2021 portugal soccer cup?',
    category: 'Sports',
    betsCloseAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    readyForValidationAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    proposer: accounts[0],
    bets: ['Sporting', 'Benfica', 'Penafiel', 'Vitoria Setubal'],
  });
  await addMarket({
    description: 'Will bitcoin hit new lows in 2022?',
    category: 'Economy',
    betsCloseAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    readyForValidationAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    proposer: accounts[2],
    bets: ['yes', 'no'],
  });
  await addMarket({
    description: 'Will covid be gone in 2022?',
    category: 'World Events',
    betsCloseAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    readyForValidationAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    proposer: accounts[4],
    bets: ['yes', 'no'],
  });
  await addMarket({
    description:
      'How many albums will Johnson and Jonhson have released by 2022?',
    category: 'Arts',
    betsCloseAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    readyForValidationAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    proposer: accounts[4],
    bets: ['2', '3', '4'],
  });
  await addMarket({
    description: 'Is this real life?',
    category: 'Other',
    betsCloseAt: getTimeInUnixEpochSeconds(4 * 24 * 60 * 60),
    readyForValidationAt: getTimeInUnixEpochSeconds(4 * 24 * 60 * 60),
    proposer: accounts[4],
    bets: ['Yes', 'No'],
  });
  await addMarket({
    description:
      'Will Cristiano Ronaldo leave Manchester United before 20th September?',
    category: 'Sports',
    betsCloseAt: getTimeInUnixEpochSeconds(4 * 24 * 60 * 60),
    readyForValidationAt: getTimeInUnixEpochSeconds(4 * 24 * 60 * 60),
    proposer: accounts[6],
    bets: ['Yes', 'No'],
  });
  await addMarket({
    description: 'What will happen on September 19th?',
    category: 'World Events',
    betsCloseAt: getTimeInUnixEpochSeconds(4 * 24 * 60 * 60),
    readyForValidationAt: getTimeInUnixEpochSeconds(4 * 24 * 60 * 60),
    proposer: accounts[8],
    bets: ['Nothing', 'Pretty much nothing', 'Everything'],
  });
  await addMarket({
    description: 'Who will win the Qatar 2022 World Cup?',
    category: 'Sports',
    betsCloseAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    readyForValidationAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    proposer: accounts[0],
    bets: ['portugal', 'brazil', 'spain', 'england'],
  });
  await addMarket({
    description: 'Who will win the 2022 US elections?',
    category: 'Politics',
    betsCloseAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    readyForValidationAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    proposer: accounts[1],
    bets: ['democrats', 'republicans'],
  });
  await addMarket({
    description: 'Will ETH trade at $5k in 2022?',
    category: 'Economy',
    betsCloseAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    readyForValidationAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    proposer: accounts[2],
    bets: ['yes', 'no'],
  });
  await addMarket({
    description: 'Will we live in economic recession in 2023?',
    category: 'Economy',
    betsCloseAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    readyForValidationAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    proposer: accounts[3],
    bets: ['yes', 'no'],
  });
  await addMarket({
    description: 'How many hurricans will hit Florida in 2023?',
    category: 'World Events',
    betsCloseAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    readyForValidationAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    proposer: accounts[4],
    bets: ['10', '20', '30', '50'],
  });
  await addMarket({
    description:
      'Which month will the next album of Badjeka Badjouran be released?',
    category: 'Arts',
    betsCloseAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    readyForValidationAt: getTimeInUnixEpochSeconds(24 * 60 * 60),
    proposer: accounts[3],
    bets: ['May', 'June', 'August', 'December', 'January', 'March'],
  });
}

async function addMarket(market) {
  const contract = new ethers.Contract(address, daimAbi, provider);
  const bookieAddress = await contract.bookie();
  let bookie = new ethers.Contract(bookieAddress, bookieAbi, provider);
  const signerIndex = Math.floor(Math.random() * accounts.length);
  bookie = bookie.connect(provider.getSigner(signerIndex));

  const tx = await bookie[`propose(string,string,uint256,uint256)`](
    market.description,
    market.category,
    market.betsCloseAt,
    market.readyForValidationAt
  );

  const receipt = await tx.wait();
  const { args } = receipt.events[0];

  await placeBets(args[0], market.bets, market);
}

async function placeBets(marketId, bets) {
  const contract = new ethers.Contract(address, daimAbi, provider);
  const bookieAddress = await contract.bookie();
  let bookie = new ethers.Contract(bookieAddress, bookieAbi, provider);
  let numberOfBets = 50;

  while (numberOfBets > 0) {
    const bet = bets[Math.floor(Math.random() * bets.length)];
    const signer = provider.getSigner(
      Math.floor(Math.random() * accounts.length)
    );
    bookie = bookie.connect(signer);
    const stake = (Math.random() * Math.random() * 15).toFixed(10);

    console.log(
      `${await signer.getAddress()} PLACING "${bet}" with stake ${stake}`
    );

    try {
      const tx = await bookie.placeBet(marketId, bet, {
        value: ethers.utils.parseEther(stake),
      });
      tx.wait();
    } catch (error) {
      const revertData = error.error.error.data;
      const decodedError = bookie.interface.parseError(revertData);
      console.log('ERROR:', decodedError.name); // "seriouserror"
    }

    numberOfBets--;
  }
}

function getTimeInUnixEpochSeconds(extraSeconds) {
  return Math.round(new Date().getTime() / 1000) + extraSeconds;
}
