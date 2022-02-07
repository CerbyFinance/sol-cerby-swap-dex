/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import BN from "bn.js";
import { EventData, PastEventOptions } from "web3-eth-contract";

export interface CerbySwapV1VaultImplementationContract
  extends Truffle.Contract<CerbySwapV1VaultImplementationInstance> {
  "new"(
    meta?: Truffle.TransactionDetails
  ): Promise<CerbySwapV1VaultImplementationInstance>;
}

type AllEvents = never;

export interface CerbySwapV1VaultImplementationInstance
  extends Truffle.ContractInstance {
  initialize: {
    (
      _token: string,
      _cerUsdToken: string,
      _isNativeToken: boolean,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _token: string,
      _cerUsdToken: string,
      _isNativeToken: boolean,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _token: string,
      _cerUsdToken: string,
      _isNativeToken: boolean,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _token: string,
      _cerUsdToken: string,
      _isNativeToken: boolean,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  token0(txDetails?: Truffle.TransactionDetails): Promise<string>;

  token1(txDetails?: Truffle.TransactionDetails): Promise<string>;

  withdrawEth: {
    (
      _to: string,
      _value: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _to: string,
      _value: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _to: string,
      _value: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _to: string,
      _value: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  methods: {
    initialize: {
      (
        _token: string,
        _cerUsdToken: string,
        _isNativeToken: boolean,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _token: string,
        _cerUsdToken: string,
        _isNativeToken: boolean,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _token: string,
        _cerUsdToken: string,
        _isNativeToken: boolean,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _token: string,
        _cerUsdToken: string,
        _isNativeToken: boolean,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    token0(txDetails?: Truffle.TransactionDetails): Promise<string>;

    token1(txDetails?: Truffle.TransactionDetails): Promise<string>;

    withdrawEth: {
      (
        _to: string,
        _value: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _to: string,
        _value: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _to: string,
        _value: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _to: string,
        _value: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };
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