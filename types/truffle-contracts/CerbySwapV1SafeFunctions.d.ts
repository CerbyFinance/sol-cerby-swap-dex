/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import BN from "bn.js";
import { EventData, PastEventOptions } from "web3-eth-contract";

export interface CerbySwapV1SafeFunctionsContract
  extends Truffle.Contract<CerbySwapV1SafeFunctionsInstance> {
  "new"(
    meta?: Truffle.TransactionDetails
  ): Promise<CerbySwapV1SafeFunctionsInstance>;
}

export interface LiquidityAdded {
  name: "LiquidityAdded";
  args: {
    _token: string;
    _amountTokensIn: BN;
    _amountCerbyToMint: BN;
    _lpAmount: BN;
    0: string;
    1: BN;
    2: BN;
    3: BN;
  };
}

export interface LiquidityRemoved {
  name: "LiquidityRemoved";
  args: {
    _token: string;
    _amountTokensOut: BN;
    _amountCerbyToBurn: BN;
    _amountLpTokensBalanceToBurn: BN;
    0: string;
    1: BN;
    2: BN;
    3: BN;
  };
}

export interface PoolCreated {
  name: "PoolCreated";
  args: {
    _token: string;
    _vaultAddress: string;
    _poolId: BN;
    0: string;
    1: string;
    2: BN;
  };
}

export interface Swap {
  name: "Swap";
  args: {
    _token: string;
    _sender: string;
    _amountTokensIn: BN;
    _amountCerbyIn: BN;
    _amountTokensOut: BN;
    _amountCerbyOut: BN;
    _currentFee: BN;
    _transferTo: string;
    0: string;
    1: string;
    2: BN;
    3: BN;
    4: BN;
    5: BN;
    6: BN;
    7: string;
  };
}

export interface Sync {
  name: "Sync";
  args: {
    _token: string;
    _newBalanceToken: BN;
    _newBalanceCerby: BN;
    _newCreditCerby: BN;
    0: string;
    1: BN;
    2: BN;
    3: BN;
  };
}

type AllEvents = LiquidityAdded | LiquidityRemoved | PoolCreated | Swap | Sync;

export interface CerbySwapV1SafeFunctionsInstance
  extends Truffle.ContractInstance {
  getPoolBalancesByToken(
    _token: string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<{ balanceToken: BN; balanceCerby: BN }>;

  methods: {
    getPoolBalancesByToken(
      _token: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<{ balanceToken: BN; balanceCerby: BN }>;
  };

  getPastEvents(event: string): Promise<EventData[]>;
  getPastEvents(
    event: string,
    options: PastEventOptions,
    callback: (error: Error, event: EventData) => void
  ): Promise<EventData[]>;
  getPastEvents(event: string, options: PastEventOptions): Promise<EventData[]>;
  getPastEvents(
    event: string,
    callback: (error: Error, event: EventData) => void
  ): Promise<EventData[]>;
}
