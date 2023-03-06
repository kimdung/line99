//
//  config.h
//  Line98
//
//  Created by Nguyen Minh Ngoc on 2015/09/07.
//  Copyright (c) 2015年 Nguyen Minh Ngoc. All rights reserved.
//

#ifndef Line98_config_h
#define Line98_config_h

#ifdef DEBUG
#define DLog(fmt, ...)  NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define DLog(fmt, ...) ;
#endif

#endif
