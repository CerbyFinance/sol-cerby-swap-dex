/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import BN from "bn.js";
import { EventData, PastEventOptions } from "web3-eth-contract";

export interface CerbySwapV1DeclarationsContract
  extends Truffle.Contract<CerbySwapV1DeclarationsInstance> {
  "new"(
    meta?: Truffle.TransactionDetails
  ): Promise<CerbySwapV1DeclarationsInstance>;
}

export interface LiquidityAdded {
  name: "LiquidityAdded";
  args: {
    _token: string;
    _amountTokensIn: BN;
    _amountCerUsdToMint: BN;
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
    _amountCerUsdToBurn: BN;
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
    _poolId: BN;
    0: string;
    1: BN;
  };
}

export interface Swap {
  name: "Swap";
  args: {
    _token: string;
    _sender: string;
    _amountTokensIn: BN;
    _amountCerUsdIn: BN;
    __amountTokensOut: BN;
    amountCerUsdOut: BN;
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
    _newBalanceCerUsd: BN;
    _newCreditCerUsd: BN;
    0: string;
    1: BN;
    2: BN;
    3: BN;
  };
}

type AllEvents = LiquidityAdded | LiquidityRemoved | PoolCreated | Swap | Sync;

export interface CerbySwapV1DeclarationsInstance
  extends Truffle.ContractInstance {
  hourlyTradeVolumeInCerUsd(
    arg0: string,
    arg1: number | BN | string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<BN>;

  oneMinusFeeCached(
    arg0: string,
    arg1: number | BN | string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<BN>;

  methods: {
    hourlyTradeVolumeInCerUsd(
      arg0: string,
      arg1: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN>;

    oneMinusFeeCached(
      arg0: string,
      arg1: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN>;
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
