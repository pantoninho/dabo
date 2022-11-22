import {
  useActiveMarkets,
  useValidationProcess,
} from '../../../smart-contracts/daim';
import Market from '../../../components/Market';
import Masonry, { ResponsiveMasonry } from 'react-responsive-masonry';
import Button from '../../../components/Button';

const PendingValidationMarkets = () => {
  const { validatingMarkets, openMarkets, isLoading, error } =
    useActiveMarkets();

  if (error || isLoading) return <div></div>;

  return (
    <ResponsiveMasonry
      className="p-4"
      columnsCountBreakPoints={{ 0: 1, 700: 2, 1200: 3 }}
    >
      <Masonry gutter="1em">
        {validatingMarkets.concat(openMarkets).map((market) => {
          return (
            <Market
              id={market.id}
              key={market.id}
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

export default PendingValidationMarkets;

const MarketActions = ({ id, readyForValidationAt }) => {
  const { process, isLoading, error, startValidationRound } =
    useValidationProcess(id);

  if (isLoading || error) return <div />;

  const isButtonDisabled = process.isActive;
  const buttonText = isButtonDisabled
    ? 'Validation Round Running'
    : 'Start Validation Round';

  return (
    <div className="flex items-center justify-between">
      <div className="flex-col flex gap-2">
        <h4>Ready for Validation At: {readyForValidationAt}</h4>
        <h4>Validation Round: {process.currentRound}</h4>
        <h4>Consecutive Consensus: {process.consecutiveConsensus}</h4>
      </div>
      <div>
        <Button disabled={isButtonDisabled} onClick={startValidationRound}>
          {buttonText}
        </Button>
      </div>
    </div>
  );
};
