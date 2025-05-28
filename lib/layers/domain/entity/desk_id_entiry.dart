import 'package:cloud_firestore/cloud_firestore.dart';

class DeskIdEntiry {
  String id;

  DeskIdEntiry({
    this.id = '',
  });

  factory DeskIdEntiry.fromJson(Map<String, dynamic> data) {
    return DeskIdEntiry(
      id: data['id'] = '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
      };
}
