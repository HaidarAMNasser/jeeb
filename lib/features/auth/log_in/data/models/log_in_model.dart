class LogInModel {
  String? id;
  String? name;

  LogInModel({
    this.id,
    this.name,
  });

  factory LogInModel.fromJson(Map<String, dynamic> json) {
    return LogInModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
