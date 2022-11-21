import { useActiveMarkets } from '../../../smart-contracts/daim';
import Market from '../../../components/Market';
import Masonry, { ResponsiveMasonry } from 'react-responsive-masonry';
import Link from 'next/link';

const TrendingMarkets = () => {
  const { openMarkets, isLoading, error } = useActiveMarkets();

  if (error) return <div>failed to load</div>;
  if (isLoading) return <div>loading...</div>;

  return (
    <ResponsiveMasonry
      className="p-4"
      columnsCountBreakPoints={{ 0: 1, 700: 2, 1200: 3 }}
    >
      <Masonry gutter="1em">
        {openMarkets.map((market) => {
          return (
            <Market
              id={market.id}
              key={market.id}
              description={market.description}
              betsClosedAt={market.betsClosedAt}
              betPool={market.betPool}
              category={market.category}
              actions={
                <MarketActions
                  id={market.id}
                  betsClosedAt={market.betsClosedAt}
                />
              }
            />
          );
        })}
      </Masonry>
    </ResponsiveMasonry>
  );
};

export default TrendingMarkets;

const MarketActions = ({ id, betsClosedAt }) => {
  return (
    <div className="flex items-center justify-end">
      <div className="flex-col flex gap-2">
        <ButtonLink href={`/markets/${encodeURIComponent(id)}`}>
          Place Bet
        </ButtonLink>
        <h5 className="text-xs">bets close at {betsClosedAt}</h5>
      </div>
    </div>
  );
};

const ButtonLink = ({ children, href, className }) => {
  return (
    <Link
      href={href}
      className={`rounded-lg border-2 border-zinc-900 px-2 py-1 text-center hover:bg-zinc-800 hover:text-white dark:border-white dark:hover:bg-white dark:hover:text-zinc-900 ${className}`}
    >
      {children}
    </Link>
  );
};
