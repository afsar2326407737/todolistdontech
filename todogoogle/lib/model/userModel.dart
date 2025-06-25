class Usermodel {
  String? id;
  String? name;
  String? email;
  String? phone;
  String? token;

  Usermodel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.token,
  });

  Usermodel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
    token = json['token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['phone'] = phone;
    data['token'] = token;
    return data;
  }
}
