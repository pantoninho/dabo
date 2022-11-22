import React from 'react';
import Button from '../../components/Button';
import { Form, Input } from '../../components/Form';
import { useFACT, useFACTx, useTreasury } from '../../smart-contracts/daim';

const TreasuryDashboard = () => {
  const { isPriceSet, factPrice, balance, initialize, stake } = useTreasury();
  const { totalSupply } = useFACT();
  const { totalSupply: factxSupply } = useFACTx();

  return (
    <div className="flex flex-col items-center">
      <div className="mt-4"></div>
      {isPriceSet ? (
        <div className="flex flex-wrap gap-16 px-16 py-8">
          <TreasuryStats
            factPrice={factPrice}
            balance={balance}
            issuedFacts={totalSupply}
            stakedFacts={factxSupply}
          />
          <BuyFactBox />
          <StakeFactBox onSubmit={stake} />
        </div>
      ) : (
        <InitTreasury initialize={initialize} />
      )}
    </div>
  );
};

export default TreasuryDashboard;

const TreasuryStats = ({ balance, issuedFacts, stakedFacts }) => {
  return (
    <div className="flex min-w-fit flex-1 flex-wrap items-center justify-center gap-16 rounded-md border-2 border-zinc-800 py-4 px-8 dark:border-white">
      <DashboardStat value={issuedFacts} label="Issued Facts" />
      <DashboardStat value={balance} label="ETH in Treasury" />
      <DashboardStat value={balance / issuedFacts} label="ETH/FACT" />
      <DashboardStat value={stakedFacts} label="Staked FACTs" />
    </div>
  );
};

const DashboardStat = ({ value, label }) => {
  return (
    <div className="flex flex-col items-center justify-center">
      <div className="text-6xl">{value}</div>
      <div>
        <h3 className="text-sm tracking-widest">{label.toUpperCase()}</h3>
      </div>
    </div>
  );
};

const InitTreasury = ({ initialize }) => {
  const [fact, setFact] = React.useState(1);
  const [eth, setEth] = React.useState(0.001);

  const pricePerFact = eth / fact;

  const initializeTreasury = (e) => {
    e.preventDefault();
    initialize({ fact, eth });
  };

  return (
    <div className="flex flex-col items-center justify-center gap-4 rounded-md border-2 border-zinc-800 py-4 px-8 dark:border-white">
      <div className="text-xl">Initialize Treasury</div>
      <div className="text-sm">
        Treasury may be initialized by buying FACT with ETH.
      </div>
      <div className="text-sm">This will set the initial FACT price.</div>
      <Form>
        <Input
          required
          min={1}
          labelClassName="w-20 text-center"
          type="number"
          label={'FACT'}
          value={fact}
          onChange={setFact}
        />
        <Input
          required
          labelClassName="w-20 text-center"
          type="number"
          label={'ETH'}
          value={eth}
          onChange={setEth}
        />
        <Button onClick={initializeTreasury} type="submit">
          Buy {fact} FACT for {eth} ETH
        </Button>
      </Form>
      <h2 className="text-sm">
        Setting FACT price at ~{pricePerFact || 0} ETH
      </h2>
    </div>
  );
};

const BuyFactBox = () => {
  const [fact, setFact] = React.useState(0);
  const [eth, setEth] = React.useState(0);

  const { balance, trade, sell } = useTreasury();
  const { totalSupply } = useFACT();

  const price = balance / totalSupply;

  const setFactAndUpdate = (value) => {
    value = parseFloat(value);
    setFact(value);
    setEth(value * price);
  };

  const setEthAndUpdate = (value) => {
    value = parseFloat(value);
    setEth(value);
    setFact(value / price);
  };

  const onBuy = (e) => {
    e.preventDefault();
    trade(eth);
  };

  const onSell = (e) => {
    e.preventDefault();
    sell(fact);
  };

  return (
    <div className="flex flex-1 rounded-md border-2 border-zinc-800 dark:border-white">
      <Form>
        <Input
          type="number"
          label="FACT"
          labelClassName="w-20 text-center"
          value={fact}
          min={0}
          onChange={setFactAndUpdate}
        />
        <Input
          type="number"
          label="ETH"
          labelClassName="w-20 text-center"
          value={eth}
          min={0}
          onChange={setEthAndUpdate}
        />
        <div className="flex justify-between">
          <Button type="submit" onClick={onBuy}>
            Buy FACT
          </Button>
          <Button type="submit" onClick={onSell}>
            Sell FACT
          </Button>
        </div>
        <div className="self-end text-sm font-thin">
          <h3>CURRENT PRICE: {price} ETH/FACT</h3>
        </div>
      </Form>
    </div>
  );
};

const StakeFactBox = () => {
  const [fact, setFact] = React.useState(0);
  const { allowance, approveForStaking } = useFACT();
  const { stake, unstake } = useTreasury();

  const onStake = (e) => {
    e.preventDefault();
    stake(fact);
  };

  const onUnstake = (e) => {
    e.preventDefault();
    unstake(fact);
  };

  const onApprove = (e) => {
    e.preventDefault();
    approveForStaking();
  };

  return (
    <div className="flex flex-1 flex-col justify-between rounded-md border-2 border-zinc-800 dark:border-white">
      <Form>
        <Input
          type="number"
          label="FACT"
          labelClassName="w-20 text-center"
          value={fact}
          min={0}
          onChange={setFact}
        />
      </Form>
      {allowance == 0 ? (
        <div className="flex justify-between gap-4 p-2">
          <Button type="submit" className="flex-1" onClick={onApprove}>
            Approve FACT
          </Button>
        </div>
      ) : (
        <div className="flex justify-between gap-4 p-2">
          <Button type="submit" onClick={onStake}>
            Stake FACT
          </Button>
          <Button type="submit" onClick={onUnstake}>
            Unstake FACT
          </Button>
        </div>
      )}
    </div>
  );
};
