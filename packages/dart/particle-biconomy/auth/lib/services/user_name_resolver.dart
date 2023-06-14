import 'dart:developer';

import 'package:auth/utils/constants.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';

Uint8List convertStringToUint8List(String str) {
  final slicedStr = str.replaceAll('0x', '').substring(0, 32);
  // String? 32bytes = slicedStr.substring(0,32);
  log(' $slicedStr');
  final List<int> codeUnits = slicedStr.codeUnits;

  final Uint8List unit8List = Uint8List.fromList(codeUnits);

  return unit8List;
}

Future<String?> loadNameResolverContract(
    Web3Client? client, String hash) async {
  String? address;
  String? abi =
      await rootBundle.loadString('assets/abis/user_name_resolver.json');
  if (abi != null) {
    log(abi.toString());
    String contractAddress = Constants.usernameResolverContract;
    final contract = DeployedContract(
      ContractAbi.fromJson(abi, 'UsernamesResolver'),
      EthereumAddress.fromHex(contractAddress),
    );
    // log(Constants.usernameResolverContract);
    final funcAddr = contract.function('addr');
    log('log this: $hash');
    final addr = await client!.call(
        contract: contract,
        function: funcAddr,
        params: [convertStringToUint8List(hash)]);
    log('my Address${addr.toString().replaceAll('[', '').replaceAll(']', '')}');
    address = addr.toString().replaceAll('[', '').replaceAll(']', '');
    
  }
  return address;
}
