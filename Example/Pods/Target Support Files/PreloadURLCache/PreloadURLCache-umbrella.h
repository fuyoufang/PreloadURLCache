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

#import "NSURLProtocol+WKWebView.h"

FOUNDATION_EXPORT double PreloadURLCacheVersionNumber;
FOUNDATION_EXPORT const unsigned char PreloadURLCacheVersionString[];

