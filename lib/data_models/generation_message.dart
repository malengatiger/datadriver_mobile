class GenerationMessage {
  String? type;
  String? message;
  int? count;

  GenerationMessage({
    required this.type,
    required this.message,
    required this.count,
  });

  GenerationMessage.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    message = json['message'];
    count = json['count'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'message': message,
        'count': count,
      };
}
