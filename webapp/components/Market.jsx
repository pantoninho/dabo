import Link from 'next/link';
import { useMarketBets } from '../smart-contracts/daim';
import stringToColor from 'string-to-color';

const Market = ({
  id,
  description,
  category,
  betsClosedAt,
  betPool,
  className,
}) => {
  const { bets, isLoading, error } = useMarketBets(id);

  if (error) return <div>failed to load</div>;
  if (isLoading) return <div>loading...</div>;

  const colorBars = bets.map(toColorBar);

  return (
    <div
      className={`rounded-lg border-2 border-zinc-800 p-4 dark:border-white ${className}`}
    >
      <div className="mb-8">
        <div className="mb-4 flex justify-between gap-12">
          <div>
            <div className="text-md">{category}</div>
            <h3 className="min-w-[300px] max-w-xs text-xl">{description}</h3>
          </div>
          <h3 className="text-xl">{betPool} ETH</h3>
        </div>

        <ColorBars>
          {colorBars.map((bet) => (
            <ColorBar
              key={bet.color}
              label={bet.label}
              color={bet.color}
              share={bet.stakeShare}
            />
          ))}
        </ColorBars>
      </div>
      <div className="flex items-center justify-end">
        <div className="flex flex-col gap-2">
          <ButtonLink href={`/markets/${encodeURIComponent(id)}`}>
            Place Bet
          </ButtonLink>
          <h5 className="text-xs">bets close at {betsClosedAt}</h5>
        </div>
      </div>
    </div>
  );
};

export default Market;

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

const toColorBar = (bet, i, bets) => {
  const totalStake = bets.reduce((acc, bet) => bet.stake.add(acc), 0);

  return {
    label: bet.description,
    color: stringToColor(bet.description),
    stakeShare: bet.stake.mul(100).div(totalStake).toNumber(),
  };
};

const ColorBars = ({ children }) => {
  return (
    <div className="border-1 flex h-2 justify-between overflow-hidden rounded-md border-zinc-800 dark:border-white">
      {children}
    </div>
  );
};

const ColorBar = ({ color, share }) => {
  return (
    <div className="flex" style={{ width: `${share}%` }}>
      <div className="w-full" style={{ backgroundColor: `${color}` }}></div>
    </div>
  );
};
