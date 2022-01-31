/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import BN from "bn.js";
import { EventData, PastEventOptions } from "web3-eth-contract";

export interface CerbySwapV1LiquidityFunctionsContract
  extends Truffle.Contract<CerbySwapV1LiquidityFunctionsInstance> {
  "new"(
    meta?: Truffle.TransactionDetails
  ): Promise<CerbySwapV1LiquidityFunctionsInstance>;
}

export interface ApprovalForAll {
  name: "ApprovalForAll";
  args: {
    account: string;
    operator: string;
    approved: boolean;
    0: string;
    1: string;
    2: boolean;
  };
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

export interface TransferBatch {
  name: "TransferBatch";
  args: {
    operator: string;
    from: string;
    to: string;
    ids: BN[];
    values: BN[];
    0: string;
    1: string;
    2: string;
    3: BN[];
    4: BN[];
  };
}

export interface TransferSingle {
  name: "TransferSingle";
  args: {
    operator: string;
    from: string;
    to: string;
    id: BN;
    value: BN;
    0: string;
    1: string;
    2: string;
    3: BN;
    4: BN;
  };
}

export interface URI {
  name: "URI";
  args: {
    value: string;
    id: BN;
    0: string;
    1: BN;
  };
}

type AllEvents =
  | ApprovalForAll
  | LiquidityAdded
  | LiquidityRemoved
  | PoolCreated
  | Swap
  | Sync
  | TransferBatch
  | TransferSingle
  | URI;

export interface CerbySwapV1LiquidityFunctionsInstance
  extends Truffle.ContractInstance {
  addTokenLiquidity: {
    (
      _token: string,
      _amountTokensIn: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _token: string,
      _amountTokensIn: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN>;
    sendTransaction(
      _token: string,
      _amountTokensIn: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _token: string,
      _amountTokensIn: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  balanceOf(
    _account: string,
    _id: number | BN | string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<BN>;

  balanceOfBatch(
    _accounts: string[],
    _ids: (number | BN | string)[],
    txDetails?: Truffle.TransactionDetails
  ): Promise<BN[]>;

  createPool: {
    (
      _token: string,
      _amountTokensIn: number | BN | string,
      _amountCerUsdToMint: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _token: string,
      _amountTokensIn: number | BN | string,
      _amountCerUsdToMint: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _token: string,
      _amountTokensIn: number | BN | string,
      _amountCerUsdToMint: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _token: string,
      _amountTokensIn: number | BN | string,
      _amountCerUsdToMint: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  decimals(txDetails?: Truffle.TransactionDetails): Promise<BN>;

  exists(
    _id: number | BN | string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<boolean>;

  getCurrentOneMinusFeeBasedOnTrades(
    _token: string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<BN>;

  getInputTokensForExactTokens(
    _tokenIn: string,
    _tokenOut: string,
    _amountTokensOut: number | BN | string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<BN>;

  getOutputExactTokensForTokens(
    _tokenIn: string,
    _tokenOut: string,
    _amountTokensIn: number | BN | string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<BN>;

  getPoolsByTokens(
    _tokens: string[],
    txDetails?: Truffle.TransactionDetails
  ): Promise<{ balanceToken: BN; balanceCerUsd: BN }[]>;

  getSettings(
    txDetails?: Truffle.TransactionDetails
  ): Promise<{
    mintFeeBeneficiary: string;
    mintFeeMultiplier: BN;
    feeMinimum: BN;
    feeMaximum: BN;
    tvlMultiplierMinimum: BN;
    tvlMultiplierMaximum: BN;
  }>;

  getTokenToPoolId(
    _token: string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<BN>;

  getUtilsContractAtPos(
    _pos: number | BN | string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<string>;

  increaseCerUsdCreditInPool: {
    (
      _token: string,
      _amountCerUsdCredit: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _token: string,
      _amountCerUsdCredit: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _token: string,
      _amountCerUsdCredit: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _token: string,
      _amountCerUsdCredit: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  isApprovedForAll(
    _account: string,
    _operator: string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<boolean>;

  name(txDetails?: Truffle.TransactionDetails): Promise<string>;

  removeTokenLiquidity: {
    (
      _token: string,
      _amountLpTokensBalanceToBurn: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _token: string,
      _amountLpTokensBalanceToBurn: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN>;
    sendTransaction(
      _token: string,
      _amountLpTokensBalanceToBurn: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _token: string,
      _amountLpTokensBalanceToBurn: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  safeBatchTransferFrom: {
    (
      _from: string,
      _to: string,
      _ids: (number | BN | string)[],
      _amounts: (number | BN | string)[],
      _data: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _from: string,
      _to: string,
      _ids: (number | BN | string)[],
      _amounts: (number | BN | string)[],
      _data: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _from: string,
      _to: string,
      _ids: (number | BN | string)[],
      _amounts: (number | BN | string)[],
      _data: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _from: string,
      _to: string,
      _ids: (number | BN | string)[],
      _amounts: (number | BN | string)[],
      _data: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  safeTransferFrom: {
    (
      _from: string,
      _to: string,
      _id: number | BN | string,
      _amount: number | BN | string,
      _data: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _from: string,
      _to: string,
      _id: number | BN | string,
      _amount: number | BN | string,
      _data: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _from: string,
      _to: string,
      _id: number | BN | string,
      _amount: number | BN | string,
      _data: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _from: string,
      _to: string,
      _id: number | BN | string,
      _amount: number | BN | string,
      _data: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  setApprovalForAll: {
    (
      _operator: string,
      _approved: boolean,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _operator: string,
      _approved: boolean,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _operator: string,
      _approved: boolean,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _operator: string,
      _approved: boolean,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  supportsInterface(
    interfaceId: string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<boolean>;

  symbol(txDetails?: Truffle.TransactionDetails): Promise<string>;

  uri(
    _id: number | BN | string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<string>;

  methods: {
    addTokenLiquidity: {
      (
        _token: string,
        _amountTokensIn: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _token: string,
        _amountTokensIn: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<BN>;
      sendTransaction(
        _token: string,
        _amountTokensIn: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _token: string,
        _amountTokensIn: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    balanceOf(
      _account: string,
      _id: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN>;

    balanceOfBatch(
      _accounts: string[],
      _ids: (number | BN | string)[],
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN[]>;

    createPool: {
      (
        _token: string,
        _amountTokensIn: number | BN | string,
        _amountCerUsdToMint: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _token: string,
        _amountTokensIn: number | BN | string,
        _amountCerUsdToMint: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _token: string,
        _amountTokensIn: number | BN | string,
        _amountCerUsdToMint: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _token: string,
        _amountTokensIn: number | BN | string,
        _amountCerUsdToMint: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    decimals(txDetails?: Truffle.TransactionDetails): Promise<BN>;

    exists(
      _id: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<boolean>;

    getCurrentOneMinusFeeBasedOnTrades(
      _token: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN>;

    getInputTokensForExactTokens(
      _tokenIn: string,
      _tokenOut: string,
      _amountTokensOut: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN>;

    getOutputExactTokensForTokens(
      _tokenIn: string,
      _tokenOut: string,
      _amountTokensIn: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN>;

    getPoolsByTokens(
      _tokens: string[],
      txDetails?: Truffle.TransactionDetails
    ): Promise<{ balanceToken: BN; balanceCerUsd: BN }[]>;

    getSettings(
      txDetails?: Truffle.TransactionDetails
    ): Promise<{
      mintFeeBeneficiary: string;
      mintFeeMultiplier: BN;
      feeMinimum: BN;
      feeMaximum: BN;
      tvlMultiplierMinimum: BN;
      tvlMultiplierMaximum: BN;
    }>;

    getTokenToPoolId(
      _token: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN>;

    getUtilsContractAtPos(
      _pos: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;

    increaseCerUsdCreditInPool: {
      (
        _token: string,
        _amountCerUsdCredit: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _token: string,
        _amountCerUsdCredit: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _token: string,
        _amountCerUsdCredit: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _token: string,
        _amountCerUsdCredit: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    isApprovedForAll(
      _account: string,
      _operator: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<boolean>;

    name(txDetails?: Truffle.TransactionDetails): Promise<string>;

    removeTokenLiquidity: {
      (
        _token: string,
        _amountLpTokensBalanceToBurn: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _token: string,
        _amountLpTokensBalanceToBurn: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<BN>;
      sendTransaction(
        _token: string,
        _amountLpTokensBalanceToBurn: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _token: string,
        _amountLpTokensBalanceToBurn: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    safeBatchTransferFrom: {
      (
        _from: string,
        _to: string,
        _ids: (number | BN | string)[],
        _amounts: (number | BN | string)[],
        _data: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _from: string,
        _to: string,
        _ids: (number | BN | string)[],
        _amounts: (number | BN | string)[],
        _data: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _from: string,
        _to: string,
        _ids: (number | BN | string)[],
        _amounts: (number | BN | string)[],
        _data: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _from: string,
        _to: string,
        _ids: (number | BN | string)[],
        _amounts: (number | BN | string)[],
        _data: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    safeTransferFrom: {
      (
        _from: string,
        _to: string,
        _id: number | BN | string,
        _amount: number | BN | string,
        _data: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _from: string,
        _to: string,
        _id: number | BN | string,
        _amount: number | BN | string,
        _data: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _from: string,
        _to: string,
        _id: number | BN | string,
        _amount: number | BN | string,
        _data: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _from: string,
        _to: string,
        _id: number | BN | string,
        _amount: number | BN | string,
        _data: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    setApprovalForAll: {
      (
        _operator: string,
        _approved: boolean,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _operator: string,
        _approved: boolean,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _operator: string,
        _approved: boolean,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _operator: string,
        _approved: boolean,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    supportsInterface(
      interfaceId: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<boolean>;

    symbol(txDetails?: Truffle.TransactionDetails): Promise<string>;

    uri(
      _id: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;

    "totalSupply()"(txDetails?: Truffle.TransactionDetails): Promise<BN>;

    "totalSupply(uint256)"(
      _id: number | BN | string,
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
