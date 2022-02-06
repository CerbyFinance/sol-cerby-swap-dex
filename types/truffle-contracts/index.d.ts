/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { AccessControlContract } from "./AccessControl";
import { AccessControlEnumerableContract } from "./AccessControlEnumerable";
import { CerbyCronJobsExecutionContract } from "./CerbyCronJobsExecution";
import { CerbySwapLP1155V1Contract } from "./CerbySwapLP1155V1";
import { CerbySwapV1Contract } from "./CerbySwapV1";
import { CerbySwapV1AdminFunctionsContract } from "./CerbySwapV1AdminFunctions";
import { CerbySwapV1DeclarationsContract } from "./CerbySwapV1Declarations";
import { CerbySwapV1ERC1155Contract } from "./CerbySwapV1ERC1155";
import { CerbySwapV1EventsAndErrorsContract } from "./CerbySwapV1EventsAndErrors";
import { CerbySwapV1GetFunctionsContract } from "./CerbySwapV1GetFunctions";
import { CerbySwapV1LiquidityFunctionsContract } from "./CerbySwapV1LiquidityFunctions";
import { CerbySwapV1MinimalProxyContract } from "./CerbySwapV1MinimalProxy";
import { CerbySwapV1ModifiersContract } from "./CerbySwapV1Modifiers";
import { CerbySwapV1SafeFunctionsContract } from "./CerbySwapV1SafeFunctions";
import { CerbySwapV1SwapFunctionsContract } from "./CerbySwapV1SwapFunctions";
import { CerbySwapV1VaultContract } from "./CerbySwapV1Vault";
import { CerbySwapV1VaultImplementationContract } from "./CerbySwapV1VaultImplementation";
import { ERC1155Contract } from "./ERC1155";
import { ERC1155SupplyContract } from "./ERC1155Supply";
import { ERC165Contract } from "./ERC165";
import { ERC20Contract } from "./ERC20";
import { IAccessControlContract } from "./IAccessControl";
import { IAccessControlEnumerableContract } from "./IAccessControlEnumerable";
import { IBasicERC20Contract } from "./IBasicERC20";
import { ICerbyBotDetectionContract } from "./ICerbyBotDetection";
import { ICerbySwapV1VaultContract } from "./ICerbySwapV1Vault";
import { ICerbySwapV1VaultImplementationContract } from "./ICerbySwapV1VaultImplementation";
import { ICerbyTokenContract } from "./ICerbyToken";
import { ICerbyTokenMinterBurnerContract } from "./ICerbyTokenMinterBurner";
import { IERC1155Contract } from "./IERC1155";
import { IERC1155MetadataURIContract } from "./IERC1155MetadataURI";
import { IERC1155ReceiverContract } from "./IERC1155Receiver";
import { IERC165Contract } from "./IERC165";
import { IERC20Contract } from "./IERC20";
import { IERC20MetadataContract } from "./IERC20Metadata";
import { MigrationsContract } from "./Migrations";
import { OwnableContract } from "./Ownable";
import { TestCerUsdTokenContract } from "./TestCerUsdToken";
import { TestCerbyTokenContract } from "./TestCerbyToken";
import { TestUsdcTokenContract } from "./TestUsdcToken";

declare global {
  namespace Truffle {
    interface Artifacts {
      require(name: "AccessControl"): AccessControlContract;
      require(name: "AccessControlEnumerable"): AccessControlEnumerableContract;
      require(name: "CerbyCronJobsExecution"): CerbyCronJobsExecutionContract;
      require(name: "CerbySwapLP1155V1"): CerbySwapLP1155V1Contract;
      require(name: "CerbySwapV1"): CerbySwapV1Contract;
      require(
        name: "CerbySwapV1_AdminFunctions"
      ): CerbySwapV1AdminFunctionsContract;
      require(
        name: "CerbySwapV1_Declarations"
      ): CerbySwapV1DeclarationsContract;
      require(name: "CerbySwapV1_ERC1155"): CerbySwapV1ERC1155Contract;
      require(
        name: "CerbySwapV1_EventsAndErrors"
      ): CerbySwapV1EventsAndErrorsContract;
      require(
        name: "CerbySwapV1_GetFunctions"
      ): CerbySwapV1GetFunctionsContract;
      require(
        name: "CerbySwapV1_LiquidityFunctions"
      ): CerbySwapV1LiquidityFunctionsContract;
      require(
        name: "CerbySwapV1_MinimalProxy"
      ): CerbySwapV1MinimalProxyContract;
      require(name: "CerbySwapV1_Modifiers"): CerbySwapV1ModifiersContract;
      require(
        name: "CerbySwapV1_SafeFunctions"
      ): CerbySwapV1SafeFunctionsContract;
      require(
        name: "CerbySwapV1_SwapFunctions"
      ): CerbySwapV1SwapFunctionsContract;
      require(name: "CerbySwapV1_Vault"): CerbySwapV1VaultContract;
      require(
        name: "CerbySwapV1_VaultImplementation"
      ): CerbySwapV1VaultImplementationContract;
      require(name: "ERC1155"): ERC1155Contract;
      require(name: "ERC1155Supply"): ERC1155SupplyContract;
      require(name: "ERC165"): ERC165Contract;
      require(name: "ERC20"): ERC20Contract;
      require(name: "IAccessControl"): IAccessControlContract;
      require(
        name: "IAccessControlEnumerable"
      ): IAccessControlEnumerableContract;
      require(name: "IBasicERC20"): IBasicERC20Contract;
      require(name: "ICerbyBotDetection"): ICerbyBotDetectionContract;
      require(name: "ICerbySwapV1_Vault"): ICerbySwapV1VaultContract;
      require(
        name: "ICerbySwapV1_VaultImplementation"
      ): ICerbySwapV1VaultImplementationContract;
      require(name: "ICerbyToken"): ICerbyTokenContract;
      require(name: "ICerbyTokenMinterBurner"): ICerbyTokenMinterBurnerContract;
      require(name: "IERC1155"): IERC1155Contract;
      require(name: "IERC1155MetadataURI"): IERC1155MetadataURIContract;
      require(name: "IERC1155Receiver"): IERC1155ReceiverContract;
      require(name: "IERC165"): IERC165Contract;
      require(name: "IERC20"): IERC20Contract;
      require(name: "IERC20Metadata"): IERC20MetadataContract;
      require(name: "Migrations"): MigrationsContract;
      require(name: "Ownable"): OwnableContract;
      require(name: "TestCerUsdToken"): TestCerUsdTokenContract;
      require(name: "TestCerbyToken"): TestCerbyTokenContract;
      require(name: "TestUsdcToken"): TestUsdcTokenContract;
    }
  }
}

export { AccessControlContract, AccessControlInstance } from "./AccessControl";
export {
  AccessControlEnumerableContract,
  AccessControlEnumerableInstance,
} from "./AccessControlEnumerable";
export {
  CerbyCronJobsExecutionContract,
  CerbyCronJobsExecutionInstance,
} from "./CerbyCronJobsExecution";
export {
  CerbySwapLP1155V1Contract,
  CerbySwapLP1155V1Instance,
} from "./CerbySwapLP1155V1";
export { CerbySwapV1Contract, CerbySwapV1Instance } from "./CerbySwapV1";
export {
  CerbySwapV1AdminFunctionsContract,
  CerbySwapV1AdminFunctionsInstance,
} from "./CerbySwapV1AdminFunctions";
export {
  CerbySwapV1DeclarationsContract,
  CerbySwapV1DeclarationsInstance,
} from "./CerbySwapV1Declarations";
export {
  CerbySwapV1ERC1155Contract,
  CerbySwapV1ERC1155Instance,
} from "./CerbySwapV1ERC1155";
export {
  CerbySwapV1EventsAndErrorsContract,
  CerbySwapV1EventsAndErrorsInstance,
} from "./CerbySwapV1EventsAndErrors";
export {
  CerbySwapV1GetFunctionsContract,
  CerbySwapV1GetFunctionsInstance,
} from "./CerbySwapV1GetFunctions";
export {
  CerbySwapV1LiquidityFunctionsContract,
  CerbySwapV1LiquidityFunctionsInstance,
} from "./CerbySwapV1LiquidityFunctions";
export {
  CerbySwapV1MinimalProxyContract,
  CerbySwapV1MinimalProxyInstance,
} from "./CerbySwapV1MinimalProxy";
export {
  CerbySwapV1ModifiersContract,
  CerbySwapV1ModifiersInstance,
} from "./CerbySwapV1Modifiers";
export {
  CerbySwapV1SafeFunctionsContract,
  CerbySwapV1SafeFunctionsInstance,
} from "./CerbySwapV1SafeFunctions";
export {
  CerbySwapV1SwapFunctionsContract,
  CerbySwapV1SwapFunctionsInstance,
} from "./CerbySwapV1SwapFunctions";
export {
  CerbySwapV1VaultContract,
  CerbySwapV1VaultInstance,
} from "./CerbySwapV1Vault";
export {
  CerbySwapV1VaultImplementationContract,
  CerbySwapV1VaultImplementationInstance,
} from "./CerbySwapV1VaultImplementation";
export { ERC1155Contract, ERC1155Instance } from "./ERC1155";
export { ERC1155SupplyContract, ERC1155SupplyInstance } from "./ERC1155Supply";
export { ERC165Contract, ERC165Instance } from "./ERC165";
export { ERC20Contract, ERC20Instance } from "./ERC20";
export {
  IAccessControlContract,
  IAccessControlInstance,
} from "./IAccessControl";
export {
  IAccessControlEnumerableContract,
  IAccessControlEnumerableInstance,
} from "./IAccessControlEnumerable";
export { IBasicERC20Contract, IBasicERC20Instance } from "./IBasicERC20";
export {
  ICerbyBotDetectionContract,
  ICerbyBotDetectionInstance,
} from "./ICerbyBotDetection";
export {
  ICerbySwapV1VaultContract,
  ICerbySwapV1VaultInstance,
} from "./ICerbySwapV1Vault";
export {
  ICerbySwapV1VaultImplementationContract,
  ICerbySwapV1VaultImplementationInstance,
} from "./ICerbySwapV1VaultImplementation";
export { ICerbyTokenContract, ICerbyTokenInstance } from "./ICerbyToken";
export {
  ICerbyTokenMinterBurnerContract,
  ICerbyTokenMinterBurnerInstance,
} from "./ICerbyTokenMinterBurner";
export { IERC1155Contract, IERC1155Instance } from "./IERC1155";
export {
  IERC1155MetadataURIContract,
  IERC1155MetadataURIInstance,
} from "./IERC1155MetadataURI";
export {
  IERC1155ReceiverContract,
  IERC1155ReceiverInstance,
} from "./IERC1155Receiver";
export { IERC165Contract, IERC165Instance } from "./IERC165";
export { IERC20Contract, IERC20Instance } from "./IERC20";
export {
  IERC20MetadataContract,
  IERC20MetadataInstance,
} from "./IERC20Metadata";
export { MigrationsContract, MigrationsInstance } from "./Migrations";
export { OwnableContract, OwnableInstance } from "./Ownable";
export {
  TestCerUsdTokenContract,
  TestCerUsdTokenInstance,
} from "./TestCerUsdToken";
export {
  TestCerbyTokenContract,
  TestCerbyTokenInstance,
} from "./TestCerbyToken";
export { TestUsdcTokenContract, TestUsdcTokenInstance } from "./TestUsdcToken";
