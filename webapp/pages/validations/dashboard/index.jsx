import {
  useMarket,
  useMarketBets,
  usePendingValidationsForSelf,
} from '../../../smart-contracts/daim';
import Market from '../../../components/Market';
import Masonry, { ResponsiveMasonry } from 'react-responsive-masonry';
import Button from '../../../components/Button';
import React from 'react';
import { Form } from '../../../components/Form';

const ValidationsDashboard = () => {
  const { pendingValidations, isLoading, error } =
    usePendingValidationsForSelf();
  console.log({ error });

  if (error || isLoading) return <div></div>;

  return (
    <ResponsiveMasonry
      className="p-4"
      columnsCountBreakPoints={{ 0: 1, 700: 2, 1200: 3 }}
    >
      <Masonry gutter="1em">
        {pendingValidations.map((market) => {
          return (
            <Market
              id={market.id}
              key={market.id}
              hideShares={true}
              description={market.description}
              betsClosedAt={market.betsClosedAt}
              betPool={market.betPool}
              category={market.category}
              actions={
                <MarketActions
                  id={market.id}
                  readyForValidationAt={market.readyForValidationAt}
                />
              }
            />
          );
        })}
      </Masonry>
    </ResponsiveMasonry>
  );
};

export default ValidationsDashboard;

const MarketActions = ({ id }) => {
  const { bets, isLoading, error } = useMarketBets(id);
  const { validate } = useMarket(id);

  if (isLoading || error) return <div />;

  const onValidate = (betIds) => {
    validate(betIds);
  };

  return (
    <div className="flex-col flex">
      <BetChoices bets={bets} onValidate={onValidate} />
      <div className="mb-8"></div>
      <Button className="border-red-500 dark:border-red-500">
        Mark as Unverifiable
      </Button>
    </div>
  );
};

const BetChoices = ({ bets, onValidate }) => {
  const [selectedBets, setSelectedBets] = React.useState({});

  const isPicked = (id) => !!selectedBets[id];
  const toggle = (id) => {
    const newState = !selectedBets[id];
    setSelectedBets({ ...selectedBets, [id]: newState });
  };

  const onButtonClick = (e) => {
    e.preventDefault();
    onValidate(
      Object.keys(selectedBets).filter((betId) => selectedBets[betId])
    );
  };

  return (
    <Form>
      {bets.map((bet) => (
        <BetChoice
          key={bet.description}
          description={bet.description}
          isPicked={isPicked(bet.id)}
          onChange={() => toggle(bet.id)}
        />
      ))}
      <Button type="submit" onClick={onButtonClick}>
        Validate
      </Button>
    </Form>
  );
};

const BetChoice = ({ description, onChange, isPicked }) => {
  const onClick = (e) => {
    e.preventDefault();
    onChange(!isPicked);
  };

  return (
    <div>
      <input
        type="checkbox"
        id={`betchoice-${description}`}
        className="peer hidden"
        onChange={onChange}
        value={isPicked}
      />
      <label htmlFor={`betchoice-${description}`} className="flex flex-1">
        <Button
          className={`flex flex-1 ${
            isPicked
              ? 'bg-zinc-800 text-white dark:bg-white dark:text-zinc-800'
              : ''
          }`}
          onClick={onClick}
        >
          {description}
        </Button>
      </label>
    </div>
  );
};
