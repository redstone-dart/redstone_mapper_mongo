library mongodb_service;

import 'dart:async';

import 'package:redstone/server.dart' as app;
import 'package:redstone_mapper_mongo/manager.dart';
import 'package:mongo_dart/mongo_dart.dart';

/**
 * Handles MongoDB operations for type T.
 * 
 * Usage:
 * 
 *      MongoDbService dbService = new MongoDbService<User>("users");
 * 
 *      @app.Route("/services/user/list")
 *      @Encode()
 *      Future<List<User>> listUsers() => dbService.find();
 * 
 *      @app.Route("/services/user/add")
 *      Future addUser(@Decode() User user) => 
 *          dbService.insert(user);
 * 
 * Also, it's possible to inherit from this class:
 * 
 *      @app.Group("/services/user")
 *      Class UserServices extends MongoDbService<User> {
 * 
 *        UserServices() : super("users");
 * 
 *        @app.Route("/list")
 *        @Encode()
 *        Future<List<User>> list() => find();
 *        
 *        @app.Route("/add")
 *        Future add(@Decode() User user) => insert(user);
 * 
 *      }
 * 
 * By default, the service will use the database connection
 * associated with the current http request. If you are not using
 * Redstone.dart, be sure to use the [MongoDbService.fromConnection] 
 * constructor to create a new service.
 * 
 */ 
class MongoDbService<T> {
  
  MongoDb _mongoDb = null;
  
  ///The name of the MongoDB collection associated with this service
  final String collectionName;
  
  ///The MongoDB connection wrapper
  MongoDb get mongoDb => 
      _mongoDb != null ? _mongoDb : app.request.attributes["dbConn"];
  
  ///The MongoDb connection
  Db get innerConn => mongoDb.innerConn;
  
  ///The MongoDB collection associated with this service
  DbCollection get collection => mongoDb.collection(collectionName);
  
  /**
   * Creates a new MongoDB service.
   * 
   * This service will use the database connection
   * associated with the current http request.
   */ 
  MongoDbService(this.collectionName);
  
  /**
   * Creates a new MongoDB service, using the provided
   * MongoDB connection.
   */
  MongoDbService.fromConnection(this._mongoDb, this.collectionName);
  
  /**
   * Wrapper for DbCollection.find().
   * 
   * [selector] can be a Map, a SelectorBuilder,
   * or an encodable object.
   */
  Future<List<T>> find([dynamic selector]) {
    return mongoDb.find(collection, T, selector);
  }
  
  /**
   * Wrapper for DbCollection.findOne().
   * 
   * [selector] can be a Map, a SelectorBuilder,
   * or an encodable object.
   */ 
  Future<T> findOne([dynamic selector]) {
    return mongoDb.findOne(collection, T, selector);
  }
  
  /**
   * Wrapper for DbCollection.save().
   * 
   * [obj] is the object to be saved.
   */ 
  Future save(T obj) {
    return mongoDb.save(collection, obj);
  }
  
  /**
   * Wrapper for DbCollection.insert().
   * 
   * [obj] is the object to be inserted.
   */ 
  Future insert(T obj) {
    return mongoDb.insert(collection, obj); 
  }
  
  /**
   * Wrapper for DbCollection.insertAll().
   * 
   * [objs] are the objectes to be inserted.
   */ 
  Future insertAll(List<T> objs) {
    return mongoDb.insertAll(collection, objs);
  }
  
  /**
   * Wrapper for DbCollection.update().
   * 
   * [selector] can be a Map, a SelectorBuilder,
   * or an encodable object. [obj] is the object to be updated, and 
   * if [override] is false, then only non null fields will be updated,
   * otherwise, the entire document will be replaced.
   */
  Future update(dynamic selector, T obj, {bool override: true, 
                                          bool upsert: false, 
                                          bool multiUpdate: false}) {
    return mongoDb.update(collection, selector, obj, 
        override: override, upsert: upsert, 
        multiUpdate: multiUpdate);
  }
  
  /**
   * Wrapper for DbCollection.remove().
   * 
   * [selector] can be a Map, a SelectorBuilder,
   * or an encodable object.
   */ 
  Future remove(dynamic selector) {
    return mongoDb.save(collection, selector);
  }
}