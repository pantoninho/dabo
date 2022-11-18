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

  return (
    <div
      className={`rounded-lg border-2 border-zinc-800 p-4 dark:border-white ${className}`}
    >
      <MarketHeader
        description={description}
        category={category}
        betPool={betPool}
      />
      <div className="mb-12"></div>
      <BetSharesBars bets={bets} />
      <div className="mb-8"></div>
      <MarketActions id={id} betsClosedAt={betsClosedAt} />
    </div>
  );
};

export default Market;

const MarketHeader = ({ category, description, betPool }) => {
  return (
    <div>
      <div className="mb-4 flex justify-between gap-12">
        <div className="flex-1">
          <div className="text-xs font-thin tracking-widest">
            {category.toUpperCase()}
          </div>
          <h3 className="text-xl">{description}</h3>
        </div>
        <div className="flex-0">
          <h3 className="text-center text-lg">{betPool} ETH</h3>
          <h3 className="text-center text-xs font-thin tracking-widest">
            BET POOL
          </h3>
        </div>
      </div>
    </div>
  );
};

const MarketActions = ({ id, betsClosedAt }) => {
  return (
    <div className="flex items-center justify-end">
      <div className="flex flex-col gap-2">
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

const BetSharesBars = ({ bets }) => {
  const colorBars = bets.map(toColorBar);
  return (
    <div>
      <ColorBars>
        {colorBars.map((bet) => (
          <ColorBar
            key={bet.label}
            label={bet.label}
            color={bet.color}
            share={bet.stakeShare}
          />
        ))}
      </ColorBars>
      <div className="mb-1"></div>
      <ColorBarCaptions>
        {colorBars.map((bet) => (
          <ColorBarCaption
            key={bet.label}
            label={bet.label}
            color={bet.color}
            share={bet.stakeShare}
          />
        ))}
      </ColorBarCaptions>
    </div>
  );
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
    <div className="flex flex-auto" style={{ width: `${share}%` }}>
      <div className="w-full" style={{ backgroundColor: `${color}` }}></div>
    </div>
  );
};

const ColorBarCaption = ({ label, color, share }) => {
  return (
    <div
      className="flex flex-auto justify-center gap-2 px-2"
      style={{ minWidth: `${share}%` }}
    >
      <div className="flex items-center justify-center">
        <div
          className="h-2 w-2 rounded-full"
          style={{ backgroundColor: color }}
        ></div>
      </div>
      <div className="">
        <span className="text-xs font-thin tracking-widest">
          {label.toUpperCase()}
        </span>
      </div>
    </div>
  );
};

const ColorBarCaptions = ({ children }) => {
  return <div className="flex flex-wrap">{children}</div>;
};

const toColorBar = (bet, i, bets) => {
  const totalStake = bets.reduce((acc, bet) => bet.stake.add(acc), 0);

  return {
    label: bet.description,
    color: stringToColor(bet.description),
    stakeShare: bet.stake.mul(100).div(totalStake).toNumber(),
  };
};
