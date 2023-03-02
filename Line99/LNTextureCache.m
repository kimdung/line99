//
//  LNTextureCache.m
//  Line98
//
//  Created by Nguyen Minh Ngoc on 2015/08/31.
//  Copyright (c) 2015年 Nguyen Minh Ngoc. All rights reserved.
//

#import "LNTextureCache.h"
#import "config.h"
#import "LNTextureCache.h"

@interface LNTextureCache ()
{
    NSMutableArray *_allTextures;
    NSMutableDictionary *_textures;
}
@end

static LNTextureCache *__shared;

@implementation LNTextureCache

- (id)init
{
    self = [super init];
    if (self) {
        _allTextures = [[NSMutableArray alloc] init];
        _textures = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (id)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __shared = [[LNTextureCache alloc] init];
    });
    return __shared;
}

- (NSString *)plistPathForBaseName:(NSString *)baseName
{
    NSString *ipadSuffix = @"";
    NSString *hdSuffix = @"";
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        ipadSuffix = @"-ipad";
    }

    if ([[UIScreen mainScreen] scale] > 1.0) {
        hdSuffix = @"-hd";
    }

    NSString *fileName = [NSString stringWithFormat:@"%@%@%@", baseName, ipadSuffix, hdSuffix];
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"plist"];

    if (!path && [ipadSuffix length]) {
        fileName = [NSString stringWithFormat:@"%@%@", baseName, hdSuffix];
        path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"plist"];
    }

    if (!path && [hdSuffix length]) {
        fileName = [NSString stringWithFormat:@"%@%@", baseName, ipadSuffix];
        path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"plist"];
    }

    if (!path) {
        path = [[NSBundle mainBundle] pathForResource:baseName ofType:@"plist"];
    }


    return path;
}

- (void)addTextureFromPlist:(NSString *)filename
{
    NSString *fileName = [filename componentsSeparatedByString:@"."][0];
    NSString *plistPath = [self plistPathForBaseName:fileName];

    NSDictionary *textureInfo = [NSDictionary dictionaryWithContentsOfFile:plistPath];

    if (textureInfo) {

        NSString *imageName = [textureInfo[@"metadata"][@"textureFileName"] stringByDeletingPathExtension];

        NSData *imageData = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:imageName ofType:@"png"]];
        UIImage *texImage = [UIImage imageWithData:imageData];

        SKTexture *bulkTexture = [SKTexture textureWithImage:texImage];
        NSDictionary *info = @{@"texture":bulkTexture, @"frames":textureInfo[@"frames"]};
        [_allTextures addObject:info];
    } else {
        DLog(@"Could not load resource %@", fileName);
    }
}

- (SKSpriteNode *)spriteWithCacheName:(NSString *)cacheName {
    SKTexture *foundTexture = nil;
    NSString *frameRectString = nil;

    for (NSDictionary *i in _allTextures) {
        NSDictionary *frameNames = i[@"frames"];
        if ([[frameNames allKeys] containsObject:cacheName]) {
            foundTexture = i[@"texture"];
            frameRectString = frameNames[cacheName][@"frame"];
            break;
        }
    }
    SKSpriteNode *sprite = nil;
    if (foundTexture && frameRectString) {
        CGRect sampleRect = CGRectFromString(frameRectString);
        CGRect textureRect = sampleRect;

        textureRect.size.width = textureRect.size.width/foundTexture.size.width;
        textureRect.size.height = textureRect.size.height/foundTexture.size.height;
        textureRect.origin.x =  (textureRect.origin.x/foundTexture.size.width);
        textureRect.origin.y =  1 - (textureRect.origin.y/foundTexture.size.height) - textureRect.size.height;

        CGFloat factor =  1.0/[[UIScreen mainScreen] scale];

        sampleRect = CGRectApplyAffineTransform(sampleRect, CGAffineTransformMakeScale(factor, factor));

        SKTexture *subTex = [SKTexture textureWithRect:textureRect inTexture:foundTexture];

        sprite = [SKSpriteNode spriteNodeWithTexture:subTex size:sampleRect.size];

    }
    return sprite;
}

- (SKTexture*)textureWithCacheName:(NSString*)cacheName {
    SKTexture *foundTexture = nil;
    NSString *frameRectString = nil;

    for (NSDictionary *i in _allTextures) {
        NSDictionary *frameNames = i[@"frames"];
        if ([[frameNames allKeys] containsObject:cacheName]) {
            foundTexture = i[@"texture"];
            frameRectString = frameNames[cacheName][@"frame"];
            break;
        }
    }

    SKTexture *subTex = nil;
    if (foundTexture && frameRectString) {
        CGRect sampleRect = CGRectFromString(frameRectString);
        CGRect textureRect = sampleRect;

        textureRect.size.width = textureRect.size.width/foundTexture.size.width;
        textureRect.size.height = textureRect.size.height/foundTexture.size.height;
        textureRect.origin.x =  (textureRect.origin.x/foundTexture.size.width);
        textureRect.origin.y =  1 - (textureRect.origin.y/foundTexture.size.height) - textureRect.size.height;

        CGFloat factor =  1.0/[[UIScreen mainScreen] scale];

        sampleRect = CGRectApplyAffineTransform(sampleRect, CGAffineTransformMakeScale(factor, factor));

        subTex = [SKTexture textureWithRect:textureRect inTexture:foundTexture];
    }
    return subTex;
}

@end
