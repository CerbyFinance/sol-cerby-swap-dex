/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import BN from "bn.js";
import { EventData, PastEventOptions } from "web3-eth-contract";

export interface CerbySwapV1AdminFunctionsContract
  extends Truffle.Contract<CerbySwapV1AdminFunctionsInstance> {
  "new"(
    meta?: Truffle.TransactionDetails
  ): Promise<CerbySwapV1AdminFunctionsInstance>;
}

export interface ApprovalForAll {
  name: "ApprovalForAll";
  args: {
    _account: string;
    _operator: string;
    _approved: boolean;
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

export interface OwnershipTransferred {
  name: "OwnershipTransferred";
  args: {
    previousOwner: string;
    newOwner: string;
    0: string;
    1: string;
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
    _amountCerUsdIn: BN;
    _amountTokensOut: BN;
    _amountCerUsdOut: BN;
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
    _operator: string;
    _from: string;
    _to: string;
    _ids: BN[];
    _values: BN[];
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
    _operator: string;
    _from: string;
    _to: string;
    _id: BN;
    _value: BN;
    0: string;
    1: string;
    2: string;
    3: BN;
    4: BN;
  };
}

type AllEvents =
  | ApprovalForAll
  | LiquidityAdded
  | LiquidityRemoved
  | OwnershipTransferred
  | PoolCreated
  | Swap
  | Sync
  | TransferBatch
  | TransferSingle;

export interface CerbySwapV1AdminFunctionsInstance
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

  adminChangeCerUsdCreditInPool: {
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

  adminCreatePool: {
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

  adminSetUrlPrefix: {
    (_newUrlPrefix: string, txDetails?: Truffle.TransactionDetails): Promise<
      Truffle.TransactionResponse<AllEvents>
    >;
    call(
      _newUrlPrefix: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _newUrlPrefix: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _newUrlPrefix: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  adminUpdateNameAndSymbol: {
    (
      _newContractName: string,
      _newContractSymbol: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _newContractName: string,
      _newContractSymbol: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _newContractName: string,
      _newContractSymbol: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _newContractName: string,
      _newContractSymbol: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  adminUpdateSettings: {
    (
      _settings: {
        mintFeeBeneficiary: string;
        mintFeeMultiplier: number | BN | string;
        feeMinimum: number | BN | string;
        feeMaximum: number | BN | string;
        tvlMultiplierMinimum: number | BN | string;
        tvlMultiplierMaximum: number | BN | string;
      },
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _settings: {
        mintFeeBeneficiary: string;
        mintFeeMultiplier: number | BN | string;
        feeMinimum: number | BN | string;
        feeMaximum: number | BN | string;
        tvlMultiplierMinimum: number | BN | string;
        tvlMultiplierMaximum: number | BN | string;
      },
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _settings: {
        mintFeeBeneficiary: string;
        mintFeeMultiplier: number | BN | string;
        feeMinimum: number | BN | string;
        feeMaximum: number | BN | string;
        tvlMultiplierMinimum: number | BN | string;
        tvlMultiplierMaximum: number | BN | string;
      },
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _settings: {
        mintFeeBeneficiary: string;
        mintFeeMultiplier: number | BN | string;
        feeMinimum: number | BN | string;
        feeMaximum: number | BN | string;
        tvlMultiplierMinimum: number | BN | string;
        tvlMultiplierMaximum: number | BN | string;
      },
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

  getCurrentFeeBasedOnTrades(
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

  getPoolsBalancesByTokens(
    _tokens: string[],
    txDetails?: Truffle.TransactionDetails
  ): Promise<{ balanceToken: BN; balanceCerUsd: BN }[]>;

  getPoolsByTokens(
    _tokens: string[],
    txDetails?: Truffle.TransactionDetails
  ): Promise<
    {
      tradeVolumePerPeriodInCerUsd: BN[];
      lastCachedFee: BN;
      lastCachedTradePeriod: BN;
      lastSqrtKValue: BN;
      creditCerUsd: BN;
    }[]
  >;

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

  owner(txDetails?: Truffle.TransactionDetails): Promise<string>;

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

  renounceOwnership: {
    (txDetails?: Truffle.TransactionDetails): Promise<
      Truffle.TransactionResponse<AllEvents>
    >;
    call(txDetails?: Truffle.TransactionDetails): Promise<void>;
    sendTransaction(txDetails?: Truffle.TransactionDetails): Promise<string>;
    estimateGas(txDetails?: Truffle.TransactionDetails): Promise<number>;
  };

  safeTransferFrom: {
    (
      _from: string,
      _to: string,
      _id: number | BN | string,
      _amount: number | BN | string,
      arg4: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _from: string,
      _to: string,
      _id: number | BN | string,
      _amount: number | BN | string,
      arg4: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _from: string,
      _to: string,
      _id: number | BN | string,
      _amount: number | BN | string,
      arg4: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _from: string,
      _to: string,
      _id: number | BN | string,
      _amount: number | BN | string,
      arg4: string,
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

  swapExactTokensForTokens: {
    (
      _tokenIn: string,
      _tokenOut: string,
      _amountTokensIn: number | BN | string,
      _minAmountTokensOut: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _tokenIn: string,
      _tokenOut: string,
      _amountTokensIn: number | BN | string,
      _minAmountTokensOut: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN[]>;
    sendTransaction(
      _tokenIn: string,
      _tokenOut: string,
      _amountTokensIn: number | BN | string,
      _minAmountTokensOut: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _tokenIn: string,
      _tokenOut: string,
      _amountTokensIn: number | BN | string,
      _minAmountTokensOut: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  swapTokensForExactTokens: {
    (
      _tokenIn: string,
      _tokenOut: string,
      _amountTokensOut: number | BN | string,
      _maxAmountTokensIn: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _tokenIn: string,
      _tokenOut: string,
      _amountTokensOut: number | BN | string,
      _maxAmountTokensIn: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN[]>;
    sendTransaction(
      _tokenIn: string,
      _tokenOut: string,
      _amountTokensOut: number | BN | string,
      _maxAmountTokensIn: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _tokenIn: string,
      _tokenOut: string,
      _amountTokensOut: number | BN | string,
      _maxAmountTokensIn: number | BN | string,
      _expireTimestamp: number | BN | string,
      _transferTo: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  symbol(txDetails?: Truffle.TransactionDetails): Promise<string>;

  transferOwnership: {
    (_newOwner: string, txDetails?: Truffle.TransactionDetails): Promise<
      Truffle.TransactionResponse<AllEvents>
    >;
    call(
      _newOwner: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _newOwner: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _newOwner: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

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

    adminChangeCerUsdCreditInPool: {
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

    adminCreatePool: {
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

    adminSetUrlPrefix: {
      (_newUrlPrefix: string, txDetails?: Truffle.TransactionDetails): Promise<
        Truffle.TransactionResponse<AllEvents>
      >;
      call(
        _newUrlPrefix: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _newUrlPrefix: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _newUrlPrefix: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    adminUpdateNameAndSymbol: {
      (
        _newContractName: string,
        _newContractSymbol: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _newContractName: string,
        _newContractSymbol: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _newContractName: string,
        _newContractSymbol: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _newContractName: string,
        _newContractSymbol: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    adminUpdateSettings: {
      (
        _settings: {
          mintFeeBeneficiary: string;
          mintFeeMultiplier: number | BN | string;
          feeMinimum: number | BN | string;
          feeMaximum: number | BN | string;
          tvlMultiplierMinimum: number | BN | string;
          tvlMultiplierMaximum: number | BN | string;
        },
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _settings: {
          mintFeeBeneficiary: string;
          mintFeeMultiplier: number | BN | string;
          feeMinimum: number | BN | string;
          feeMaximum: number | BN | string;
          tvlMultiplierMinimum: number | BN | string;
          tvlMultiplierMaximum: number | BN | string;
        },
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _settings: {
          mintFeeBeneficiary: string;
          mintFeeMultiplier: number | BN | string;
          feeMinimum: number | BN | string;
          feeMaximum: number | BN | string;
          tvlMultiplierMinimum: number | BN | string;
          tvlMultiplierMaximum: number | BN | string;
        },
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _settings: {
          mintFeeBeneficiary: string;
          mintFeeMultiplier: number | BN | string;
          feeMinimum: number | BN | string;
          feeMaximum: number | BN | string;
          tvlMultiplierMinimum: number | BN | string;
          tvlMultiplierMaximum: number | BN | string;
        },
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

    getCurrentFeeBasedOnTrades(
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

    getPoolsBalancesByTokens(
      _tokens: string[],
      txDetails?: Truffle.TransactionDetails
    ): Promise<{ balanceToken: BN; balanceCerUsd: BN }[]>;

    getPoolsByTokens(
      _tokens: string[],
      txDetails?: Truffle.TransactionDetails
    ): Promise<
      {
        tradeVolumePerPeriodInCerUsd: BN[];
        lastCachedFee: BN;
        lastCachedTradePeriod: BN;
        lastSqrtKValue: BN;
        creditCerUsd: BN;
      }[]
    >;

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

    owner(txDetails?: Truffle.TransactionDetails): Promise<string>;

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

    renounceOwnership: {
      (txDetails?: Truffle.TransactionDetails): Promise<
        Truffle.TransactionResponse<AllEvents>
      >;
      call(txDetails?: Truffle.TransactionDetails): Promise<void>;
      sendTransaction(txDetails?: Truffle.TransactionDetails): Promise<string>;
      estimateGas(txDetails?: Truffle.TransactionDetails): Promise<number>;
    };

    safeTransferFrom: {
      (
        _from: string,
        _to: string,
        _id: number | BN | string,
        _amount: number | BN | string,
        arg4: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _from: string,
        _to: string,
        _id: number | BN | string,
        _amount: number | BN | string,
        arg4: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _from: string,
        _to: string,
        _id: number | BN | string,
        _amount: number | BN | string,
        arg4: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _from: string,
        _to: string,
        _id: number | BN | string,
        _amount: number | BN | string,
        arg4: string,
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

    swapExactTokensForTokens: {
      (
        _tokenIn: string,
        _tokenOut: string,
        _amountTokensIn: number | BN | string,
        _minAmountTokensOut: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _tokenIn: string,
        _tokenOut: string,
        _amountTokensIn: number | BN | string,
        _minAmountTokensOut: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<BN[]>;
      sendTransaction(
        _tokenIn: string,
        _tokenOut: string,
        _amountTokensIn: number | BN | string,
        _minAmountTokensOut: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _tokenIn: string,
        _tokenOut: string,
        _amountTokensIn: number | BN | string,
        _minAmountTokensOut: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    swapTokensForExactTokens: {
      (
        _tokenIn: string,
        _tokenOut: string,
        _amountTokensOut: number | BN | string,
        _maxAmountTokensIn: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _tokenIn: string,
        _tokenOut: string,
        _amountTokensOut: number | BN | string,
        _maxAmountTokensIn: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<BN[]>;
      sendTransaction(
        _tokenIn: string,
        _tokenOut: string,
        _amountTokensOut: number | BN | string,
        _maxAmountTokensIn: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _tokenIn: string,
        _tokenOut: string,
        _amountTokensOut: number | BN | string,
        _maxAmountTokensIn: number | BN | string,
        _expireTimestamp: number | BN | string,
        _transferTo: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    symbol(txDetails?: Truffle.TransactionDetails): Promise<string>;

    transferOwnership: {
      (_newOwner: string, txDetails?: Truffle.TransactionDetails): Promise<
        Truffle.TransactionResponse<AllEvents>
      >;
      call(
        _newOwner: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _newOwner: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _newOwner: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

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
