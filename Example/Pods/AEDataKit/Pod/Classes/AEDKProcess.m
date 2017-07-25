//
//  AEDKProcess.m
//  AEDataKit
//
//  Created by Altair on 10/07/2017.
//  Copyright © 2017 Altair. All rights reserved.
//

#import "AEDKProcess.h"
#import "AEDKServer.h"
#import "AEDKServiceConfiguration.h"

@implementation AEDKProcess

#pragma mark Private methods

- (void)setState:(AEDKProcessState)state {
    @synchronized (self) {
        if (_state != state)
        {
            NSString * keyPath1 = [self keyPathFromProcessState:_state];
            NSString * keyPath2 = [self keyPathFromProcessState:state];
            if (![keyPath1 isEqualToString:keyPath2]) {
                [self willChangeValueForKey:keyPath1];
                _state = state;
                [self didChangeValueForKey:keyPath2];
            }
        }
    }
}


- (NSString *)keyPathFromProcessState:(AEDKProcessState)state {
    switch (state) {
        case AEDKProcessStateReady:
        {
            return @"isReady";
        }
            break;
        case AEDKProcessStateProcessing:
        {
            return @"isExecuting";
        }
            break;
        case AEDKProcessStateSuspended: {
            return @"isSuspended";
        }
        case AEDKProcessStateCompleted:
        {
            return @"isFinished";
        }
            break;
        case AEDKProcessStateCanceling:
        {
            return @"isCancelled";
        }
            break;
        default:
            break;
    }
    return @"state";
}


#pragma mark Public methods

#pragma mark Super methods

- (void)main {
    NSArray<id<AEDKPlugProtocol>> *delegates = [[AEDKServer server] allDelegates];
    BOOL hasDelegate = NO;
    for (id<AEDKPlugProtocol> delegate in delegates) {
        if ([delegate canHandleProcess:self]) {
            [self setState:AEDKProcessStateReady];
            [delegate handleProcess:self];
            hasDelegate = YES;
            break;
        }
    }
    if (!hasDelegate) {
        [self cancel];
    }
}

- (void)cancel {
    [super cancel];
    if (self.configuration.ProcessCompleted) {
        __weak typeof(self) weakSelf = self;
        NSError *error = [NSError errorWithDomain:@"AEDataKit-process" code:AEDK_ERROR_CANCEL userInfo:@{NSLocalizedDescriptionKey : @"没有找到合适的请求代理"}];
        self.configuration.ProcessCompleted(weakSelf, error, nil);
    }
}

@end
