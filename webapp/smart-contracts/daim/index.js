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
        betsClosedAt,
        readyForValidationAt
      );
    },
    getActiveMarkets: async () => {
      const marketsAddress = await contract.bets();
      console.log(await library.getCode(marketsAddress));
      let markets = new ethers.Contract(marketsAddress, marketsAbi, library);

      return markets.getActiveProposals();
    },
    getNumberOfMarkets: async () => {
      const marketsAddress = await contract.bets();
      let markets = new ethers.Contract(marketsAddress, marketsAbi, library);

      return markets.getNumberOfProposals();
    },
  };
};

export { useDAIM };
