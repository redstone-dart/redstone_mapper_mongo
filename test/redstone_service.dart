library redstone_mongodb_service;

import 'package:redstone/server.dart' as app;
import 'package:redstone_mapper/mapper.dart';
import 'package:redstone_mapper/plugin.dart';
import 'package:redstone_mapper_mongo/metadata.dart';
import 'package:redstone_mapper_mongo/service.dart';

class User {
  
  @Id()
  String id;
  
  @Field()
  String username;
  
  @Field()
  String password;
  
  operator == (other) {
    return other is User &&
           other.id == id &&
           other.username == username &&
           other.password == password;
  }
  
  toString() => "id: $id username: $username password: $password";
}

var _service = new MongoDbService<User>("user");

@app.Route("/find")
@Encode()
find() => _service.find();

@app.Route("/save", methods: const [app.POST])
save(@Decode() User user) =>
    _service.save(user).then((_) => {"success": true});