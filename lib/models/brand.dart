class Brand {
  int? id;
  String? backendId;
  String? name;
  String? phone;
  String? email;

  Brand({this.name, this.phone, this.email});

  Brand.fromJson(Map<dynamic, dynamic> json){
    id = json["id"];
    name = json["name"];
    phone = json["brandPhone"] ?? json["phone"];
    email = json["email"];
  }

  Map<String, dynamic> toJson(){
    final map = <String, dynamic>{
      "id": id,
      "brandName": name,
    };
    if (phone != null) map["brandPhone"] = phone;
    if (email != null) map["email"] = email;
    return map;
  }
}