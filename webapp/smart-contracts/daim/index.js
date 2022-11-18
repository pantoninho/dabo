import { useWeb3React } from '@web3-react/core';
import { ethers } from 'ethers';
import daimAbi from './daim.abi.json';
import bookieAbi from './bookie.abi.json';
import marketsAbi from './daimarkets.abi.json';
import useSWR from 'swr';

const address = process.env.NEXT_PUBLIC_DAIM_ADDRESS;

function useMarket(id) {
  const { library } = useWeb3React();
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

const useDAIM = () => {
  const { library } = useWeb3React();
  const contract = new ethers.Contract(address, daimAbi, library);

  return {
    propose: async ({ description, betsClosedAt, readyForValidationAt }) => {
      const bookieAddress = await contract.bookie();
      let bookie = new ethers.Contract(bookieAddress, bookieAbi, library);
      bookie = bookie.connect(library.getSigner());

      await bookie[`propose(string,uint256,uint256)`](
        description,
        localizedStringToTimestamp(betsClosedAt),
        localizedStringToTimestamp(readyForValidationAt)
      );
    },
    placeBet: async ({ market, bet, value }) => {
      const bookieAddress = await contract.bookie();
      let bookie = new ethers.Contract(bookieAddress, bookieAbi, library);
      bookie = bookie.connect(library.getSigner());

      return bookie.placeBet(market, bet, {
        value: ethers.utils.parseEther(value),
      });
    },
  };
};

export { useDAIM, useActiveMarkets, useMarket, useMarketBets };

function processMarket(market) {
  return {
    ...market,
    id: market.id.toHexString(),
    betsClosedAt: timestampToLocalizedString(market.betsClosedAt),
    readyForValidationAt: timestampToLocalizedString(
      market.readyForValidationAt
    ),
  };
}

function timestampToLocalizedString(timestamp) {
  return new Date(timestamp * 1000).toLocaleString();
}

function localizedStringToTimestamp(dateString) {
  return Math.round(new Date(dateString).getTime() / 1000);
}
