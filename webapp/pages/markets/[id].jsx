import { useRouter } from 'next/router';
import CreatableSelect from 'react-select/creatable';

import { useMarket, useMarketBets } from '../../smart-contracts/daim';
import Button from '../../components/Button';
import { Form, Input } from '../../components/Form';
import React from 'react';
import Market from '../../components/Market';

const MarketDetails = () => {
  const router = useRouter();
  const { id } = router.query;

  const { market, isLoading, error, placeBet } = useMarket(id);

  if (error) return <div>failed to load</div>;
  if (isLoading) return <div>loading...</div>;

  return (
    <div className="flex justify-center p-8">
      <Market
        id={market.id}
        key={market.id}
        description={market.description}
        betsClosedAt={market.betsClosedAt}
        betPool={market.betPool}
        category={market.category}
        actions={<MarketBets id={id} onSubmit={placeBet} />}
      />
    </div>
  );
};

export default MarketDetails;

const MarketBets = ({ id, onSubmit }) => {
  const [bet, setBet] = React.useState(null);
  const [value, setValue] = React.useState(0);
  const { bets, isLoading, error } = useMarketBets(id);

  if (error || isLoading) return <div />;

  const onButtonClick = (e) => {
    e.preventDefault();
    onSubmit({ bet: bet.value, value });
  };

  return (
    <ul>
      <li>
        <Form>
          <Input
            type="number"
            label="Stake"
            labelClassName="w-20 text-center"
            value={value}
            onChange={setValue}
          />

          <div className="flex items-center rounded-md bg-zinc-800 dark:bg-white">
            <label className="w-20 text-center text-white dark:text-zinc-800">
              Bet
            </label>
            <CreatableSelect
              className="text-inc-800 flex-1 rounded-md border-2 border-zinc-800 bg-white dark:border-white dark:bg-zinc-800"
              onChange={setBet}
              value={bet}
              styles={{
                menuList: (baseStyles) => ({
                  ...baseStyles,
                  color: 'black',
                }),
              }}
              options={bets.map((bet) => ({
                value: bet.id,
                label: bet.description,
              }))}
            />
          </div>

          <Button onClick={onButtonClick}>New Bet</Button>
        </Form>
      </li>
    </ul>
  );
};
