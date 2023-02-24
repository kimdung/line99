//
//  LNTextureCache.h
//  Line98
//
//  Created by Nguyen Minh Ngoc on 2015/08/31.
//  Copyright (c) 2015年 Nguyen Minh Ngoc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@interface LNTextureCache : NSObject

- (void)addTextureFromPlist:(NSString *)filename;
- (SKSpriteNode *)spriteWithCacheName:(NSString *)cacheName;
- (SKTexture*)textureWithCacheName:(NSString*)cacheName;
+ (id)sharedInstance;

@end
