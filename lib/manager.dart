library mongodb_manager;

import 'dart:async';

import 'package:redstone_mapper/database.dart';
import 'package:redstone_mapper/mapper.dart';
import 'package:connection_pool/connection_pool.dart';
import 'package:redstone_mapper_mongo/metadata.dart';
import 'package:mongo_dart/mongo_dart.dart';

///Manage connections with a MongoDB instance
class MongoDbManager implements DatabaseManager<MongoDb> {
  
  _MongoDbPool _pool;
  
  /**
   * Creates a new MongoDbManager
   * 
   * [uri] a MongoDB uri, and [poolSize] is the number of connections
   * that will be created.
   * 
   */ 
  MongoDbManager(String uri, {int poolSize: 3}) {
    _pool = new _MongoDbPool(uri, poolSize);
  }
  
  @override
  void closeConnection(MongoDb connection, {error}) {
    var invalidConn = error is ConnectionException;
    _pool.releaseConnection(
        connection._managedConn, 
        markAsInvalid: invalidConn);
  }

  @override
  Future<MongoDb> getConnection() {
    return _pool.getConnection().then((managedConn) =>
      new MongoDb(managedConn));
  }
}

/**
 * Wrapper for the MongoDb driver.
 * 
 * This class provides helper functions for
 * enconding query parameters and decoding query
 * results using redstone_mapper.
 * 
 */ 
class MongoDb {
  
  ManagedConnection _managedConn;
  
  MongoDb(this._managedConn);

  ///The original MongoDb connection object.
  Db get innerConn => _managedConn.conn;
  
  ///get a MongoDb collection
  DbCollection collection(String collectionName) {
    return innerConn.collection(collectionName);
  }
  
  ///Encode [data] to a Map or List.
  dynamic encode(dynamic data) =>
      _codec.encode(data);
  
  ///Decode [data] to one or more objects of type [type].
  dynamic decode(dynamic data, Type type) =>
      _codec.decode(data, type);

  /**
   * Wrapper for DbCollection.find().
   * 
   * [collection] is the MongoDb collection where the query will be executed,
   * and it can be a String or a DbCollection. [selector] can be a Map, a SelectorBuilder,
   * or an encodable object. The query result will be decoded to List<[type]>.
   */ 
  Future<List> find(dynamic collection, Type type, [dynamic selector]) {
    var dbCol = _collection(collection);
    if (selector != null && selector is! Map && selector is! SelectorBuilder) {
      selector = _codec.encode(selector);
    }
    return dbCol.find(selector).toList().then((result) =>
        _codec.decode(result, type));
  }
  
  /**
   * Wrapper for DbCollection.findOne().
   * 
   * [collection] is the MongoDb collection where the query will be executed,
   * and it can be a String or a DbCollection. [selector] can be a Map, a SelectorBuilder,
   * or an encodable object. The query result will be decoded to an object of type [type]
   */ 
  Future findOne(dynamic collection, Type type, [dynamic selector]) {
    var dbCol = _collection(collection);
    if (selector != null && selector is! Map && selector is! SelectorBuilder) {
      selector = _codec.encode(selector);
    }
    return dbCol.findOne(selector).then((result) =>
        _codec.decode(result, type));
  }
  
  /**
   * Wrapper for DbCollection.save().
   * 
   * [collection] is the MongoDb collection where the query will be executed,
   * and it can be a String or a DbCollection. [obj] is the object to be saved,
   * and can be a Map or an encodable object.
   */ 
  Future save(dynamic collection, Object obj) {
    var dbCol = _collection(collection);
    if (obj is! Map) {
      obj = _codec.encode(obj);
    }
    return dbCol.save(obj);
  }
  
  /**
   * Wrapper for DbCollection.insert().
   * 
   * [collection] is the MongoDb collection where the query will be executed,
   * and it can be a String or a DbCollection. [obj] is the object to be inserted,
   * and can be a Map or an encodable object.
   */ 
  Future insert(dynamic collection, Object obj) {
    var dbCol = _collection(collection);
    if (obj is! Map) {
      obj = _codec.encode(obj);
    }
    return dbCol.insert(obj);
  }
  
  /**
   * Wrapper for DbCollection.insertAll().
   * 
   * [collection] is the MongoDb collection where the query will be executed,
   * and it can be a String or a DbCollection. [objs] are the objects to be inserted,
   * and can be a list of maps, or a list of encodable objects.
   */ 
  Future insertAll(dynamic collection, List objs) {
    var dbCol = _collection(collection);
    return dbCol.insertAll(_codec.encode(objs));
  }
  
  /**
   * Wrapper for DbCollection.update().
   * 
   * [collection] is the MongoDb collection where the query will be executed,
   * and it can be a String or a DbCollection. [selector] can be a Map, a SelectorBuilder,
   * or an encodable object. [obj] is the object to be updated, and can be a Map, a 
   * ModifierBuilder or an encodable object. If [obj] is an encodable object and 
   * [override] is false, then the codec will produce a ModifierBuilder, and only
   * non null fields will be updated, otherwise, the entire document will be updated.
   */ 
  Future update(dynamic collection, dynamic selector, Object obj, {bool override: true, 
                                               bool upsert: false, 
                                               bool multiUpdate: false}) {
    var dbCol = _collection(collection);
    if (selector != null && selector is! Map && selector is! SelectorBuilder) {
      selector = _codec.encode(selector);
    }
    if (obj != null && obj is! Map && obj is! ModifierBuilder) {
      if (override) {
        obj = _codec.encode(obj);
      } else {
        obj = _updtCodec.encode(obj);
      }
    }
    return dbCol.update(selector, obj, 
          upsert: upsert, multiUpdate: multiUpdate);
  }
  
  /**
   * Wrapper for DbCollection.remove().
   * 
   * [collection] is the MongoDb collection where the query will be executed,
   * and it can be a String or a DbCollection. [selector] can be a Map, a SelectorBuilder,
   * or an encodable object.
   */ 
  Future remove(dynamic collection, dynamic selector) {
    var dbCol = _collection(collection);
    if (selector is! Map) {
      selector = _codec.encode(selector);
    }
    return dbCol.remove(selector);
  }
  
  DbCollection _collection(collection) {
    if (collection is String) {
      collection = innerConn.collection(collection);
    }
    return collection;
  }
}

class _MongoDbPool extends ConnectionPool<Db> {
  
  String uri;
  
  _MongoDbPool(String this.uri, int poolSize) : super(poolSize);
  
  @override
  void closeConnection(Db conn) {
    conn.close();
  }

  @override
  Future<Db> openNewConnection() {
    var conn = new Db(uri);
    return conn.open().then((_) => conn);
  }
}


FieldDecoder _fieldDecoder = (Object data, String fieldName, 
                              Field fieldInfo, List metadata) {
  String name = fieldInfo.model;
  if (name == null) {
    name = fieldName;
  }
  var value = (data as Map)[name];
  if (fieldInfo is Id || fieldInfo is ReferenceId) {
    if (value is ObjectId) {
      value = value.toHexString();
    } else if (value is List) {
      value = (value as List).map((o) => o.toHexString()).toList();
    }
  }
  return value;
};

FieldEncoder _fieldEncoder = (Map data, String fieldName, Field fieldInfo, 
                              List metadata, Object value) {
  String name = fieldInfo.model;
  if (name == null) {
    name = fieldName;
  }
  if (fieldInfo is Id || fieldInfo is ReferenceId) {
    if (value != null) {
      if (value is String) {
        value = ObjectId.parse(value);
        data[name] = value;
      } else if (value is List) {
        value = (value as List).map((o) => ObjectId.parse(o)).toList();
        data[name] = value;
      }
    }
  } else {
    data[name] = value;
  }
};

FieldEncoder _updtFieldEncoder = (Map data, String fieldName, Field fieldInfo, 
                                  List metadata, Object value) {
  if (value == null) {
   return;
  }
  String name = fieldInfo.model;
  if (name == null) {
    name = fieldName;
  }
  Map set = data[r'$set'];
  if (set == null) {
    set = {};
    data[r'$set'] = set;
  }
  if (fieldInfo is Id || fieldInfo is ReferenceId) {
    if (value is String) {
      value = ObjectId.parse(value);
      set[name] = value;
    } else if (value is List) {
      value = (value as List).map((o) => ObjectId.parse(o)).toList();
      set[name] = value;
    }
  } else {
    set[name] = value;
  }
};

GenericTypeCodec _codec = new GenericTypeCodec(fieldDecoder: _fieldDecoder, 
                                               fieldEncoder: _fieldEncoder);

GenericTypeCodec _updtCodec = new GenericTypeCodec(fieldEncoder: _updtFieldEncoder);
