/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import BN from "bn.js";
import { EventData, PastEventOptions } from "web3-eth-contract";

export interface ICerbyBotDetectionContract
  extends Truffle.Contract<ICerbyBotDetectionInstance> {
  "new"(meta?: Truffle.TransactionDetails): Promise<ICerbyBotDetectionInstance>;
}

type AllEvents = never;

export interface ICerbyBotDetectionInstance extends Truffle.ContractInstance {
  checkTransactionInfo: {
    (
      _tokenAddr: string,
      _sender: string,
      _recipient: string,
      _recipientBalance: number | BN | string,
      _transferAmount: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _tokenAddr: string,
      _sender: string,
      _recipient: string,
      _recipientBalance: number | BN | string,
      _transferAmount: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<{ isBuy: boolean; isSell: boolean }>;
    sendTransaction(
      _tokenAddr: string,
      _sender: string,
      _recipient: string,
      _recipientBalance: number | BN | string,
      _transferAmount: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _tokenAddr: string,
      _sender: string,
      _recipient: string,
      _recipientBalance: number | BN | string,
      _transferAmount: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  detectBotTransaction: {
    (
      _tokenAddr: string,
      _addr: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _tokenAddr: string,
      _addr: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<boolean>;
    sendTransaction(
      _tokenAddr: string,
      _addr: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _tokenAddr: string,
      _addr: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  executeCronJobs: {
    (txDetails?: Truffle.TransactionDetails): Promise<
      Truffle.TransactionResponse<AllEvents>
    >;
    call(txDetails?: Truffle.TransactionDetails): Promise<void>;
    sendTransaction(txDetails?: Truffle.TransactionDetails): Promise<string>;
    estimateGas(txDetails?: Truffle.TransactionDetails): Promise<number>;
  };

  isBotAddress(
    _addr: string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<boolean>;

  registerTransaction: {
    (
      _tokenAddr: string,
      _addr: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _tokenAddr: string,
      _addr: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _tokenAddr: string,
      _addr: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _tokenAddr: string,
      _addr: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  methods: {
    checkTransactionInfo: {
      (
        _tokenAddr: string,
        _sender: string,
        _recipient: string,
        _recipientBalance: number | BN | string,
        _transferAmount: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _tokenAddr: string,
        _sender: string,
        _recipient: string,
        _recipientBalance: number | BN | string,
        _transferAmount: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<{ isBuy: boolean; isSell: boolean }>;
      sendTransaction(
        _tokenAddr: string,
        _sender: string,
        _recipient: string,
        _recipientBalance: number | BN | string,
        _transferAmount: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _tokenAddr: string,
        _sender: string,
        _recipient: string,
        _recipientBalance: number | BN | string,
        _transferAmount: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    detectBotTransaction: {
      (
        _tokenAddr: string,
        _addr: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _tokenAddr: string,
        _addr: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<boolean>;
      sendTransaction(
        _tokenAddr: string,
        _addr: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _tokenAddr: string,
        _addr: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    executeCronJobs: {
      (txDetails?: Truffle.TransactionDetails): Promise<
        Truffle.TransactionResponse<AllEvents>
      >;
      call(txDetails?: Truffle.TransactionDetails): Promise<void>;
      sendTransaction(txDetails?: Truffle.TransactionDetails): Promise<string>;
      estimateGas(txDetails?: Truffle.TransactionDetails): Promise<number>;
    };

    isBotAddress(
      _addr: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<boolean>;

    registerTransaction: {
      (
        _tokenAddr: string,
        _addr: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _tokenAddr: string,
        _addr: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _tokenAddr: string,
        _addr: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _tokenAddr: string,
        _addr: string,
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
