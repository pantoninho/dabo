import Link from 'next/link';

const ButtonLink = ({ children, href, className }) => {
  return (
    <Link
      href={href}
      className={`rounded-md border-2 border-zinc-900 px-2 py-1 text-center hover:bg-zinc-800 hover:text-white dark:border-white dark:hover:bg-white dark:hover:text-zinc-900 ${className}`}
    >
      {children}
    </Link>
  );
};

export default ButtonLink;
