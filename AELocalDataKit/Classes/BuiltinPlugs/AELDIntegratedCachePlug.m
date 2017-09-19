//
//  AELDIntegratedCachePlug.m
//  Pods
//
//  Created by Altair on 19/09/2017.
//
//

#import "AELDIntegratedCachePlug.h"
#import "AELDMemoryCachePlug.h"
#import "AELDDiskCachePlug.h"
#import "AELDPlugMode.h"
#import "AELDResponse.h"

@interface AELDIntegratedCachePlug ()

@end

@implementation AELDIntegratedCachePlug

#pragma mark AELocalDataPlugProtocal

- (AELDPlugMode *)plugMode {
    return [AELDPlugMode modeWithName:NSStringFromClass([self class]) supportOperationType:AELDOperationTypeRead|AELDOperationTypeWrite|AELDOperationTypeDelete|AELDOperationTypeClear];
}

- (BOOL)startOperation:(AELDOperationMode *)mode response:(nonnull void (^)(AELDResponse * _Nonnull))response {
    if (!mode) {
        return NO;
    }
    AELDMemoryCachePlug *memoryCachePlug = [[AELocalDataSocket publicSocket] plugWithMode:[AELDPlugMode modeWithName:NSStringFromClass([AELDMemoryCachePlug class]) supportOperationType:AELDOperationTypeRead|AELDOperationTypeWrite|AELDOperationTypeDelete|AELDOperationTypeClear]];
    AELDDiskCachePlug *diskCachePlug = [[AELocalDataSocket publicSocket] plugWithMode:[AELDPlugMode modeWithName:NSStringFromClass([AELDMemoryCachePlug class]) supportOperationType:AELDOperationTypeRead|AELDOperationTypeWrite|AELDOperationTypeDelete|AELDOperationTypeClear]];
    if (!memoryCachePlug && !diskCachePlug) {
        return NO;
    }
    
    __block AELDResponse *operationResp = nil;
    //先操作内存缓存
    BOOL retValue = [memoryCachePlug startOperation:mode response:^(AELDResponse * _Nonnull resp) {
        operationResp = resp;
    }];
    if (retValue && !operationResp.error) {
        if (response) {
            response(operationResp);
        }
        return YES;
    }
    //如果内存缓存操作失败，则操作磁盘缓存
    retValue = [diskCachePlug startOperation:mode response:^(AELDResponse * _Nonnull resp) {
        operationResp = resp;
    }];
    if (response) {
        response(operationResp);
    }
    
    return YES;
}

- (BOOL)stopOperation {
    return YES;
}

@end
