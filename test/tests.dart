library mapper_mongodb_tests;

import 'dart:async';
import 'dart:convert' as conv;

import 'package:unittest/unittest.dart';
import 'package:mock/mock.dart';

import 'package:redstone/redstone.dart';

import 'package:connection_pool/connection_pool.dart';
import 'package:redstone_mapper/mapper_factory.dart';
import 'package:redstone_mapper_mongo/manager.dart';
import 'package:redstone_mapper/database.dart';
import 'package:redstone_mapper/plugin.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'redstone_service.dart';

class MockDb implements Db {

  var col = new MockDbCollection();
  
  @override
  DbCollection collection(String collectionName) {
    return col;
  }

  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockDbCollection extends Mock implements DbCollection {

  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockManagedConnection implements ManagedConnection {
  
  var _conn = new MockDb();
  
  @override
  get conn => _conn;

  @override
  int get connId => 1;
}

class MockCursor implements Cursor {

  List<Map> resp;
  
  MockCursor(this.resp);

  @override
  Future<List<Map>> toList() => new Future.value(resp);
  
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockMongoDbManager implements DatabaseManager<MongoDb> {
  
  MongoDb mongoDb;
  
  MockMongoDbManager(this.mongoDb);
  
  @override
  void closeConnection(MongoDb connection, {error}) {
  }

  @override
  Future<MongoDb> getConnection() {
    return new Future.value(mongoDb);
  }
}

main() {
  
  bootstrapMapper();
  
  var userObj = new User()
                  ..id = "53552802a1c800cf5172e724"
                  ..username = "user"
                  ..password = "1234"
                  ..resourceId = "54669d524ee3d652f7d0030d"
                  ..resourceIds = ["54669d524ee3d652f7d0030d", "54669d524ee3d652f7d0030d"];
  
  var userMap = {
    "_id": ObjectId.parse("53552802a1c800cf5172e724"),
    "username": "user",
    "password": "1234",
    "resourceId": ObjectId.parse("54669d524ee3d652f7d0030d"),
    "resourceIds": [ObjectId.parse("54669d524ee3d652f7d0030d"),
                    ObjectId.parse("54669d524ee3d652f7d0030d")]
  };
  
  MongoDb mongoDb;
  MockDbCollection mockCol;
  
  setUp(() {
    mongoDb = new MongoDb(new MockManagedConnection());
    mockCol = mongoDb.collection("");
  });
  
  test("Decode", () {
    mockCol.when(callsTo("find")).alwaysReturn(new MockCursor([userMap, userMap, userMap]));
    return mongoDb.find(mongoDb.collection("user"), User).then((users) {
      expect(users, equals([userObj, userObj, userObj]));
    });
  });
  
  test("Encode", () {
    var encodedUser;
    mockCol.when(callsTo("insert")).alwaysCall((document, {w}) {
      encodedUser = document;
      return new Future.value();
    });
    return mongoDb.insert(mongoDb.collection("user"), userObj).then((_) {
      mockCol.getLogs(callsTo("insert")).verify(happenedOnce);
      expect(encodedUser, equals(userMap));
    });
  });
  
  test("Encode: Update", () {
    var encodedData;
    mockCol.when(callsTo("update")).alwaysCall((selector, document, {upsert, multiUpdate, w}) {
      encodedData = document;
      return new Future.value();
    });
    
    var updtUser = new User()
                       ..username = 'new_username';
    var encodedUpdtUser = {'username': 'new_username'};
    
    var testObj = new TestObject()
                        ..id = "1"
                        ..field = "value1";
    testObj.innerObj = new TestObject()
                        ..field = "value2";
    testObj.innerObj.innerObj = new TestObject()
                            ..field = "value3";
    
    var encodedUpdtTestObj = {
      "id": "1",
      "field": "value1",
      "innerObj.field": "value2",
      "innerObj.innerObj.field": "value3"
    };
    
    return mongoDb.update(mongoDb.collection("user"), userMap, userObj).then((_) {
      expect(encodedData, equals(userMap));
    }).then((_) {
      return mongoDb.update(mongoDb.collection("user"), userMap, userObj, 
          override: false);
    }).then((_) {
      expect(encodedData, equals({r"$set": userMap}));
    }).then((_) {
      return mongoDb.update(mongoDb.collection("user"), userMap, updtUser, 
          override: false);
    }).then((_) {
      expect(encodedData, equals({r"$set": encodedUpdtUser}));
    }).then((_) {
      return mongoDb.update(mongoDb.collection("test"), {"id": 1}, testObj, 
          override: false);
    }).then((_) {
      expect(encodedData, equals({r"$set": encodedUpdtTestObj}));
    });
  });
  
  group("MongoDbService:", () {
    
    var userJson = {
      "id": "53552802a1c800cf5172e724",
      "username": "user",
      "password": "1234",
      "resourceId": "54669d524ee3d652f7d0030d",
      "resourceIds": ["54669d524ee3d652f7d0030d", "54669d524ee3d652f7d0030d"]
    };
    
    setUp(() async {
      var dbManager = new MockMongoDbManager(mongoDb);
      addPlugin(getMapperPlugin(dbManager));
      await redstoneSetUp([#redstone_mongodb_service]);
    });
    
    tearDown(redstoneTearDown);
    
    test("find", () {
      mockCol.when(callsTo("find")).alwaysReturn(new MockCursor([userMap, userMap, userMap]));

      var req = new MockRequest("/find");
      return dispatch(req).then((resp) {
        expect(resp.mockContent, equals(conv.JSON.encode([userJson, userJson, userJson])));
      });
    });
    
    test("save", () {
      var encodedUser;
      mockCol.when(callsTo("save")).alwaysCall((document, {w}) {
        encodedUser = document;
        return new Future.value();
      });
      
      var req = new MockRequest("/save", method: POST, 
          bodyType: JSON, body: userJson);
      return dispatch(req).then((resp) {
        mockCol.getLogs(callsTo("save")).verify(happenedOnce);
        expect(encodedUser, equals(userMap));
        expect(resp.mockContent, conv.JSON.encode({"success": true}));
      });
    });
  });
 
}