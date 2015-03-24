#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"

CFStringRef const kShowSMSPreviewKey = CFSTR("SBShowSMSPreview");
CFStringRef const kSpringBoard = CFSTR("com.apple.springboard");
CFStringRef const kSMSNotification = CFSTR("SpringBoardMessageSettingsChangedNotification");
NSString *const kSwitchIdentifier = @"com.PS.MPFS";

@interface MPFSSwitch : NSObject <FSSwitchDataSource>
@end

@implementation MPFSSwitch

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
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
	CFPreferencesSetAppValue(kShowSMSPreviewKey, enabled, kSpringBoard);
	CFPreferencesAppSynchronize(kSpringBoard);
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kSMSNotification, nil, nil, YES);
}

@end

static void PreferencesChanged()
{
	[[FSSwitchPanel sharedPanel] stateDidChangeForSwitchIdentifier:kSwitchIdentifier];
}

__attribute__((constructor)) static void init()
{
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)PreferencesChanged, kSMSNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
}