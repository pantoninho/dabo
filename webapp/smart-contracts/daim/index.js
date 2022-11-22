import { useWeb3React } from '@web3-react/core';
import { BigNumber, ethers } from 'ethers';
import daimAbi from './daim.abi.json';
import bookieAbi from './bookie.abi.json';
import marketsAbi from './daimarkets.abi.json';
import treasuryAbi from './treasury.abi.json';
import factAbi from './fact.abi.json';
import factxAbi from './factx.abi.json';
import officeAbi from './office.abi.json';
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

    return processMarket(market);
  };

  const { data, error } = useSWR(`getMarket(${id})`, fetcher(id));

  return {
    market: data,
    isLoading: !error && !data,
    error: error,
    placeBet: async ({ bet, value }) => bookie.placeBet({ id, bet, value }),
    validate: async (betIds) => {
      const officeAddress = await contract.office();
      let office = new ethers.Contract(officeAddress, officeAbi, library);
      office = office.connect(library.getSigner());
      await office.validate(betIds.map((id) => BigNumber.from(id)));
    },
  };
}

function useActiveMarkets() {
  const { library } = useWeb3React();
  const contract = new ethers.Contract(address, daimAbi, library);

  const fetcher = async () => {
    const marketsAddress = await contract.bets();
    const markets = new ethers.Contract(marketsAddress, marketsAbi, library);
    const activeMarkets = await markets.getActiveProposals();

    return {
      openMarkets: activeMarkets.filter(isOpen).map(processMarket),
      validatingMarkets: activeMarkets
        .filter(isInValidationProcess)
        .map(processMarket),
    };
  };

  const { data, error } = useSWR(`getActiveMarkets()`, fetcher);

  return {
    openMarkets: data && data.openMarkets,
    validatingMarkets: data && data.validatingMarkets,
    isLoading: !error && !data,
    error: error,
  };
}

function useMarketsReadyForValidation() {
  const { library } = useWeb3React();
  const contract = new ethers.Contract(address, daimAbi, library);

  const fetcher = async () => {
    const marketsAddress = await contract.bets();
    const markets = new ethers.Contract(marketsAddress, marketsAbi, library);
    const marketsForValidation = await markets.getProposalsToBeValidated();

    return marketsForValidation;
  };

  const { data, error } = useSWR(`getMarketsReadyForValidation()`, fetcher);

  return {
    marketsForValidation: data,
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
        return { id: betId.toHexString(), description, stake };
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
      const bookie = await getSignedBookie();
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

function useActiveBets() {
  const { library } = useWeb3React();
  const contract = new ethers.Contract(address, daimAbi, library);

  const fetcher = async () => {
    const bookieAddress = await contract.bookie();
    let bookie = new ethers.Contract(bookieAddress, bookieAbi, library);
    const marketsAddress = await contract.bets();
    let markets = new ethers.Contract(marketsAddress, marketsAbi, library);
    const officeAddress = await contract.office();
    const office = new ethers.Contract(officeAddress, officeAbi, library);

    bookie = bookie.connect(library.getSigner());
    const address = await library.getSigner().getAddress();
    let activeBets = await bookie.getActiveBets();
    activeBets = await Promise.all(
      activeBets.map(async (betId) => {
        const market = await markets.getProposalByBetId(betId);
        const process = await office.getProcessById(market.id);
        const description = await markets.getBetDescription(betId);
        const stake = await markets.getPlayerStakeOnBet(address, betId);
        const isWinner = await office.isWinner(betId);
        const rewards = await markets.calculatePlayerRewards(address, betId);

        return {
          market: processMarket(market),
          description,
          stake: ethers.utils.formatEther(stake.toString()),
          isWinner,
          rewards: ethers.utils.formatEther(rewards.toString()),
          process,
        };
      })
    );

    return {
      activeBets,
      pendingRewards: activeBets.filter((bet) => bet.process.validated),
    };
  };

  const { data, error } = useSWR(`getActiveBets()`, fetcher);

  return {
    activeBets: data && data.activeBets,
    pendingRewards: data && data.pendingRewards,
    isLoading: !error && !data,
    error,
    claimRewards: async () => {
      const bookieAddress = await contract.bookie();
      let bookie = new ethers.Contract(bookieAddress, bookieAbi, library);
      bookie = bookie.connect(library.getSigner());

      return bookie.claimRewards();
    },
  };
}

function useValidationProcess(id) {
  const { library } = useWeb3React();
  const contract = new ethers.Contract(address, daimAbi, library);

  const fetcher = async () => {
    const officeAddress = await contract.office();
    const office = new ethers.Contract(officeAddress, officeAbi, library);

    const process = await office.getProcessById(id);
    const isActive = await office.isProcessActive(id);
    return processValidationProcess({ ...process, isActive });
  };

  const { data, error } = useSWR(`getValidationProcess(${id})`, fetcher);

  return {
    process: data,
    isLoading: !error && !data,
    error,
    startValidationRound: async () => {
      const officeAddress = await contract.office();
      let office = new ethers.Contract(officeAddress, officeAbi, library);
      office = office.connect(library.getSigner());

      return office.startValidationRound(id);
    },
  };
}

function usePendingValidationsForSelf() {
  const { library } = useWeb3React();
  const contract = new ethers.Contract(address, daimAbi, library);

  const fetcher = async () => {
    const officeAddress = await contract.office();
    let office = new ethers.Contract(officeAddress, officeAbi, library);
    office = office.connect(library.getSigner());
    try {
      const pendingProposalIds = await office.getPendingProposalValidations();

      const pendingProposals = await Promise.all(
        pendingProposalIds
          .filter((id) => !id.eq(0))
          .map(async (id) => {
            const marketsAddress = await contract.bets();
            const markets = new ethers.Contract(
              marketsAddress,
              marketsAbi,
              library
            );
            const market = await markets.getProposal(id);

            return processMarket(market);
          })
      );

      return pendingProposals;
    } catch (error) {
      console.log('error:', error);
      return [];
    }
  };

  const { data, error } = useSWR(`getPendingValidations()`, fetcher);

  return {
    pendingValidations: data,
    isLoading: !error && !data,
    error,
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
  useMarketsReadyForValidation,
  useValidationProcess,
  usePendingValidationsForSelf,
  useActiveBets,
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

function processValidationProcess(validationProcess) {
  return {
    ...validationProcess,
    consecutiveConsensus: validationProcess.consecutiveConsensus.toNumber(),
    currentRound: validationProcess.currentRound.toNumber(),
  };
}

export function timestampToLocalizedString(timestamp) {
  return new Date(timestamp * 1000).toLocaleString();
}

export function localizedStringToTimestamp(dateString) {
  return Math.round(new Date(dateString).getTime() / 1000);
}

function isOpen(market) {
  return market.betsClosedAt > new Date().getTime() / 1000;
}

function isInValidationProcess(market) {
  return market.readyForValidationAt < new Date().getTime() / 1000;
}
