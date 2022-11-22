import Link from 'next/link';
import { useRouter } from 'next/router';
import React from 'react';
import { TopBar } from '../components/TopBar';
import Web3Provider from '../providers/web3';
import '../styles/globals.css';

function MyApp({ Component, pageProps }) {
  return (
    <Web3Provider>
      <nav>
        <TopBar />
        <Menu />
      </nav>
      <Component {...pageProps} />
    </Web3Provider>
  );
}

export default MyApp;

const Menu = () => {
  const [activeMenu, setActiveMenu] = React.useState('Markets');
  const router = useRouter();

  return (
    <nav>
      <ul className="flex items-center border-t-2">
        <MenuItem
          active={activeMenu === 'Markets'}
          onClick={() => setActiveMenu('Markets')}
        >
          Markets
        </MenuItem>
        <MenuItem
          active={activeMenu === 'Rewards'}
          onClick={() => setActiveMenu('Rewards')}
        >
          Rewards
        </MenuItem>
        <MenuItem
          active={activeMenu === 'Maintenance'}
          onClick={() => setActiveMenu('Maintenance')}
        >
          <Link href="/maintenance">Maintenance</Link>
        </MenuItem>
        <MenuItem
          active={activeMenu === 'Validations'}
          onClick={() => setActiveMenu('Validations')}
        >
          <Link href="/validations">Validations</Link>
        </MenuItem>
        <MenuItem
          active={activeMenu === 'Treasury'}
          onClick={() => setActiveMenu('Treasury')}
        >
          <Link href="/treasury">Treasury</Link>
        </MenuItem>
      </ul>
      <ul className="flex items-center border-b-2 bg-zinc-800 text-white dark:bg-white dark:text-zinc-800">
        <Switch value={activeMenu}>
          <Switch.Case value="Markets">
            <SubMenuItem active={router.asPath === '/markets/trending'}>
              <Link href="/markets/trending">Trending</Link>
            </SubMenuItem>
            <SubMenuItem active={router.asPath === '/markets/new'}>
              <Link href="/markets/new">New</Link>
            </SubMenuItem>
          </Switch.Case>
          <Switch.Case value="Rewards">
            <SubMenuItem active={router.asPath === '/rewards/pending'}>
              <Link href="/rewards/pending">Pending</Link>
            </SubMenuItem>
            <SubMenuItem active={router.asPath === '/rewards/claim'}>
              <Link href="/rewards/claim">Claim</Link>
            </SubMenuItem>
          </Switch.Case>
        </Switch>
      </ul>
    </nav>
  );
};

const MenuItem = ({ children, active, onClick }) => {
  return (
    <li
      className={`px-4 py-1 hover:underline ${
        active ? 'bg-zinc-800 text-white dark:bg-white dark:text-zinc-800' : ''
      }`}
      onClick={onClick}
    >
      {children}
    </li>
  );
};

const SubMenuItem = ({ children, active }) => {
  return (
    <li className={`px-4 py-1 hover:underline ${active ? 'underline' : ''}`}>
      {children}
    </li>
  );
};

const Switch = ({ value, children }) => {
  return children.filter((c) => {
    return c.props.value === value;
  });
};

Switch.Case = ({ children }) => {
  return children;
};
