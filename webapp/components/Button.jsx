const Button = ({ onClick, children, className }) => {
  return (
    <button
      className={`rounded-lg border-2 border-zinc-900 px-2 py-1 hover:bg-zinc-800 hover:text-white dark:border-white dark:hover:bg-white dark:hover:text-zinc-900 ${className}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
};

export default Button;
