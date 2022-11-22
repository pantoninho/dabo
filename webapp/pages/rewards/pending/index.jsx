import Masonry, { ResponsiveMasonry } from 'react-responsive-masonry';
import Button from '../../../components/Button';
import ButtonLink from '../../../components/ButtonLink';
import Market from '../../../components/Market';
import { useActiveBets } from '../../../smart-contracts/daim';

const PendingBets = () => {
  const { pendingRewards, isLoading, error } = useActiveBets();

  if (isLoading || error) return <div />;

  return (
    <ResponsiveMasonry
      className="p-4"
      columnsCountBreakPoints={{ 0: 1, 700: 2, 1200: 3 }}
    >
      <Masonry gutter="1em">
        {pendingRewards.map((bet) => {
          const { market } = bet;
          return (
            <Market
              key={bet.id}
              className={
                bet.isWinner ? 'border-green-500 dark:border-green-500' : ''
              }
              betPool={market.betPool}
              category={market.category}
              description={market.description}
              hideShares={true}
              id={market.id}
              actions={
                <MarketActions
                  description={bet.description}
                  isWinner={bet.isWinner}
                  stake={bet.stake}
                  rewards={bet.rewards}
                />
              }
            />
          );
        })}
      </Masonry>
    </ResponsiveMasonry>
  );
};

export default PendingBets;

const MarketActions = ({ description, isWinner, stake, rewards }) => {
  return (
    <div className="flex items-center justify-between">
      <div className="flex-col flex">
        <h2>Bet: {description}</h2>
        <h2>Stake: {stake} ETH</h2>
        <h2>Rewards: {rewards} ETH</h2>
      </div>
      {isWinner ? (
        <ButtonLink href="/rewards/claim">Claim Rewards</ButtonLink>
      ) : (
        <Button disabled={true}>No rewards to claim</Button>
      )}
    </div>
  );
};
