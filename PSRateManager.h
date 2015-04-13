//
//  PSRateManager.h
//  botmusic
//
//  Created by Panda Systems on 4/7/15.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PSRateCompletionType) {
    PSRateCompletionTypeNotProposed,
    PSRateCompletionTypeLiked,
    PSRateCompletionTypeDisliked,
    PSRateComplitionTypeDeclinedProposal
};

typedef NS_ENUM(NSUInteger, PSRating) {
    PSGreate,
    PSNotGreate
};

typedef void(^PSRateCompletion)(PSRateCompletionType);

@interface PSRateManager : NSObject

@property (copy, nonatomic) NSString *appStoreID;
@property (weak, nonatomic) UIViewController *presentingViewController;

@property (nonatomic) BOOL forceToAppStore;

@property (nonatomic) BOOL ratedThisVersion;
@property (nonatomic) BOOL declinedThisVersion;

@property (nonatomic) NSDate* lastPromptDate;
@property (nonatomic) NSNumber* lastPromptRunNumber;
@property (nonatomic) NSNumber* promptsNumber;
@property (nonatomic, assign) BOOL shouldReplaceEUtoUSA;
@property (nonatomic, copy) PSRateCompletion rateCompletion;
+ (instancetype)sharedInstance;

- (void)promptForRatingIfPossibleWithCompletion:(void (^)(PSRateCompletionType willShow))rateCompletion view:(UIView*)view;
- (void)promptForRatingIfPossibleWithForcePromt:(BOOL)forcePromt completion:(void (^)(PSRateCompletionType willShow))rateCompletion view:(UIView*)view;

@end
