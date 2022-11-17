import React from 'react';
import Button from '../../../components/Button';
import { useDAIM } from '../../../smart-contracts/daim';

const NewMarket = () => {
  const daim = useDAIM();

  const onSubmit = async ({
    description,
    betsClosedAt,
    readyForValidationAt,
  }) => {
    await daim.propose({
      description,
      betsClosedAt: new Date(betsClosedAt).getTime() / 1000,
      readyForValidationAt: new Date(readyForValidationAt).getTime() / 1000,
    });
  };

  return <NewMarketForm onSubmit={onSubmit} />;
};

export default NewMarket;

const NewMarketForm = ({ onSubmit }) => {
  const [description, setDescription] = React.useState('');
  const [betsClosedAt, setBetsClosedAt] = React.useState('');
  const [readyForValidationAt, setReadyForValidationAt] = React.useState('');

  const onButtonClick = (e) => {
    e.preventDefault();
    onSubmit({ description, betsClosedAt, readyForValidationAt });
  };

  return (
    <Form>
      <Input
        type="text"
        name="description"
        label="Description"
        onChange={setDescription}
        value={description}
      />
      <Input
        type="datetime-local"
        name="betsClosedAt"
        label="Close Bets At"
        onChange={setBetsClosedAt}
        value={betsClosedAt}
      />
      <Input
        type="datetime-local"
        name="validationReadyAt"
        label="Ready for Validation At"
        onChange={setReadyForValidationAt}
        value={readyForValidationAt}
      />
      <Button className="w-32 self-center" onClick={onButtonClick}>
        Create Market
      </Button>
    </Form>
  );
};

const Form = ({ children }) => {
  return <form className="flex flex-col gap-4 py-4 px-2">{children}</form>;
};

const Input = ({ type, label, name, onChange, value }) => {
  return (
    <div className="flex items-center rounded-lg bg-zinc-800 dark:bg-white">
      <label className="px-4 text-white dark:text-zinc-800" htmlFor={name}>
        {label}
      </label>
      <input
        className="flex-1 rounded-lg border-2 border-zinc-800 bg-white py-2 px-4 focus:outline-none dark:border-white dark:bg-zinc-800"
        id={name}
        type={type}
        name={name}
        onChange={(e) => onChange(e.target.value)}
        value={value}
      />
    </div>
  );
};
