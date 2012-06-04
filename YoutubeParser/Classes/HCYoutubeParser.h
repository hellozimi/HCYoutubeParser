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

@interface HCYoutubeParser : NSObject

/**
 Method for retreiving a iOS supported video link
 
 @param youtubeURL the the complete youtube video url
 @return dictionary with the available formats for the selected video
 
 */
+ (NSDictionary *)h264videosWithYoutubeURL:(NSURL *)youtubeURL;

@end


@interface NSString (QueryString)

/**
 Parses a query string
 
 @return key value dictionary with each parameter as an array
 */
- (NSMutableDictionary *)dictionaryFromQueryStringComponents;


/**
 Convenient method for decoding a html encoded string
 */
- (NSString *)stringByDecodingURLFormat;

@end

@interface NSURL (QueryString)

/**
 Parses a query string of an NSURL
 
 @return key value dictionary with each parameter as an array
 */
- (NSMutableDictionary *)dictionaryForQueryString;

@end
