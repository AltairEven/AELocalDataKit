//
//  AELDResponse.m
//  AELocalDataKit
//
//  Created by Altair on 21/06/2017.
//  Copyright © 2017 Altair. All rights reserved.
//

#import "AELDResponse.h"

@implementation AELDResponse

- (instancetype)initWithOriginalMode:(AELDOperationMode *)originalMode {
    if (![originalMode isKindOfClass:[AELDOperationMode class]]) {
        return nil;
    }
    self = [self init];
    if (self) {
        _originalMode = originalMode;
    }
    return self;
}

@end
