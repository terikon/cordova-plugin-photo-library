//
//  ObjCTryCatch.h
//  ObjCTryCatch
//
//  Created by jbrooks on 3/23/16.
//  Copyright © 2016 jbrooks. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for ObjCTryCatch.
FOUNDATION_EXPORT double ObjCTryCatchVersionNumber;

//! Project version string for ObjCTryCatch.
FOUNDATION_EXPORT const unsigned char ObjCTryCatchVersionString[];

@interface ObjCTry <__covariant T>: NSObject

/**
 * wraps `block` in an Objective C try block, catching any exceptions
 * and returning them in the user info of the returned error.  This will
 * import into swift as a throwing function that throws the error.
 */
+ (BOOL)doTry:(void(^)())block error:(NSError **)err;

/**
 * Same as above, but used for blocks that produce an Objective C object.
 */
+ (T)doTryObj:(T(^)())block error:(NSError **)err;

@end
