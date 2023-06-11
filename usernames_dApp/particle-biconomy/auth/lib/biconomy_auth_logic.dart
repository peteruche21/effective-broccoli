import 'dart:convert';
import 'dart:developer';
import 'package:auth/mock/transaction_mock.dart';
import 'package:particle_auth/model/biconmoy_fee_mode.dart';
import 'package:particle_auth/model/biconomy_version.dart';
import 'package:particle_auth/model/chain_info.dart';
import 'package:particle_auth/model/login_info.dart';
import 'package:particle_auth/model/particle_info.dart';
import 'package:particle_auth/network/model/rpc_error.dart';
import 'package:particle_biconomy/particle_biconomy.dart';
import 'package:particle_auth/particle_auth.dart';
import 'package:particle_connect/model/wallet_type.dart';
import 'package:particle_connect/particle_connect.dart';

class BiconomyAuthlogic {
  static void init() {
    // should call ParticleAuth init first.
    ParticleAuth.init(EthereumChain.goerli(), Env.dev);

    const version = BiconomyVersion.v1_0_0;
    Map<int, String> dappKeys = {
      1: "your ethereum mainnet key",
      5: "OsMFRLsGI.016cb8db-b2a8-4d84-90f6-54ec171ab2e9",
      137: "your polygon mainnet key",
      80001: ""
    };
    ParticleAuth.init(PolygonChain.mainnet(), Env.production);

    // Get your project id and client from dashboard, https://dashboard.particle.network
    const projectId = "fc510708-3e32-4b2c-a13f-c06d3943601b";
    const clientKey = "cjRX2NedPeT2YsqTr3m0YubsCQAPTheet17qfG7F";
    if (projectId.isEmpty || clientKey.isEmpty) {
      throw const FormatException(
          'You need set project info, get your project id and client key from dashboard, https://dashboard.particle.network');
    }

    ParticleInfo.set(projectId, clientKey);

    ParticleBiconomy.init(version, dappKeys);
  }

  static void isSupportChainInfo() async {
    var result =
        await ParticleBiconomy.isSupportChainInfo(EthereumChain.goerli());
    print(result);
    log("isSupportChainInfo: $result");
  }

  static void isDeploy() async {
    const eoaAddress = "0xF2f57d4FCe0704DD10cDDf53ef6DC412438705D5";
    var result = await ParticleBiconomy.isDeploy(eoaAddress);
    final status = jsonDecode(result)["status"];
    final data = jsonDecode(result)["data"];
    if (status == true || status == 1) {
      var isDelpoy = jsonDecode(result)["data"];
      print(isDelpoy);
    } else {
      final error = RpcError.fromJson(data);
      print(error);
    }

    log("isDeploy: $result");
  }

  static void isBiconomyModeEnable() async {
    var result = await ParticleBiconomy.isBiconomyModeEnable();
    print(result);
    log("isBiconomyModeEnable: $result");
  }

  static void enableBiconomyMode() {
    ParticleBiconomy.enableBiconomyMode();
  }

  static void disableBiconomyMode() {
    ParticleBiconomy.disableBiconomyMode();
  }

  static void rpcGetFeeQuotes() async {
    final publicAddress = await ParticleAuth.getAddress();
    final transaction = await TransactionMock.mockEvmSendNative(publicAddress);

    List<String> transactions = <String>[transaction];
    var result =
        await ParticleBiconomy.rpcGetFeeQuotes(publicAddress, transactions);
    print(result[0]["address"]);
    log("rpcGetFeeQuotes: $result");
  }

  static void signAndSendTransactionWithBiconomyAuto() async {
    final publicAddress = await ParticleAuth.getAddress();
    final transaction = await TransactionMock.mockEvmSendNative(publicAddress);

    final signature = await ParticleAuth.signAndSendTransaction(transaction,
        feeMode: BiconomyFeeMode.auto());
    log("signature $signature");
  }

  static void signAndSendTransactionWithBiconomyGasless() async {
    final publicAddress = await ParticleAuth.getAddress();
    final transaction = await TransactionMock.mockEvmSendNative(publicAddress);

    final signature = await ParticleAuth.signAndSendTransaction(transaction,
        feeMode: BiconomyFeeMode.gasless());
    log("signature $signature");
  }

  static void signAndSendTransactionWithBiconomyCustom() async {
    final publicAddress = await ParticleAuth.getAddress();
    final transaction = await TransactionMock.mockEvmSendNative(publicAddress);

    List<String> transactions = <String>[transaction];

    var result =
        await ParticleBiconomy.rpcGetFeeQuotes(publicAddress, transactions);

    var feeQuote = result[0];

    final signature = await ParticleAuth.signAndSendTransaction(transaction,
        feeMode: BiconomyFeeMode.custom(feeQuote));
    log("signature $signature");
  }

  static void loginParticle() async {
    final result =
        await ParticleAuth.login(LoginType.email, "", [SupportAuthType.all]);
    print(result);
  }

  static void loginMetamask() async {
    final result = await ParticleConnect.connect(WalletType.metaMask);
    print(result);
  }

  static void setChainInfo() async {
    final result = await ParticleAuth.setChainInfo(PolygonChain.mumbai());
    print(result);
  }

  static void batchSendTransactions() async {
    final publicAddress = await ParticleAuth.getAddress();
    final transaction = await TransactionMock.mockEvmSendNative(publicAddress);

    List<String> transactions = <String>[transaction, transaction];
    final signature = await ParticleAuth.batchSendTransactions(transactions,
        feeMode: BiconomyFeeMode.auto());
    log("signature $signature");
  }
}
