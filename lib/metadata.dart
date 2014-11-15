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
 * This annotation binds specifically to the _id field of
 * MongoDB documents. To bind other fields, use the
 * [ReferenceId] annotation.
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

/**
 * A helper annotation to handle MongoDB ids.
 *
 * When decoding an object, this annotation instruct
 * the codec to convert ObjectId values to String.
 * The opposite is also true: when encoding, the value
 * will be converted back to ObjectId.
 *
 * This annotation can be used to bind any document field.
 * Although, to bind the _id field, you can also use th
 * [Id] annotation.
 *
 * Usage:
 *
 *      class User {
 *
 *        @Id()
 *        String id;
 *
 *        @Field()
 *        String name;
 *
 *        @ReferenceId()
 *        String resourceId;
 *
 *        //the field can also be a list
 *        @ReferenceId()
 *        List<String> resourceIds;
 *      }
 *
 *
 *
 */
class ReferenceId extends Field {

  const ReferenceId([String view, String model]) :
    super(view: view, model: model);

}