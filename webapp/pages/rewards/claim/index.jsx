import { BigNumber, ethers } from 'ethers';
import Button from '../../../components/Button';
import { useActiveBets } from '../../../smart-contracts/daim';

const ClaimRewards = () => {
  const { pendingRewards, claimRewards, isLoading, error } = useActiveBets();

  if (error || isLoading) return <div />;

  const validatedBets = pendingRewards.length;
  const winningBets = pendingRewards.filter((r) => r.isWinner).length;
  const claiming = ethers.utils.formatEther(
    pendingRewards
      .filter((r) => r.isWinner)
      .reduce(
        (acc, bet) =>
          BigNumber.from(ethers.utils.parseEther(bet.rewards)).add(acc),
        0
      )
  );

  return (
    <div className="mt-8 flex justify-center">
      <div className="flex rounded-md border-2 border-zinc-800 p-8 dark:border-white">
        <div className="flex-col flex">
          <h2>Validated Vets: {validatedBets}</h2>
          <h2>Winning Bets: {winningBets}</h2>
          <h2>Claiming: {claiming} ETH</h2>
          <div className="mt-8"></div>

          <Button className="justify-self-center" onClick={claimRewards}>
            Claim Rewards
          </Button>
        </div>
      </div>
    </div>
  );
};

export default ClaimRewards;
