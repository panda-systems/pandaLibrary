//
//  RateManager.h
//  botmusic
//
//  Created by Panda Systems on 4/7/15.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, RateCompletionType) {
    RateCompletionTypeNotRated,
    RateCompletionTypeLiked,
    RateCompletionTypeDisliked,
};
typedef void(^RateCompletion)(RateCompletionType);

@interface RateManager : NSObject

@property (copy, nonatomic) NSString *appStoreID;
@property (copy, nonatomic) NSString *appName;
@property (weak, nonatomic) UIViewController *presentingViewController;

//open AppStore rating page right after user set 4+ stars (without intermediate alert)
@property (nonatomic) BOOL forceToAppStore;

@property (nonatomic) BOOL ratedThisVersion;
@property (nonatomic) BOOL declinedThisVersion;

@property (nonatomic) NSDate* lastPromptDate;
@property (nonatomic) NSNumber* lastPromptRunNumber;
@property (nonatomic) NSNumber* promptsNumber;
@property (nonatomic, assign) BOOL shouldReplaceEUtoUSA;
@property (nonatomic, copy) RateCompletion rateCompletion;
+ (instancetype)sharedInstance;

- (void)promptForRatingIfPossibleWithMessage:(NSString*)message completion:(void (^)(RateCompletionType willShow))rateCompletion view:(UIView*)view;
- (void)promptForRatingIfPossibleWithMessage:(NSString*)message forcePromt:(BOOL)forcePromt completion:(void (^)(RateCompletionType willShow))rateCompletion view:(UIView*)view;

@end
