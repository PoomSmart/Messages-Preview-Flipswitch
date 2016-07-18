#import <Flipswitch/FSSwitchDataSource.h>
#import <Flipswitch/FSSwitchPanel.h>
#import "../PS.h"

CFStringRef const kShowSMSPreviewKey = CFSTR("SBShowSMSPreview");
CFStringRef const kSpringBoard = CFSTR("com.apple.springboard");
CFStringRef const kSMSNotification = isiOS9Up ? CFSTR("com.apple.bulletinboard.allowPublication") : CFSTR("SpringBoardMessageSettingsChangedNotification");
NSString *const kSwitchIdentifier = @"com.PS.MPFS";
NSString *const kMobileSMS = @"com.apple.MobileSMS";

@interface BBSectionInfo : NSObject
@property(nonatomic, copy) NSString *sectionID;
@property(nonatomic) BOOL showsMessagePreview;
@end

@interface BBSettingsGateway : NSObject
- (void)setSectionInfo:(BBSectionInfo *)info forSectionID:(NSString *)sectionID;
- (void)getSectionInfoForSectionID:(NSString *)sectionID withCompletion:(void (^)(BBSectionInfo *, int))handler;
- (void)getSectionInfoForActiveSectionsWithCompletion:(void (^)(NSArray *))handler;
@end

@interface QuietHoursStateController : NSObject
+ (QuietHoursStateController *)sharedController;
- (BBSettingsGateway *)bbGateway;
@end

@interface MPFSSwitch : NSObject <FSSwitchDataSource>
@end

extern "C" BOOL BBServerAllowsPublication();
extern "C" void BBServerSetAllowsPublication(BOOL);

FSSwitchState enabledState = FSSwitchStateIndeterminate;

static void PreferencesChanged()
{
	[[FSSwitchPanel sharedPanel] stateDidChangeForSwitchIdentifier:kSwitchIdentifier];
}


@implementation MPFSSwitch

- (id)init
{
    if (self == [super init])
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, (CFNotificationCallback)PreferencesChanged, kSMSNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    return self;
}

- (void)dealloc
{
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, kSMSNotification, NULL);
	[super dealloc];
}

- (void)updateSectionInfo:(BOOL)enabled getState:(BOOL)getState
{
	[self.gateway getSectionInfoForActiveSectionsWithCompletion:^(NSArray *infos) {
		BBSectionInfo *info = nil;
		for (BBSectionInfo *_info in infos) {
			if ([_info.sectionID isEqualToString:kMobileSMS]) {
				info = _info;
				break;
			}
		}
		if (info) {
			if (!getState) {
				info.showsMessagePreview = enabled;
				[self.gateway setSectionInfo:info forSectionID:kMobileSMS];
				BBServerSetAllowsPublication(YES);
				//BBServerSetAllowsPublication(NO);
			} else
				enabledState = info.showsMessagePreview ? FSSwitchStateOn : FSSwitchStateOff;
		}
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
		if (enabledState == FSSwitchStateIndeterminate) {
			[self updateSectionInfo:NO getState:YES];
			PreferencesChanged();
		}
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
	enabledState = newState;
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