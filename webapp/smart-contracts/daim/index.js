import { useWeb3React } from '@web3-react/core';
import { ethers } from 'ethers';
import daimAbi from './daim.abi.json';
import bookieAbi from './bookie.abi.json';
import marketsAbi from './daimarkets.abi.json';
import treasuryAbi from './treasury.abi.json';
import factAbi from './fact.abi.json';
import factxAbi from './factx.abi.json';
import useSWR from 'swr';

const address = process.env.NEXT_PUBLIC_DAIM_ADDRESS;

function useMarket(id) {
  const { library } = useWeb3React();
  const bookie = useBookie();
  const contract = new ethers.Contract(address, daimAbi, library);

  const fetcher = (id) => async () => {
    const marketsAddress = await contract.bets();
    const markets = new ethers.Contract(marketsAddress, marketsAbi, library);
    const market = await markets.getProposal(id);

    return market;
  };

  const { data, error } = useSWR(`getMarket(${id})`, fetcher(id));

  return {
    market: data && processMarket(data),
    isLoading: !error && !data,
    error: error,
    placeBet: ({ bet, value }) => bookie.placeBet({ id, bet, value }),
  };
}

function useActiveMarkets() {
  const { library } = useWeb3React();
  const contract = new ethers.Contract(address, daimAbi, library);

  const fetcher = async () => {
    const marketsAddress = await contract.bets();
    const markets = new ethers.Contract(marketsAddress, marketsAbi, library);
    const activeMarkets = await markets.getActiveProposals();

    return activeMarkets;
  };

  const { data, error } = useSWR(`getActiveMarkets()`, fetcher);

  return {
    activeMarkets: data && data.map(processMarket),
    isLoading: !error && !data,
    error: error,
  };
}

function useMarketBets(marketId) {
  const { library } = useWeb3React();
  const contract = new ethers.Contract(address, daimAbi, library);

  const fetcher = (marketId) => async () => {
    const marketsAddress = await contract.bets();
    const markets = new ethers.Contract(marketsAddress, marketsAbi, library);
    const market = await markets.getProposal(marketId);

    const bets = await Promise.all(
      market.bets.map(async (betId) => {
        const [description, stake] = await Promise.all([
          markets.getBetDescription(betId),
          markets.getStakeOnBet(betId),
        ]);
        return { description, stake };
      })
    );

    return bets;
  };

  const { data, error } = useSWR(
    `getMarketBets(${marketId})`,
    fetcher(marketId)
  );

  return {
    bets: data,
    isLoading: !error && !data,
    error: error,
  };
}

function useFACT() {
  const { library } = useWeb3React();
  const contract = new ethers.Contract(address, daimAbi, library);

  const fetcher = async () => {
    const factAddress = await contract.fact();
    const fact = new ethers.Contract(factAddress, factAbi, library);
    const factxAddress = await contract.factx();
    const totalSupply = await fact.totalSupply();

    const address = await library.getSigner().getAddress();
    const allowance = await fact.allowance(address, factxAddress);

    return {
      totalSupply: ethers.utils.formatEther(totalSupply),
      allowance: ethers.utils.formatEther(allowance),
    };
  };

  const { data, error } = useSWR(`getFactInfo()`, fetcher);

  return {
    totalSupply: data && data.totalSupply,
    allowance: data && data.allowance,
    isLoading: !error && !data,
    error: error,
    approveForStaking: async () => {
      const factAddress = await contract.fact();
      const factxAddress = await contract.factx();
      let fact = new ethers.Contract(factAddress, factAbi, library);
      const signer = library.getSigner();
      fact = fact.connect(signer);

      return fact.approve(factxAddress, ethers.constants.MaxUint256);
    },
  };
}

function useFACTx() {
  const { library } = useWeb3React();
  const contract = new ethers.Contract(address, daimAbi, library);
  const fetcher = async () => {
    const factxAddress = await contract.factx();
    let factx = new ethers.Contract(factxAddress, factxAbi, library);
    const totalSupply = await factx.totalSupply();

    return ethers.utils.formatEther(totalSupply);
  };

  const { data, error } = useSWR(`getFACTxInfo()`, fetcher);

  return {
    totalSupply: data,
    isLoading: !error && !data,
    error,
  };
}

function useTreasury() {
  const { library } = useWeb3React();
  const contract = new ethers.Contract(address, daimAbi, library);

  const fetcher = async () => {
    const treasuryAddress = await contract.treasury();
    const treasury = new ethers.Contract(treasuryAddress, treasuryAbi, library);
    const isPriceSet = await treasury.isPriceSet();
    const balance = await library.getBalance(treasury.address);

    return {
      isPriceSet,
      balance: ethers.utils.formatEther(balance),
    };
  };

  const { data, error } = useSWR(`getTreasuryInfo()`, fetcher);

  return {
    isPriceSet: data && data.isPriceSet,
    factPrice: data && data.factPrice,
    balance: data && data.balance,
    isLoading: !error && !data,
    error: error,
    trade: async (eth) => {
      const treasuryAddress = await contract.treasury();
      const signer = library.getSigner();

      const tx = await signer.sendTransaction({
        to: treasuryAddress,
        value: ethers.utils.parseEther(eth.toString()),
      });

      return tx;
    },
    sell: async (fact) => {
      const treasuryAddress = await contract.treasury();
      let treasury = new ethers.Contract(treasuryAddress, treasuryAbi, library);
      treasury = treasury.connect(library.getSigner());

      await treasury.withdraw(ethers.utils.parseEther(fact.toString()));
    },
    initialize: async ({ fact, eth }) => {
      const treasuryAddress = await contract.treasury();
      let treasury = new ethers.Contract(treasuryAddress, treasuryAbi, library);
      treasury = treasury.connect(library.getSigner());

      await treasury.initialTrade(ethers.utils.parseEther(fact), {
        value: ethers.utils.parseEther(eth),
      });
    },
    stake: async (fact) => {
      const factxAddress = await contract.factx();
      let factx = new ethers.Contract(factxAddress, factxAbi, library);
      factx = factx.connect(library.getSigner());
      const address = await library.getSigner().getAddress();

      console.log('in ether:', ethers.utils.parseEther(fact.toString()));

      await factx.deposit(ethers.utils.parseEther(fact.toString()), address);
    },
    unstake: async (fact) => {
      const factxAddress = await contract.factx();
      let factx = new ethers.Contract(factxAddress, factxAbi, library);
      factx = factx.connect(library.getSigner());
      const address = await library.getSigner().getAddress();

      await factx.redeem(
        ethers.utils.parseEther(fact.toString()),
        address,
        address
      );
    },
  };
}

function useBookie() {
  const { library } = useWeb3React();
  const contract = new ethers.Contract(address, daimAbi, library);

  const getSignedBookie = async () => {
    const bookieAddress = await contract.bookie();
    const bookie = new ethers.Contract(bookieAddress, bookieAbi, library);
    return bookie.connect(library.getSigner());
  };

  return {
    propose: async ({
      description,
      category,
      betsClosedAt,
      readyForValidationAt,
    }) => {
      const bookie = getSignedBookie();
      await bookie[`propose(string,string,uint256,uint256)`](
        description,
        category,
        localizedStringToTimestamp(betsClosedAt),
        localizedStringToTimestamp(readyForValidationAt)
      );
    },
    placeBet: async ({ market, bet, value }) => {
      const bookie = getSignedBookie();

      return bookie.placeBet(market, bet, {
        value: ethers.utils.parseEther(value),
      });
    },
  };
}

export {
  useActiveMarkets,
  useMarket,
  useMarketBets,
  useTreasury,
  useBookie,
  useFACT,
  useFACTx,
};

function processMarket(market) {
  return {
    ...market,
    id: market.id.toHexString(),
    betsClosedAt: timestampToLocalizedString(market.betsClosedAt),
    readyForValidationAt: timestampToLocalizedString(
      market.readyForValidationAt
    ),
    betPool: ethers.utils.formatEther(market.betPool),
  };
}

function timestampToLocalizedString(timestamp) {
  return new Date(timestamp * 1000).toLocaleString();
}

function localizedStringToTimestamp(dateString) {
  return Math.round(new Date(dateString).getTime() / 1000);
}
