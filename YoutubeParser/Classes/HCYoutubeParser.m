//
//  HCYoutube.m
//  YoutubeParser
//
//  Created by Simon Andersson on 6/4/12.
//  Copyright (c) 2012 Hiddencode.me. All rights reserved.
//

#import "HCYoutubeParser.h"

#define kYoutubeInfoURL      @"http://www.youtube.com/get_video_info?video_id="
#define kYoutubeThumbnailURL @"http://img.youtube.com/vi/%@/%@.jpg"
#define kYoutubeDataURL      @"http://gdata.youtube.com/feeds/api/videos/%@?alt=json"
#define kUserAgent @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.79 Safari/537.4"

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


@implementation NSString (QueryString)

- (NSString *)stringByDecodingURLFormat {
    NSString *result = [self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

- (NSMutableDictionary *)dictionaryFromQueryStringComponents {

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    for (NSString *keyValue in [self componentsSeparatedByString:@"&"]) {
        NSArray *keyValueArray = [keyValue componentsSeparatedByString:@"="];
        if ([keyValueArray count] < 2) {
            continue;
        }

        NSString *key = [[keyValueArray objectAtIndex:0] stringByDecodingURLFormat];
        NSString *value = [[keyValueArray objectAtIndex:1] stringByDecodingURLFormat];

        NSMutableArray *results = [parameters objectForKey:key];

        if(!results) {
            results = [NSMutableArray arrayWithCapacity:1];
            [parameters setObject:results forKey:key];
        }

        [results addObject:value];
    }

    return parameters;
}

@end

@implementation NSURL (QueryString)

- (NSMutableDictionary *)dictionaryForQueryString {
    return [[self query] dictionaryFromQueryStringComponents];
}

@end

@interface HCYoutubeParser()
@property (nonatomic, strong) NSOperationQueue *youtubeRequestQueue;

@end

@implementation HCYoutubeParser
static NSString * kHCYoutubeParserQueueOperationCountChanged = @"queue operationcount changed";

+ (HCYoutubeParser *)sharedInstance {
    static HCYoutubeParser *sharedInstance;
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[HCYoutubeParser alloc] init];
        }
    }
    return sharedInstance;
}

- (id)init {
	self = [super init];
	if (self) {
		_youtubeRequestQueue = [[NSOperationQueue alloc] init];
		_youtubeRequestQueue.maxConcurrentOperationCount = 2;
		[_youtubeRequestQueue addObserver:self forKeyPath:@"operationCount" options:0 context:&kHCYoutubeParserQueueOperationCountChanged];
	}
	return self;
}

- (void) observeValueForKeyPath:(NSString *)keyPath
					   ofObject:(id)object
                         change:(NSDictionary *)change
						context:(void *)context {
    if (context == &kHCYoutubeParserQueueOperationCountChanged
		&& object == self.youtubeRequestQueue
		&& [keyPath isEqualToString:@"operationCount"])
	{
        if (self.youtubeRequestQueue.operationCount == 0) {
			if (self.queueCompletionBlock) {
				self.queueCompletionBlock(self.youtubeRequestQueue);
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName:kHCYoutubeParserQueueCompleted
																object:nil
															  userInfo:@{@"queue" : self.youtubeRequestQueue}];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}

- (void)setMaxConcurrentOperationCount:(NSUInteger)operationCount {
	self.youtubeRequestQueue.maxConcurrentOperationCount = operationCount;
}

+ (NSString *)youtubeIDFromYoutubeURL:(NSURL *)youtubeURL {
    NSString *youtubeID = nil;
    if ([youtubeURL.host isEqualToString:@"youtu.be"]) {
        youtubeID = [[youtubeURL pathComponents] objectAtIndex:1];
    } else {
        youtubeID = [[[youtubeURL dictionaryForQueryString] objectForKey:@"v"] objectAtIndex:0];
    }
    
    return youtubeID;
}

+ (NSDictionary *)h264videosWithYoutubeID:(NSString *)youtubeID {
    if (youtubeID) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kYoutubeInfoURL, youtubeID]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
        [request setHTTPMethod:@"GET"];
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (!error) {
            NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            
            NSMutableDictionary *parts = [responseString dictionaryFromQueryStringComponents];
            
            if (parts) {
                
                NSString *fmtStreamMapString = [[parts objectForKey:@"url_encoded_fmt_stream_map"] objectAtIndex:0];
                NSArray *fmtStreamMapArray = [fmtStreamMapString componentsSeparatedByString:@","];
                
                NSMutableDictionary *videoDictionary = [NSMutableDictionary dictionary];
                
                for (NSString *videoEncodedString in fmtStreamMapArray) {
                    NSMutableDictionary *videoComponents = [videoEncodedString dictionaryFromQueryStringComponents];
                    NSString *type = [[[videoComponents objectForKey:@"type"] objectAtIndex:0] stringByDecodingURLFormat];
                    NSString *signature = nil;
                    if ([videoComponents objectForKey:@"sig"]) {
                        signature = [[videoComponents objectForKey:@"sig"] objectAtIndex:0];
                    }
                    
                    if ([type rangeOfString:@"mp4"].length > 0) {
                        NSString *url = [[[videoComponents objectForKey:@"url"] objectAtIndex:0] stringByDecodingURLFormat];
                        url = [NSString stringWithFormat:@"%@&signature=%@", url, signature];
                        
                        NSString *quality = [[[videoComponents objectForKey:@"quality"] objectAtIndex:0] stringByDecodingURLFormat];
                        
                        [videoDictionary setObject:url forKey:quality];
                    }
                }
                
                return videoDictionary;
            }
        }
    }
    
    return nil;
}

+ (NSDictionary *)h264videosWithYoutubeURL:(NSURL *)youtubeURL {

    NSString *youtubeID = [self youtubeIDFromYoutubeURL:youtubeURL];
    return [self h264videosWithYoutubeID:youtubeID];
}

+ (void)h264videosWithYoutubeURL:(NSURL *)youtubeURL
                   completeBlock:(void(^)(NSDictionary *videoDictionary, NSError *error))completeBlock {
	HCYoutubeParser *ytParser = [HCYoutubeParser sharedInstance];
	[ytParser h264videosWithYoutubeURL:youtubeURL completeBlock:completeBlock];
}

- (void)h264videosWithYoutubeURL:(NSURL *)youtubeURL
                   completeBlock:(void(^)(NSDictionary *videoDictionary, NSError *error))completeBlock {
    
    NSString *youtubeID = [HCYoutubeParser youtubeIDFromYoutubeURL:youtubeURL];
    
    if (youtubeID)
    {
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kYoutubeInfoURL, youtubeID]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
        [request setHTTPMethod:@"GET"];
        
        [NSURLConnection sendAsynchronousRequest:request queue:self.youtubeRequestQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (!error)
            {
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

                NSMutableDictionary *parts = [responseString dictionaryFromQueryStringComponents];
                
                if (parts)
                {
                    
                    NSString *fmtStreamMapString = [[parts objectForKey:@"url_encoded_fmt_stream_map"] objectAtIndex:0];
                    NSArray *fmtStreamMapArray = [fmtStreamMapString componentsSeparatedByString:@","];
                    
                    NSMutableDictionary *videoDictionary = [NSMutableDictionary dictionary];
                    
                    for (NSString *videoEncodedString in fmtStreamMapArray)
                    {
                        NSMutableDictionary *videoComponents = [videoEncodedString dictionaryFromQueryStringComponents];
                        NSString *type = [[[videoComponents objectForKey:@"type"] objectAtIndex:0] stringByDecodingURLFormat];
                        NSString *signature = nil;
                        if ([videoComponents objectForKey:@"sig"]) {
                            signature = [[videoComponents objectForKey:@"sig"] objectAtIndex:0];
                        }
                        
                        if ([type rangeOfString:@"mp4"].length > 0) {
                            NSString *url = [[[videoComponents objectForKey:@"url"] objectAtIndex:0] stringByDecodingURLFormat];
                            url = [NSString stringWithFormat:@"%@&signature=%@", url, signature];
                            
                            NSString *quality = [[[videoComponents objectForKey:@"quality"] objectAtIndex:0] stringByDecodingURLFormat];
                            
                            [videoDictionary setObject:url forKey:quality];
                        }
                    }
                    
                    completeBlock(videoDictionary, nil);
                }
            }
            else
            {
                completeBlock(nil, error);
            }
        }];
    }
}

+ (void)thumbnailForYoutubeURL:(NSURL *)youtubeURL
                 thumbnailSize:(YouTubeThumbnail)thumbnailSize
                 completeBlock:(void(^)(UIImage *image, NSError *error))completeBlock {
    
    NSString *youtubeID = [self youtubeIDFromYoutubeURL:youtubeURL];
    return [self thumbnailForYoutubeID:youtubeID thumbnailSize:thumbnailSize completeBlock:completeBlock];
}

+ (void)thumbnailForYoutubeID:(NSString *)youtubeID thumbnailSize:(YouTubeThumbnail)thumbnailSize completeBlock:(void (^)(UIImage *, NSError *))completeBlock {
	HCYoutubeParser *ytParser = [HCYoutubeParser sharedInstance];
	[ytParser thumbnailForYoutubeID:youtubeID thumbnailSize:thumbnailSize completeBlock:completeBlock];
}

- (void)thumbnailForYoutubeID:(NSString *)youtubeID thumbnailSize:(YouTubeThumbnail)thumbnailSize completeBlock:(void (^)(UIImage *, NSError *))completeBlock {
    if (youtubeID) {
        
        NSString *thumbnailSizeString = nil;
        switch (thumbnailSize) {
            case YouTubeThumbnailDefault:
                thumbnailSizeString = @"default";
                break;
            case YouTubeThumbnailDefaultMedium:
                thumbnailSizeString = @"mqdefault";
                break;
            case YouTubeThumbnailDefaultHighQuality:
                thumbnailSizeString = @"hqdefault";
                break;
            case YouTubeThumbnailDefaultMaxQuality:
                thumbnailSizeString = @"maxresdefault";
                break;
            default:
                thumbnailSizeString = @"default";
                break;
        }
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kYoutubeThumbnailURL, youtubeID, thumbnailSizeString]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
        [request setHTTPMethod:@"GET"];
		
		[self.youtubeRequestQueue isSuspended];
        
        [NSURLConnection sendAsynchronousRequest:request
										   queue:self.youtubeRequestQueue
							   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (!error) {
                UIImage *image = [UIImage imageWithData:data];
                completeBlock(image, nil);
            }
            else {
                completeBlock(nil, error);
            }
        }];
        
    }
    else {
        
        NSDictionary *details = @{ NSLocalizedDescriptionKey : @"Could not find a valid Youtube ID" };
        
        NSError *error = [NSError errorWithDomain:@"com.hiddencode.yt-parser" code:0 userInfo:details];
        
        completeBlock(nil, error);
    }
}

+ (void)detailsForYouTubeURL:(NSURL *)youtubeURL
               completeBlock:(void(^)(NSDictionary *details, NSError *error))completeBlock {
	HCYoutubeParser *ytParser = [HCYoutubeParser sharedInstance];
	[ytParser detailsForYouTubeURL:youtubeURL completeBlock:completeBlock];
}

- (void)detailsForYouTubeURL:(NSURL *)youtubeURL
               completeBlock:(void(^)(NSDictionary *details, NSError *error))completeBlock
{
    NSString *youtubeID = [HCYoutubeParser youtubeIDFromYoutubeURL:youtubeURL];
    if (youtubeID)
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:kYoutubeDataURL, youtubeID]]];
        
        [NSURLConnection sendAsynchronousRequest:request queue:self.youtubeRequestQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (!error) {
                NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:kNilOptions
                                                                       error:&error];
                if (!error)
                {
                    completeBlock(json, nil);
                }
                else {
                    completeBlock(nil, error);
                }
            }
            else {
                completeBlock(nil, error);
            }
        }];
    }
    else
    {
        NSDictionary *details = @{ NSLocalizedDescriptionKey : @"Could not find a valid Youtube ID" };
        
        NSError *error = [NSError errorWithDomain:@"com.hiddencode.yt-parser" code:0 userInfo:details];
        
        completeBlock(nil, error);
    }
}

@end
