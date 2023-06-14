import 'dart:developer';

import 'package:auth/services/user_name_resolver.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';

import '../utils/constants.dart';

Future<String?> loadNameResolverContract(
    Web3Client? client, String hash) async {
  String? address;
  String? abi =
      await rootBundle.loadString('assets/abis/user_name_controller.json');
  if (abi != null) {
    log(abi.toString());
    String contractAddress = Constants.usernamesRegistrarController;
    final contract = DeployedContract(
      ContractAbi.fromJson(abi, 'UsernamesRegistrarController'),
      EthereumAddress.fromHex(contractAddress),
    );
    // log(Constants.usernameResolverContract);
    final funcAddr = contract.function('register');
    log('log this: $hash');
    final addr = await client!.call(
        contract: contract,
        function: funcAddr,
        params: []);
    // log('my Address${addr.toString().replaceAll('[', '').replaceAll(']', '')}');
    // address = addr.toString().replaceAll('[', '').replaceAll(']', '');
    
  }
  return address;
}