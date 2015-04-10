//
//  PSRateManager.h
//  botmusic
//
//  Created by Panda Systems on 4/7/15.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PSRateCompletionType) {
    PSRateCompletionTypeNotRated,
    PSRateCompletionTypeLiked,
    PSRateCompletionTypeDisliked,
};

typedef void(^PSRateCompletion)(PSRateCompletionType);

@interface PSRateManager : NSObject

@property (copy, nonatomic) NSString *appStoreID;
@property (copy, nonatomic) NSString *appName;

@property (nonatomic) BOOL ratedThisVersion;
@property (nonatomic) BOOL declinedThisVersion;

@property (nonatomic) NSDate* lastPromptDate;
@property (nonatomic) NSNumber* lastPromptRunNumber;
@property (nonatomic) NSNumber* promptsNumber;
@property (nonatomic, assign) BOOL shouldReplaceEUtoUSA;
@property (nonatomic, copy) PSRateCompletion rateCompletion;

+ (instancetype)sharedInstance;

- (void)promptForRatingIfPossibleWithMessage:(NSString*)message
                                  completion:(void (^)(PSRateCompletionType willShow))rateCompletion
                                        view:(UIView*)view;

- (void)promptForRatingIfPossibleWithMessage:(NSString*)message
                                  forcePromt:(BOOL)forcePromt
                                  completion:(void (^)(PSRateCompletionType willShow))rateCompletion
                                        view:(UIView*)view;

@end
