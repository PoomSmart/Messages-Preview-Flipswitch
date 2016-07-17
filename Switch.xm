#import <Flipswitch/FSSwitchDataSource.h>
#import <Flipswitch/FSSwitchPanel.h>
#import "../PS.h"

CFStringRef const kShowSMSPreviewKey = CFSTR("SBShowSMSPreview");
CFStringRef const kSpringBoard = CFSTR("com.apple.springboard");
CFStringRef const kSMSNotification = CFSTR("SpringBoardMessageSettingsChangedNotification");
NSString *const kSwitchIdentifier = @"com.PS.MPFS";

@interface BBSectionInfo : NSObject
@property(nonatomic, copy) NSString *sectionID;
@property(nonatomic) BOOL showsMessagePreview;
@end

@interface BBServer : NSObject
+ (void)_writeSectionInfo:(NSDictionary *)info;
@end

@interface BBSettingsGateway : NSObject
- (void)setSectionInfo:(BBSectionInfo *)info forSectionID:(NSString *)sectionID;
- (void)getSectionInfoForSectionID:(NSString *)sectionID withCompletion:(void (^)(BBSectionInfo *, int))handler;
@end

@interface QuietHoursStateController : NSObject
+ (QuietHoursStateController *)sharedController;
- (BBSettingsGateway *)bbGateway;
@end

@interface MPFSSwitch : NSObject <FSSwitchDataSource>
@end

FSSwitchState enabledState = FSSwitchStateIndeterminate;

static void PreferencesChanged()
{
	[[FSSwitchPanel sharedPanel] stateDidChangeForSwitchIdentifier:kSwitchIdentifier];
}


@implementation MPFSSwitch

- (id)init
{
    if (self == [super init]) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, (CFNotificationCallback)PreferencesChanged, kSMSNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
        if (isiOS9Up)
        	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, (CFNotificationCallback)PreferencesChanged, CFSTR("com.apple.bulletinboard.allowPublication"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    }
    return self;
}

- (void)dealloc
{
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, kSMSNotification, NULL);
	[super dealloc];
}

- (void)updateSectionInfo:(BOOL)enabled getState:(BOOL)getState
{
	[self.gateway getSectionInfoForSectionID:@"com.apple.MobileSMS" withCompletion:^(BBSectionInfo *info, int a2) {
		enabledState = (getState ? info.showsMessagePreview : enabled) ? FSSwitchStateOn : FSSwitchStateOff;
		if (!getState) {
			info.showsMessagePreview = enabled;
			[self.gateway setSectionInfo:info forSectionID:@"com.apple.MobileSMS"];
			[BBServer _writeSectionInfo:@{ @"com.apple.MobileSMS" : info }];
		}
		PreferencesChanged();
	}];
}

- (BBSettingsGateway *)gateway
{
	QuietHoursStateController *qhs = QuietHoursStateController.sharedController;
	BBSettingsGateway *gateway = qhs.bbGateway;
	return gateway;
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
	if (isiOS9Up) {
		if (enabledState == FSSwitchStateIndeterminate)
			[self updateSectionInfo:NO getState:YES];
		return enabledState;
	}
	Boolean keyExist;
	Boolean enabled = CFPreferencesGetAppBooleanValue(kShowSMSPreviewKey, kSpringBoard, &keyExist);
	if (!keyExist)
		return FSSwitchStateOn;
	return enabled ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
	if (newState == FSSwitchStateIndeterminate)
		return;
	CFBooleanRef enabled = newState == FSSwitchStateOn ? kCFBooleanTrue : kCFBooleanFalse;
	if (isiOS9Up)
		[self updateSectionInfo:enabled == kCFBooleanTrue getState:NO];
	else {
		CFPreferencesSetAppValue(kShowSMSPreviewKey, enabled, kSpringBoard);
		CFPreferencesAppSynchronize(kSpringBoard);
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kSMSNotification, nil, nil, YES);
	}
}

@end