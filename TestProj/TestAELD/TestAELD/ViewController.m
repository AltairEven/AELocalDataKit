//
//  ViewController.m
//  TestAELD
//
//  Created by Altair on 26/06/2017.
//  Copyright © 2017 Altair. All rights reserved.
//

#import "ViewController.h"
#import <AELocalDataKit/AELocalDataKit.h>

@interface ViewController ()

@property (nonatomic, strong) AELDMemoryCache *cache;

@property (weak, nonatomic) IBOutlet UILabel *cacheLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.cache = [AELDMemoryCache memoryCacheWithName:@"AltairEvenLocalDataMemoryCache" evictAction:^(AELDMemoryCache * _Nonnull cache, id  _Nonnull object) {
        NSLog(@"%@ will evict object with identifier:%@", cache.cacheName, [object aeld_CacheIdentifier]);
    }];
    [self.cache setCacheBytesLimit:1024*1024*50];
    [self.cache setAutoClearExpectation:1024*1024*30];
    
    [self.cache addObserver:self forKeyPath:@"currentUsage" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
}

- (void)dealloc {
    [self.cache removeObserver:self forKeyPath:@"currentUsage"];
}

- (IBAction)didClickedClearButton:(id)sender {
    [self.cache removeAllObjects];
}

- (IBAction)didClickedAddButton:(id)sender {
    for (NSUInteger count = 0; count < 1024 * 10; count ++) {
        @autoreleasepool {
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@".plist"];
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            static NSUInteger index = 0;
            index ++;
            data.aeld_CacheIdentifier = [NSString stringWithFormat:@"第%lu个缓存对象", (unsigned long)index];
            
            [self.cache addObject:data];
        }
    }
}

- (IBAction)didClickedDeleteButton:(id)sender {
    NSDictionary<NSString *, id> *cachedObjects = [self.cache allCachedObjects];
    [self.cache removeObjectWithCacheIdentifier:[[cachedObjects allKeys] firstObject]];
}

- (void)resetCacheLabel {
    [self.cacheLabel setText:[NSString stringWithFormat:@""]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"currentUsage"]) {
        [self.cacheLabel setText:[NSString stringWithFormat:@"缓存限制:%lu, 当前使用：%lu", (unsigned long)self.cache.cacheBytesLimit, (unsigned long)self.cache.currentUsage]];
    }
}

@end
