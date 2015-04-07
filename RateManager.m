//
//  RateManager.m
//  botmusic
//
//  Created by Panda Systems on 4/7/15.
//
//



#import <MessageUI/MessageUI.h>

#import "RateManager.h"

//#import "TestFlight.h"

//#import "VMEventsLogger.h"

static NSString * const RateManageriOSAppStoreURLFormat = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@";
static NSString * const RateManageriOS7AppStoreURLFormat = @"itms-apps://itunes.apple.com/app/id%@";
static NSString * const RateManagerAppLookupURLFormat = @"http://itunes.apple.com/%@/lookup";

static NSString * const RateManagerRatedKey = @"RateManagerRatedKey";
static NSString * const RateManagerDeclinedKey = @"RateManagerDeclinedKey";
static NSString * const RateManagerPromptsNumberKey = @"RateManagerPromptsNumberKey";
static NSString * const RateManagerNumberOfRunsKey = @"RateManagerNumberOfRunsKey";

static NSString * const RateManagerLastPromptRunNumberKey = @"RateManagerLastPromptRunNumberKey";
static NSString * const RateManagerLastPromptDateKey = @"RateManagerLastPromptDateKey";
static NSString * const RateManagerFirstOpenDateKey = @"RateManagerFirstOpenDateKey";
static NSString * const RateManagerIsOpenedBeforeKey = @"RateManagerIsOpenedBeforeKey";

static NSString * const RateManagerISODigitalCodeEU = @"150"; // http://stackoverflow.com/questions/7169104/list-of-countries-using-nslocalecountrycode
static NSString * const RateManagerISOAlpha2CodeEU = @"EU";
static NSString * const RateManagerISOAlpha2CodeUSA = @"US";

// Return nil when __INDEX__ is beyond the bounds of the array
#define NSArrayObjectMaybeNil(__ARRAY__, __INDEX__) ((__INDEX__ >= [__ARRAY__ count]) ? nil : [__ARRAY__ objectAtIndex:__INDEX__])

// Manually expand an array into an argument list
#define NSArrayToVariableArgumentsList(__ARRAYNAME__)\
NSArrayObjectMaybeNil(__ARRAYNAME__, 0),\
NSArrayObjectMaybeNil(__ARRAYNAME__, 1),\
NSArrayObjectMaybeNil(__ARRAYNAME__, 2),\
NSArrayObjectMaybeNil(__ARRAYNAME__, 3),\
NSArrayObjectMaybeNil(__ARRAYNAME__, 4),\
NSArrayObjectMaybeNil(__ARRAYNAME__, 5),\
NSArrayObjectMaybeNil(__ARRAYNAME__, 6),\
NSArrayObjectMaybeNil(__ARRAYNAME__, 7),\
NSArrayObjectMaybeNil(__ARRAYNAME__, 8),\
NSArrayObjectMaybeNil(__ARRAYNAME__, 9),\
nil

@interface RateManager() <NSURLConnectionDelegate,UIActionSheetDelegate,UIAlertViewDelegate>


@property (nonatomic)       int ratingValue;
@property (nonatomic, strong) UIView* viewToShowPrompt;

@end

@implementation RateManager

+ (instancetype)sharedInstance
{
    static RateManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
- (id) init{
    self = [super init];
    self.numberOfRuns = @([self.numberOfRuns intValue] + 1);
    if (![self isOpenedBefore]){
        self.isOpenedBefore = YES;
        [self setFirstOpenDate:[NSDate date]];
        self.promptsNumber = @0;
    }
    return self;
}
- (void)promptForRatingIfPossibleWithMessage:(NSString*)message completion:(void (^)(RateCompletionType willShow))rateCompletion view:(UIView*)view{
    
    [self promptForRatingIfPossibleWithMessage:message forcePromt:NO completion:rateCompletion view:view];
}

- (void)promptForRatingIfPossibleWithMessage:(NSString*)message forcePromt:(BOOL)forcePromt completion:(void (^)(RateCompletionType willShow))rateCompletion view:(UIView*)view
{
    self.viewToShowPrompt = view;
    self.rateCompletion = rateCompletion;
    if (!forcePromt) {
        if(![self checkRequirements]) {
            
            if(rateCompletion) {
                rateCompletion(RateCompletionTypeNotRated);
            }
            return;
        }
    }
    
    NSString *locale = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    if ([locale isEqualToString:RateManagerISODigitalCodeEU])
    {
        if (!self.shouldReplaceEUtoUSA) {
            //Apple uses the ISO standard ISO-3166. But EU (code = 150) isn't there, so we have to check this special case
            locale = RateManagerISOAlpha2CodeEU;
        } else {
            locale = RateManagerISOAlpha2CodeUSA;
        }
    }
    
    NSString *iTunesServiceURL = [NSString stringWithFormat:RateManagerAppLookupURLFormat, locale];
    iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"?id=%@", self.appStoreID];
    
    NSOperationQueue *connectionQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:iTunesServiceURL]] queue:connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
        
        if (statusCode == 200) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self promptInternalRatingWithMessage:message];
            });
        } else {
            
            if(_rateCompletion) {
                _rateCompletion(RateCompletionTypeNotRated);
            }
        }
    }];
}

-(BOOL) checkRequirements {
    
    //alreay rated this version
    if(self.ratedThisVersion || self.declinedThisVersion) {
        return NO;
    }
    
    if([self.promptsNumber intValue]>1){
        return NO;
    } else if([self.promptsNumber intValue] == 0){
        NSTimeInterval time = [[NSDate date] timeIntervalSinceDate: self.firstOpenDate];
        if((time>2.0*60.0*60.0*24.0)&&([self.numberOfRuns intValue] >  2)){
            return YES;
        }
    } else if([self.promptsNumber intValue] == 1){
        NSTimeInterval time = [[NSDate date] timeIntervalSinceDate: self.lastPromptDate];
        if((time>60.0*60.0*24.0)&&([self.numberOfRuns intValue] > [self.lastPromptRunNumber intValue] + 1)){
            return YES;
        }
    }
    
    return NO;
//    //already prompted rating on this run
//    if(self.lastPromptRunNumber && [self.lastPromptRunNumber intValue] == [[self numberOfRuns] intValue]) {
//        return NO;
//    }
    
    
    //Rate blockers moved to application layer
    
    //    NSDate* lastPromptDate = self.lastPromptDate;
    //
    //    if(!lastPromptDate) {
    //        lastPromptDate = [VMRunsCounter counter].object.lastUpdateDate;
    //    }
    //
    //    if(!lastPromptDate) {
    //        lastPromptDate = [VMRunsCounter counter].object.firstLaunchDate;
    //    }
    //
    //    if(lastPromptDate) {
    //
    //        NSTimeInterval lastPromptElapsed = [[NSDate date] timeIntervalSinceDate:lastPromptDate];
    //
    //        int prompts = [self.promptsNumber intValue];
    //
    //        if(prompts == 0 && lastPromptElapsed < 60*60*24)
    //            return NO;
    //        else if(prompts == 1 && lastPromptElapsed < 60*60*48)
    //            return NO;
    //        else if(prompts == 2 && lastPromptElapsed < 60*60*72)
    //            return NO;
    //        else if(prompts > 2)
    //            return NO;
    //    }
    
}

- (NSString *)applicationVersion
{
    NSString *applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if ([applicationVersion length] == 0) {
        applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    }
    return applicationVersion;
}

- (NSString*)userDefaultsKey {
    
    return [NSString stringWithFormat:@"RateManagerInfo_%@", [self applicationVersion]];
}

-(id)versionParamForKey:(NSString*)key {
    
    NSDictionary* versionParams = [[NSUserDefaults standardUserDefaults] objectForKey:[self userDefaultsKey]];
    if(versionParams && [versionParams isKindOfClass:[NSDictionary class]])
        return [versionParams objectForKey:key];
    return nil;
}

-(void) setVersionParam:(id)param forKey:(NSString*)key {
    
    NSMutableDictionary* newVersionInfo = [NSMutableDictionary dictionary];
    NSDictionary* versionInfo = [[NSUserDefaults standardUserDefaults] objectForKey:[self userDefaultsKey]];
    if(versionInfo && [versionInfo isKindOfClass:[NSDictionary class]]) {
        [newVersionInfo addEntriesFromDictionary:versionInfo];
    }
    
    [newVersionInfo setObject:param forKey:key];
    [[NSUserDefaults standardUserDefaults] setObject:newVersionInfo forKey:[self userDefaultsKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)declinedThisVersion {
    
    return [[self versionParamForKey:RateManagerDeclinedKey] boolValue];
}

- (void)setDeclinedThisVersion:(BOOL)declined {
    
    [self setVersionParam:@(declined) forKey:RateManagerDeclinedKey];
}

- (BOOL)ratedThisVersion {
    
    return [[self versionParamForKey:RateManagerRatedKey] boolValue];
}

- (void)setRatedThisVersion:(BOOL)rated {
    
    [self setVersionParam:@(rated) forKey:RateManagerRatedKey];
}

-(NSDate*) lastPromptDate {
    
    return [self versionParamForKey:RateManagerLastPromptDateKey];
}

-(void) setLastPromptDate:(NSDate *)lastPromptDate {
    
    [self setVersionParam:lastPromptDate forKey:RateManagerLastPromptDateKey];
}

-(NSDate*) firstOpenDate {
    
    return [self versionParamForKey:RateManagerFirstOpenDateKey];
}

-(void) setFirstOpenDate:(NSDate *)firstOpenDate {
    
    [self setVersionParam:firstOpenDate forKey:RateManagerFirstOpenDateKey];
    
}
- (BOOL)isOpenedBefore {
    
    return [[self versionParamForKey:RateManagerIsOpenedBeforeKey] boolValue];
}

- (void)setIsOpenedBefore:(BOOL)opened {
    
    [self setVersionParam:@(opened) forKey:RateManagerIsOpenedBeforeKey];
}


-(NSNumber*) lastPromptRunNumber {
    
    return [self versionParamForKey:RateManagerLastPromptRunNumberKey];
}

-(void) setLastPromptRunNumber:(NSNumber*)lastPromptRunNumber {
    
    [self setVersionParam:lastPromptRunNumber forKey:RateManagerLastPromptRunNumberKey];
}

-(NSNumber*) promptsNumber {
    
    return [self versionParamForKey:RateManagerPromptsNumberKey];
}

- (void)setPromptsNumber:(NSNumber*)promptsNumber {
    
    [self setVersionParam:promptsNumber forKey:RateManagerPromptsNumberKey];
}

-(NSNumber*) numberOfRuns {
    
    return [self versionParamForKey:RateManagerNumberOfRunsKey];
}

- (void)setNumberOfRuns:(NSNumber*)numberOfRuns {
    
    [self setVersionParam:numberOfRuns forKey:RateManagerNumberOfRunsKey];
}
- (void)promptInternalRatingWithMessage:(NSString *)message{
    
    self.lastPromptRunNumber = [self numberOfRuns];
    self.lastPromptDate = [NSDate date];
    self.promptsNumber = @([self.promptsNumber intValue] + 1);
    
    
    //BOOL isUpgrade = [self isUpdate];
    
    NSMutableArray *buttonTitles = [NSMutableArray arrayWithArray:@[@"Great", @"Not Great"]];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"How's the app for you?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSArrayToVariableArgumentsList(buttonTitles)];
    [actionSheet showInView:self.viewToShowPrompt];
    
}

-(void) internalRatedWithValue:(int)value fromAlert:(UIView *)alert{
    
    self.ratedThisVersion = YES;
    self.ratingValue = value;
    if(value >= 1) {
        if(_rateCompletion) {
            _rateCompletion(RateCompletionTypeLiked);
        }
        
        UIAlertView *alertView=[[UIAlertView alloc]initWithTitle:@"" message:NSLocalizedString(@"Would you like to leave a review?", nil) delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [alertView setTag:0];
        [alertView show];
        
        
    } else {
        if(_rateCompletion) {
            _rateCompletion(RateCompletionTypeDisliked);
        }
    }
    
}


- (NSURL *)ratingsURL
{
    return [NSURL URLWithString:[NSString stringWithFormat:([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f)? RateManageriOS7AppStoreURLFormat: RateManageriOSAppStoreURLFormat, self.appStoreID]];
}

- (void)openRatingsPageInAppStore
{
    [[UIApplication sharedApplication] openURL:self.ratingsURL];
}

- (BOOL) isUpdate{
    return NO;
}

#pragma mark - RateManagerFeedbackControllerDelegate

-(void) didSendFeedback:(NSString *)feedBack {
    
}


#pragma mark - UIActionSheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self internalRatedWithValue:1 fromAlert:actionSheet];
    } else if (buttonIndex == 1) {
        [self internalRatedWithValue:0 fromAlert:actionSheet];
    }

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex){
        [self openRatingsPageInAppStore];
    }
}
@end

