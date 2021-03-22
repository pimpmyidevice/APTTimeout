/*
# Copyright (c) 2021 t0mi
# https://twitter.com/___t0mi___/
# Released under the Artistic License 2.0
*/

#import <Preferences/Preferences.h>
#import <Preferences/PSSpecifier.h>

#define DEBUG 0
#define PAYPAL   @"https://www.paypal.com/myaccount/transfer/send/external?recipient=fritsch.weiding@yahoo.de&amount=&currencyCode=USD&payment_type=Gift"

#define TIMEOUT_FILE @"/etc/apt/apt.conf.d/99APTTimeout"

#if DEBUG
#   define debug(fmt, ...) NSLog((@"%s @ %d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define debug(...)
#endif

@interface APTTimeoutListController : PSListController
-(id)readPreferenceValue:(PSSpecifier*)specifier;
-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier;
@end

@interface AuthorListController : PSListController
@end

@implementation AuthorListController
@end

@interface iPopup:NSObject
-(void) title:(NSString *)UITitle message:(NSString *)UIMessage;
@end
 
@implementation iPopup
-(void) title:(NSString *)UITitle message:(NSString *)UIMessage {
    UIAlertView *alert = [
        [UIAlertView alloc]
            initWithTitle:UITitle
            message:UIMessage
            delegate:self
            cancelButtonTitle:@"OK"
            otherButtonTitles:nil
                         ];
    [alert show];
    [alert release];
}
@end

@implementation APTTimeoutListController
- (NSArray *)specifiers {
	if (! _specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"APTTimeout" target:self] retain];
	}
	return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    debug(@"path is: %@", path);
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
    NSString *value = (settings[specifier.properties[@"key"]]) ?:
                       specifier.properties[@"default"] ;
    debug(@"returning: %@", value);
    return value;
}
 
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    debug(@"%@", specifier.properties[@"key"]);
    [defaults setObject:value forKey:specifier.properties[@"key"]];
    [defaults writeToFile:path atomically:YES];
    CFStringRef notificationName = (CFStringRef)specifier.properties[@"PostNotification"];
    if (notificationName) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
    }

#if DEBUG
#   NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
#   debug(@"Settings: %@", settings);
#endif

}

-(void)repo {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://url/https://cydia.saurik.com/api/share#?source=https://pimpmyidevice.github.io/t0mi-repo/"]];
}

-(void)twitter {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://user?screen_name=t0mi"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=t0mi"]];
    }else{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/___t0mi___/"]];
    }
}

-(void)paypal {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:PAYPAL]];
}

-(void)apply {


    NSString *https = nil;
    NSString *ftp = nil;
    NSMutableArray *specifiers = [[NSMutableArray alloc] initWithArray:((PSListController *)self).specifiers];
    for (int i=0; i < [specifiers count]; i++ ){
        PSSpecifier *item = [specifiers objectAtIndex:i];
   
        if ([item.identifier isEqualToString:@"HTTPS Timeout"]){
            https = [self readPreferenceValue:item];
        } else if ([item.identifier isEqualToString:@"FTP Timeout"]){
            ftp = [self readPreferenceValue:item];
        }
        
        if ( https != nil && ftp != nil ){
            break;
        }
    
    }

    iPopup *popup = [[iPopup alloc] init];

    debug(@"HTTPS: %@ - FTP: %@", https, ftp);
    if( https == nil || ftp == nil ){
        [popup title:@"Error" message:@"Failure getting timeout values."];
        return;
    }

    NSFileHandle *fh = [NSFileHandle fileHandleForUpdatingAtPath:TIMEOUT_FILE];
    if (fh == nil){
        debug(@"Could not open timeout file");
        [popup title:@"Error" message:@"Couldnt open timeout file"];
        return;
    }

    [fh truncateFileAtOffset: 0];
    NSString *hline = [NSString stringWithFormat:@"Acquire::https::Timeout \"%@\";\n", https];
    NSString *fline = [NSString stringWithFormat:@"Acquire::ftp::Timeout \"%@\";\n",  ftp];

    [fh writeData:[hline dataUsingEncoding:NSASCIIStringEncoding]];
    [fh writeData:[fline dataUsingEncoding:NSASCIIStringEncoding]];
    [fh closeFile];

    debug(@"Success HTTPS %@ -- FTP %@", https, ftp);
    [popup title:@"Success" message:@"Timeouts updated."];
}


@end
