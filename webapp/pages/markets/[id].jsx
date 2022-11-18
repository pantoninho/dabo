import { useRouter } from 'next/router';

import { useDAIM, useMarket } from '../../smart-contracts/daim';
import Button from '../../components/Button';
import { Form, Input } from '../../components/Form';
import React from 'react';

const MarketDetails = () => {
  const daim = useDAIM();
  const router = useRouter();
  const { id } = router.query;

  const { market, isLoading, error } = useMarket(id);

  if (error) return <div>failed to load</div>;
  if (isLoading) return <div>loading...</div>;

  const placeBet = ({ bet, value }) => {
    daim.placeBet({ market: id, bet, value });
  };

  return (
    <div>
      <MarketDetailsHeader description={market.description} />
      <MarketBets bets={market.bets} onSubmit={placeBet} />
    </div>
  );
};

export default MarketDetails;

const MarketDetailsHeader = ({ description }) => {
  return (
    <div>
      <h1>{description}</h1>
    </div>
  );
};

const MarketBets = ({ onSubmit }) => {
  const [bet, setBet] = React.useState('');
  const [value, setValue] = React.useState(0);

  const onButtonClick = (e) => {
    e.preventDefault();
    onSubmit({ bet, value });
  };

  return (
    <ul>
      <li>
        <Form>
          <Input type="text" label="Bet" value={bet} onChange={setBet} />
          <Input
            type="number"
            label="Stake"
            value={value}
            onChange={setValue}
          />

          <Button onClick={onButtonClick}>New Bet</Button>
        </Form>
      </li>
    </ul>
  );
};
