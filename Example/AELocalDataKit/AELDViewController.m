//
//  AELDViewController.m
//  AELocalDataKit
//
//  Created by AltairEven on 07/25/2017.
//  Copyright (c) 2017 AltairEven. All rights reserved.
//

#import "AELDViewController.h"
#import <AELocalDataKit/AELocalDataKit.h>

@interface AELDViewController ()

@property (nonatomic, strong) AELDMemoryCache *memCache;
@property (nonatomic, strong) AELDDiskCache *diskCache;

@property (weak, nonatomic) IBOutlet UILabel *cacheLabel;
@property (weak, nonatomic) IBOutlet UILabel *diskCacheLabel;

@end

@implementation AELDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.memCache = [AELDMemoryCache memoryCacheWithName:@"AltairEvenLocalDataMemoryCache" willEvictAction:^(AELDMemoryCache * _Nonnull cache, id  _Nonnull object) {
        NSLog(@"%@ will evict object with identifier:%@", cache.cacheName, [object aeld_CacheKey]);
    }];
    [self.memCache setCacheBytesLimit:1024*1024*50];
    [self.memCache setAutoClearExpectation:1024*1024*30];
    
    [self.memCache addObserver:self forKeyPath:@"currentUsage" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    
    //disk cache
    self.diskCache = [AELDDiskCache diskCacheWithName:@"ALtairEvenLocalDataDiskCache"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showDiskCacheInfo];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)dealloc {
    [self.memCache removeObserver:self forKeyPath:@"currentUsage"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma Memory Cache

- (IBAction)didClickedClearButton:(id)sender {
    [self.memCache removeAllObjects];
}

- (IBAction)didClickedAddButton:(id)sender {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@".plist"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSDate *start = [NSDate date];
    NSLog(@"Add memory cache start:%@", start);
    for (NSUInteger count = 0; count < 1024 * 10; count ++) {
        @autoreleasepool {
            //            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@".plist"];
            //            NSData *data = [NSData dataWithContentsOfFile:filePath];
            static NSUInteger memIndex = 0;
            memIndex ++;
            NSString *key = [NSString stringWithFormat:@"第%lu个缓存对象", (unsigned long)memIndex];
            
            [self.memCache setObject:data forKey:key];
        }
    }
    NSDate *finish = [NSDate date];
    NSLog(@"Add memory cache finished:%@, %f seconds elapsed.", finish, [finish timeIntervalSinceDate:start]);
}

- (IBAction)didClickedDeleteButton:(id)sender {
    NSDictionary<NSString *, id> *cachedObjects = [self.memCache allCachedObjects];
    [self.memCache removeObjectForKey:[[cachedObjects allKeys] firstObject]];
}

- (void)resetCacheLabel {
    [self.cacheLabel setText:[NSString stringWithFormat:@""]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ((object == self.memCache) && [keyPath isEqualToString:@"currentUsage"]) {
        [self.cacheLabel setText:[NSString stringWithFormat:@"内存缓存限制:%lu, 当前使用：%lu", (unsigned long)self.memCache.cacheBytesLimit, (unsigned long)self.memCache.currentUsage]];
    }
}

#pragma mark Disk Cache

- (IBAction)didClickedAddToDiskButton:(id)sender {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@".plist"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    static NSUInteger diskIndex = 0;
    diskIndex ++;
    NSString *key = [NSString stringWithFormat:@"第%lu个.缓存.对象", (unsigned long)diskIndex];
    
    [self.diskCache setObject:data forKey:key];
    [self showDiskCacheInfo];
}

- (IBAction)didClikedDeleteDiskCacheButton:(id)sender {
    NSDictionary<NSString *, id> *cachedObjects = [self.diskCache allCachedObjects];
    [self.diskCache removeObjectForKey:[[cachedObjects allKeys] firstObject]];
    [self showDiskCacheInfo];
}

- (IBAction)didClickedClearDiskCacheButton:(id)sender {
    [self.diskCache removeAllObjects];
    [self showDiskCacheInfo];
}

- (void)showDiskCacheInfo {
    NSDictionary *cachedObjects = [self.diskCache allCachedObjects];
    NSUInteger usage = [self.diskCache currentDiskUsage];
    
    [self.diskCacheLabel setText:[NSString stringWithFormat:@"磁盘缓存数量:%lu, 当前使用磁盘容量：%lu", (unsigned long)[cachedObjects count], (unsigned long)usage]];
}

@end
