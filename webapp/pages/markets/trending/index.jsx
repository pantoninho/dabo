import { useActiveMarkets } from '../../../smart-contracts/daim';
import Market from '../../../components/Market';
import Masonry, { ResponsiveMasonry } from 'react-responsive-masonry';

const TrendingMarkets = () => {
  const { activeMarkets, isLoading, error } = useActiveMarkets();

  if (error) return <div>failed to load</div>;
  if (isLoading) return <div>loading...</div>;

  return (
    <ResponsiveMasonry
      className="p-4"
      columnsCountBreakPoints={{ 0: 1, 700: 2, 1200: 3 }}
    >
      <Masonry gutter="1em">
        {activeMarkets.map((market) => {
          return (
            <Market
              id={market.id}
              key={market.id}
              description={market.description}
              betsClosedAt={market.betsClosedAt}
              betPool={market.betPool}
              category={market.category}
            />
          );
        })}
      </Masonry>
    </ResponsiveMasonry>
  );
};

export default TrendingMarkets;
