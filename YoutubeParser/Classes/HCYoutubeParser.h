//
//  HCYoutube.h
//  YoutubeParser
//
//  Created by Simon Andersson on 6/4/12.
//  Copyright (c) 2012 Hiddencode.me. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//  
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import <Foundation/Foundation.h>
#if	TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#if TARGET_OS_IPHONE
#define HCImage UIImage
#else
#define HCImage NSImage
#endif

typedef enum {
    YouTubeThumbnailDefault,
    YouTubeThumbnailDefaultMedium,
    YouTubeThumbnailDefaultHighQuality,
    YouTubeThumbnailDefaultMaxQuality
} YouTubeThumbnail;

@interface HCYoutubeParser : NSObject

/**
 Method for retrieving the youtube ID from a youtube URL
 
 @param youtubeURL the the complete youtube video url, either youtu.be or youtube.com
 @return string with desired youtube id
 */
+ (nullable NSString *)youtubeIDFromYoutubeURL:(nullable NSURL *)youtubeURL;

/**
 Method for retreiving a iOS supported video link
 
 @param youtubeURL the the complete youtube video url
 @return dictionary with the available formats for the selected video
 
 */
+ (nullable NSDictionary *)h264videosWithYoutubeURL:(nullable NSURL *)youtubeURL;

/**
 Method for retreiving an iOS supported video link
 
 @param youtubeID the id of the youtube video
 @return dictionary with the available formats for the selected video
 
 */
+ (nullable NSDictionary *)h264videosWithYoutubeID:(nullable NSString *)youtubeID;

/**
 Block based method for retreiving a iOS supported video link
 
 @param youtubeURL the the complete youtube video url
 @param completeBlock the block which is called on completion
 
 */
+ (void)h264videosWithYoutubeURL:(nullable NSURL *)youtubeURL
                   completeBlock:(nonnull void(^)( NSDictionary * _Nullable videoDictionary, NSError * _Nullable error))completeBlock;

/**
 Method for retreiving a thumbnail url for wanted youtube id
 
 @param youtubeURL the complete youtube video id
 @param thumbnailSize the wanted size of the thumbnail
 */
+ (nullable NSURL *)thumbnailUrlForYoutubeURL:(nullable NSURL *)youtubeURL
                         thumbnailSize:(YouTubeThumbnail)thumbnailSize;

/**
 Method for retreiving a thumbnail for wanted youtube url
 
 @param youtubeURL the the complete youtube video url
 @param thumbnailSize the wanted size of the thumbnail
 @param completeBlock the block which is called on completion
 */
+ (void)thumbnailForYoutubeURL:(nullable NSURL *)youtubeURL
				 thumbnailSize:(YouTubeThumbnail)thumbnailSize
				 completeBlock:(nonnull void(^)(HCImage * _Nullable image, NSError * _Nullable error))completeBlock;

/**
 Method for retreiving a thumbnail for wanted youtube id
 
 @param youtubeURL the complete youtube video id
 @param thumbnailSize the wanted size of the thumbnail
 @param completeBlock the block which is called on completion
 */
+ (void)thumbnailForYoutubeID:(nullable NSString *)youtubeID
				thumbnailSize:(YouTubeThumbnail)thumbnailSize
				completeBlock:(nonnull void(^)(HCImage * _Nullable image, NSError * _Nullable error))completeBlock;


/**
 Method for retreiving all the details of a youtube video
 
 @param youtubeURL the the complete youtube video url
 @param completeBlock the block which is called on completion
 
 */
+ (void)detailsForYouTubeURL:(nullable NSURL *)youtubeURL
               completeBlock:(nonnull void(^)(NSDictionary * _Nullable details, NSError * _Nullable error))completeBlock;
@end
