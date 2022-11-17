import useSWR from 'swr';

import { useDAIM } from '../../../smart-contracts/daim';
import Market from '../../../components/Market';

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
            key={market.id}
            description={market.description}
            betsClosedAt={market.betsClosedAt}
          />
        );
      })}
    </div>
  );
};

export default TrendingMarkets;
