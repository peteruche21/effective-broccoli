class CreateAccountModel {
  int? status;
  Data? data;

  CreateAccountModel({this.status, this.data});

  CreateAccountModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  Map<String, dynamic>();
    data['status'] = this.status;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? email;
  int? id;
  SecurityAccount? securityAccount;
  String? token;
  String? updatedAt;
  String? uuid;
  List<Wallets>? wallets;
  String? redirectType;

  Data(
      {this.email,
      this.id,
      this.securityAccount,
      this.token,
      this.updatedAt,
      this.uuid,
      this.wallets,
      this.redirectType});

  Data.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    id = json['id'];
    securityAccount = json['security_account'] != null
        ? new SecurityAccount.fromJson(json['security_account'])
        : null;
    token = json['token'];
    updatedAt = json['updated_at'];
    uuid = json['uuid'];
    if (json['wallets'] != null) {
      wallets = <Wallets>[];
      json['wallets'].forEach((v) {
        wallets!.add(new Wallets.fromJson(v));
      });
    }
    redirectType = json['redirect_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['email'] = this.email;
    data['id'] = this.id;
    if (this.securityAccount != null) {
      data['security_account'] = this.securityAccount!.toJson();
    }
    data['token'] = this.token;
    data['updated_at'] = this.updatedAt;
    data['uuid'] = this.uuid;
    if (this.wallets != null) {
      data['wallets'] = this.wallets!.map((v) => v.toJson()).toList();
    }
    data['redirect_type'] = this.redirectType;
    return data;
  }
}

class SecurityAccount {
  bool? hasSetMasterPassword;
  bool? hasSetPaymentPassword;

  SecurityAccount({this.hasSetMasterPassword, this.hasSetPaymentPassword});

  SecurityAccount.fromJson(Map<String, dynamic> json) {
    hasSetMasterPassword = json['has_set_master_password'];
    hasSetPaymentPassword = json['has_set_payment_password'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['has_set_master_password'] = this.hasSetMasterPassword;
    data['has_set_payment_password'] = this.hasSetPaymentPassword;
    return data;
  }
}

class Wallets {
  String? chainName;
  String? publicAddress;
  String? uuid;

  Wallets({this.chainName, this.publicAddress, this.uuid});

  Wallets.fromJson(Map<String, dynamic> json) {
    chainName = json['chain_name'];
    publicAddress = json['public_address'];
    uuid = json['uuid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['chain_name'] = this.chainName;
    data['public_address'] = this.publicAddress;
    data['uuid'] = this.uuid;
    return data;
  }
}
