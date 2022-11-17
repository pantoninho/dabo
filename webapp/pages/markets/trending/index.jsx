import useSWR from 'swr';

import { useDAIM } from '../../../smart-contracts/daim';

const TrendingMarkets = () => {
  const daim = useDAIM();
  const fetcher = daim.getActiveMarkets;
  const { data, error } = useSWR('getActiveMarkets', fetcher);

  if (error) return <div>failed to load</div>;
  if (!data) return <div>loading...</div>;

  return (
    <div className="flex flex-wrap gap-4 p-4">
      {data.map((market) => {
        return (
          <Market
            id={market.id._hex}
            key={market.id._hex}
            creator={market.creator}
            description={market.description}
          />
        );
      })}
    </div>
  );
};

export default TrendingMarkets;

const Market = ({ id, description, creator, betsClosedAt }) => {
  return (
    <div className="rounded-lg border-2 border-zinc-800 p-2 dark:border-white">
      <h3>creator: {creator}</h3>
      <br />
      <h3>{description}</h3>
    </div>
  );
};
