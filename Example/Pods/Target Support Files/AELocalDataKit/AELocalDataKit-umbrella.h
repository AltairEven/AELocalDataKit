#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AELocalDataKit.h"
#import "AELDOperationMode.h"
#import "AELDPlugMode.h"
#import "AELDResponse.h"
#import "AELDCache.h"
#import "AELDDiskCache.h"
#import "AELDMemoryCache.h"
#import "AELDTools.h"
#import "AELocalDataSocket.h"

FOUNDATION_EXPORT double AELocalDataKitVersionNumber;
FOUNDATION_EXPORT const unsigned char AELocalDataKitVersionString[];

