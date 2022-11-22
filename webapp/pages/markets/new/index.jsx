import React from 'react';
import Select from 'react-select';
import Button from '../../../components/Button';
import { useBookie } from '../../../smart-contracts/daim';
import { Form, Input } from '../../../components/Form';

const NewMarket = () => {
  const bookie = useBookie();

  const onSubmit = async ({
    description,
    category,
    betsClosedAt,
    readyForValidationAt,
  }) => {
    await bookie.propose({
      description,
      category,
      betsClosedAt,
      readyForValidationAt,
    });
  };

  return (
    <div className="flex justify-center p-8">
      <div className="flex rounded-md border-2 border-zinc-800 p-2 dark:border-white">
        <NewMarketForm onSubmit={onSubmit} />
      </div>
    </div>
  );
};

export default NewMarket;

const categories = [
  { value: 'Politics', label: 'Politics' },
  { value: 'Economy', label: 'Economy' },
  { value: 'World Events', label: 'World Events' },
  { value: 'Sports', label: 'Sports' },
  { value: 'eSports', label: 'eSports' },
  { value: 'Other', label: 'Other' },
];

const NewMarketForm = ({ onSubmit }) => {
  const [description, setDescription] = React.useState('');
  const [betsClosedAt, setBetsClosedAt] = React.useState('');
  const [readyForValidationAt, setReadyForValidationAt] = React.useState('');
  const [category, setCategory] = React.useState(null);

  const onButtonClick = (e) => {
    e.preventDefault();
    onSubmit({
      description,
      betsClosedAt,
      readyForValidationAt,
      category: category.value,
    });
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
      <div className="flex items-center rounded-md bg-zinc-800 dark:bg-white">
        <label className="px-4 py-2 text-white dark:text-zinc-800">
          Category
        </label>
        <Select
          className="text-inc-800 flex-1 rounded-md border-2 border-zinc-800 bg-white dark:border-white dark:bg-zinc-800"
          defaultValue={category}
          onChange={setCategory}
          value={category}
          options={categories}
          styles={{
            menuList: (baseStyles) => ({
              ...baseStyles,
              color: 'black',
            }),
          }}
        />
      </div>

      <Button className="mt-8 flex-1" onClick={onButtonClick}>
        Create Market
      </Button>
    </Form>
  );
};
