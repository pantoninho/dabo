import { useActiveMarkets } from '../../../smart-contracts/daim';
import Market from '../../../components/Market';

const TrendingMarkets = () => {
  const { activeMarkets, isLoading, error } = useActiveMarkets();
  console.log(activeMarkets);

  if (error) return <div>failed to load</div>;
  if (isLoading) return <div>loading...</div>;

  return (
    <div className="flex flex-wrap gap-4 p-4">
      {activeMarkets.map((market) => {
        return (
          <Market
            id={market.id}
            key={market.id}
            className="flex-1"
            description={market.description}
            betsClosedAt={market.betsClosedAt}
            betPool={market.betPool}
            category={market.category}
          />
        );
      })}
    </div>
  );
};

export default TrendingMarkets;
