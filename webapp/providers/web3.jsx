import { Web3ReactProvider } from '@web3-react/core';
import { Web3Provider as EthersProvider } from '@ethersproject/providers';
import { InjectedConnector } from '@web3-react/injected-connector';

const Web3Provider = ({ children }) => {
  return (
    <Web3ReactProvider getLibrary={(provider) => new EthersProvider(provider)}>
      {children}
    </Web3ReactProvider>
  );
};
export default Web3Provider;

const connectors = {
  injected: new InjectedConnector({
    supportedChainIds: [1, 3, 4, 5, 42, 31337],
  }),
};

export { connectors };
