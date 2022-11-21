const Button = ({ onClick, children, className, type, disabled }) => {
  return (
    <button
      disabled={disabled}
      type={type}
      className={`rounded-lg border-2 border-zinc-900 px-2 py-1 enabled:hover:bg-zinc-800 enabled:hover:text-white dark:border-white enabled:dark:hover:bg-white enabled:dark:hover:text-zinc-900 ${className}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
};

export default Button;
