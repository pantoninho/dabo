import { useWeb3React } from '@web3-react/core';
import React from 'react';
import { connectors } from '../providers/web3';
import Button from './Button';
import ThemeToggler from './ThemeToggler';

export const TopBar = () => {
  return (
    <div className="flex h-14 items-center">
      <div className="w-3/4 flex-1">
        <h1 className="px-4 text-lg">
          Decentralized Autonomous Information Markets
        </h1>
      </div>
      <div className="flex flex-none justify-center">
        <ConnectWalletButton />
      </div>
      <div className="h-8 w-8 flex-none">
        <ThemeToggler />
      </div>
    </div>
  );
};

const ConnectWalletButton = () => {
  const { activate, active, account, chainId } = useWeb3React();

  return active ? (
    <Button className="text-[0.8em]">{`${account} @ ${chainId}`}</Button>
  ) : (
    <Button onClick={() => activate(connectors.injected)}>
      <strong>Connect Wallet</strong>
    </Button>
  );
};
