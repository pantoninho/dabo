const Market = ({ description, betsClosedAt }) => {
  return (
    <div className="rounded-lg border-2 border-zinc-800 p-2 dark:border-white">
      <h3>{description}</h3>
      <br />
      <h3>bets close at: {betsClosedAt}</h3>
    </div>
  );
};

export default Market;
