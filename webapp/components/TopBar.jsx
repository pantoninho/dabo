import { useWeb3React } from '@web3-react/core';
import React from 'react';
import { connectors } from '../providers/web3';
import Button from './Button';
import ThemeToggler from './ThemeToggler';

export const TopBar = () => {
  return (
    <div className="flex items-center h-14">
      <div className="flex-1 w-3/4">
        <h1 className="text-lg px-4">
          Decentralized Autonomous Information Markets
        </h1>
      </div>
      <div className="flex-none flex justify-center">
        <ConnectWalletButton />
      </div>
      <div className="flex-none w-8 h-8">
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
