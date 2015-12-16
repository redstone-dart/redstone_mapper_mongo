library redstone_mongodb_service;

import 'package:redstone/redstone.dart';
import 'package:redstone_mapper/mapper.dart';
import 'package:redstone_mapper/plugin.dart';
import 'package:redstone_mapper_mongo/metadata.dart';
import 'package:redstone_mapper_mongo/service.dart';
import 'package:collection/equality.dart';

class User {
  @Id()
  String id;

  @Field()
  String username;

  @Field()
  String password;

  @ReferenceId()
  String resourceId;

  @ReferenceId()
  List<String> resourceIds;

  operator ==(other) {
    return other is User &&
        other.id == id &&
        other.username == username &&
        other.password == password &&
        other.resourceId == resourceId &&
        new ListEquality().equals(other.resourceIds, resourceIds);
  }

  toString() => "id: $id username: $username password: $password "
      "resourceId: $resourceId resourceIds: $resourceIds";
}

class TestObject {
  @Field()
  String id;

  @Field()
  String field;

  @Field()
  TestObject innerObj;
}

var _service = new MongoDbService<User>("user");

@Route("/find")
@Encode()
find() => _service.find();

@Route("/save", methods: const [POST])
save(@Decode() User user) => _service.save(user).then((_) => {"success": true});
