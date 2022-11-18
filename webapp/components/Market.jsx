import Link from 'next/link';
import { useMarketBets } from '../smart-contracts/daim';
import stringToColor from 'string-to-color';

const Market = ({ id, description, betsClosedAt }) => {
  const { bets, isLoading, error } = useMarketBets(id);

  if (error) return <div>failed to load</div>;
  if (isLoading) return <div>loading...</div>;

  const colorBars = bets.map(toColorBar);

  return (
    <div className="rounded-lg border-2 border-zinc-800 p-2 dark:border-white">
      <h1>{id}</h1>
      <h3>{description}</h3>
      <h3>bets close at: {betsClosedAt}</h3>

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

      <div className="mt-4 flex justify-end">
        <ButtonLink href={`/markets/${encodeURIComponent(id)}`}>
          Place Bet
        </ButtonLink>
      </div>
    </div>
  );
};

export default Market;

const ButtonLink = ({ children, href, className }) => {
  return (
    <Link
      href={href}
      className={`rounded-lg border-2 border-zinc-900 px-2 py-1 hover:bg-zinc-800 hover:text-white dark:border-white dark:hover:bg-white dark:hover:text-zinc-900 ${className}`}
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
    <div className="border-1 flex justify-between overflow-hidden rounded-md border-zinc-800 dark:border-white">
      {children}
    </div>
  );
};

const ColorBar = ({ color, share }) => {
  return (
    <div className="flex" style={{ width: `${share}%` }}>
      <div className="h-4 w-full" style={{ backgroundColor: `${color}` }}></div>
    </div>
  );
};
