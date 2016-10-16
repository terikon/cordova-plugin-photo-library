//
//  ObjCTryCatch.m
//  ObjCTryCatch
//
//  Created by jbrooks on 3/23/16.
//  Copyright © 2016 jbrooks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObjCTryCatch.h"

@implementation ObjCTry

+ (BOOL)doTry:(void(^)())block error:(NSError **)err {
    @try {
        block();
        return YES;
    }
    @catch (NSException *exception) {
        *err = [NSError errorWithDomain:@"todo" code:1 userInfo:@{@"exception": exception}];
    }
    return NO;
}

+ (id)doTryObj:(id(^)())block error:(NSError **)err {
    @try {
        return block();
    }
    @catch (NSException *exception) {
        *err = [NSError errorWithDomain:@"todo" code:1 userInfo:@{@"exception": exception}];
    }
    return nil;
}


@end
