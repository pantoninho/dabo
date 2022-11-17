import { useWeb3React } from '@web3-react/core';
import { ethers } from 'ethers';
import daimAbi from './daim.abi.json';
import bookieAbi from './bookie.abi.json';
import marketsAbi from './daimarkets.abi.json';

const address = process.env.NEXT_PUBLIC_DAIM_ADDRESS;

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
    getActiveMarkets: async () => {
      const marketsAddress = await contract.bets();
      let markets = new ethers.Contract(marketsAddress, marketsAbi, library);

      const activeMarkets = await markets.getActiveProposals();
      return activeMarkets.map(processMarket);
    },
    getNumberOfMarkets: async () => {
      const marketsAddress = await contract.bets();
      let markets = new ethers.Contract(marketsAddress, marketsAbi, library);

      return markets.getNumberOfProposals();
    },
  };
};

export { useDAIM };

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
  return new Date(dateString).getTime() / 1000;
}
