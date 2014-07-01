library mongodb_metadata;

import 'package:redstone_mapper/mapper.dart';

/**
 * A helper annotation to handle MongoDB ids.
 * 
 * When decoding an object, this annotation instruct
 * the codec to convert ObjectId values to String. 
 * The opposite is also true: when encoding, the value
 * will be converted back to ObjectId.
 * 
 * Usage:
 * 
 *      class User {
 *        
 *        //same as @Field(model: "_id") ObjectId id;
 *        @Id()
 *        String id;
 * 
 *        @Field()
 *        String name;
 *        
 *      }
 *  
 * 
 * 
 */ 
class Id extends Field {
  
  const Id([String view]) :
    super(view: view, model: "_id");
  
}