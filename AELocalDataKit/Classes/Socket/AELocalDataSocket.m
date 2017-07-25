//
//  AELocalDataSocket.m
//  AELocalDataKit
//
//  Created by Altair on 21/06/2017.
//  Copyright © 2017 Altair. All rights reserved.
//

#import "AELocalDataSocket.h"
#import "AELDPlugMode.h"
#import "AELDResponse.h"

@implementation AELocalDataSocket

+ (instancetype)publicSocket {
    static AELocalDataSocket *sharedSocket = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSocket = [[AELocalDataSocket alloc] init];
    });
    return sharedSocket;
}

- (void)plugInBuiltInPlugs:(AELDBuiltInPlugStrategy)strategy {
    _builtInPlugStrategy = strategy;
    
//    if ((strategy & ALSUABuiltInPlugStrategyAutoLogin) == ALSUABuiltInPlugStrategyAutoLogin) {
//        [[ALSUASocket publicSocket] plugIn:[[ALSUAAutoLoginPlug alloc] init]];
//    }
//    if ((strategy & ALSUABuiltInPlugStrategyBindMobile) == ALSUABuiltInPlugStrategyBindMobile) {
//        [[ALSUASocket publicSocket] plugIn:[[ALSUABindMobilePhonePlug alloc] init]];
//    }
//    if ((strategy & ALSUABuiltInPlugStrategySetPassword) == ALSUABuiltInPlugStrategySetPassword) {
//        [[ALSUASocket publicSocket] plugIn:[[ALSUASetPasswordPlug alloc] init]];
//    }
//    if ((strategy & ALSUABuiltInPlugStrategyBaichuanLogin) == ALSUABuiltInPlugStrategyBaichuanLogin) {
//#ifdef ALSUABC_2
//        [[ALSUASocket publicSocket] plugIn:[[ALSUASecondPartyBaiChuanPlug alloc] init]];
//#else
//        [[ALSUASocket publicSocket] plugIn:[[ALSUAThirdPartyBaiChuanPlug alloc] init]];
//#endif
//    }
}

- (void)plugIn:(id<AELocalDataPlugProtocal>)plug {
    if (!plug || ![plug conformsToProtocol:@protocol(AELocalDataPlugProtocal)]) {
        return;
    }
    //由于可能会遇到插件自身属性的修改，所以先拔出已插入的相同数据操作模式的插件
    [self plugOutWithMode:[plug plugMode]];
    //将插件插入插座
    NSMutableSet *plugs = [self.plugsInSocket mutableCopy];
    if (!plugs) {
        plugs = [[NSMutableSet alloc] init];
    }
    [plugs addObject:plug];
    _plugsInSocket = [plugs copy];
}

- (void)plugOutWithMode:(AELDPlugMode *)mode {
    //获取指定数据操作模式的已插入插件
    id<AELocalDataPlugProtocal> plug = [self plugWithMode:mode];
    if (plug) {
        //如果存在，则将其从插座中拔出
        NSMutableSet *plugs = [self.plugsInSocket mutableCopy];
        [plugs removeObject:plug];
        _plugsInSocket = [plugs copy];
    }
}

- (id<AELocalDataPlugProtocal>)plugWithMode:(AELDPlugMode *)mode {
    __block id<AELocalDataPlugProtocal> plug = nil;
    //遍历插座上已插入的插件
    [self.plugsInSocket enumerateObjectsUsingBlock:^(id<AELocalDataPlugProtocal>  _Nonnull obj, BOOL * _Nonnull stop) {
        AELDPlugMode *plugMode = [obj plugMode];
        if ([plugMode isEqualToMode:mode]) {
            //如果插件的数据操作模式和比对的数据操作模式相同，则获取该插件，并停止遍历
            plug = obj;
            *stop = YES;
        }
    }];
    return plug;
}

- (id<AELocalDataPlugProtocal>)plugSupportedOperationWithMode:(AELDOperationMode *)mode {
    __block id<AELocalDataPlugProtocal> plug = nil;
    //遍历插座上已插入的插件
    [self.plugsInSocket enumerateObjectsUsingBlock:^(id<AELocalDataPlugProtocal>  _Nonnull obj, BOOL * _Nonnull stop) {
        AELDPlugMode *plugMode = [obj plugMode];
        if ([plugMode supportOperationMode:mode]) {
            //如果插件的数据操作模式和比对的数据操作模式相同，则获取该插件，并停止遍历
            plug = obj;
            *stop = YES;
        }
    }];
    return plug;
}

@end
