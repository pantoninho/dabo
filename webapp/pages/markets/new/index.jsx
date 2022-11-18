import React from 'react';
import Button from '../../../components/Button';
import { useDAIM } from '../../../smart-contracts/daim';
import { Form, Input } from '../../../components/Form';

const NewMarket = () => {
  const daim = useDAIM();

  const onSubmit = async ({
    description,
    betsClosedAt,
    readyForValidationAt,
  }) => {
    await daim.propose({
      description,
      betsClosedAt,
      readyForValidationAt,
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
