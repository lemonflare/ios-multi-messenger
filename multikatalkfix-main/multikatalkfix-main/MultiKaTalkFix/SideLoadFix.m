//
//  SideLoadFix.m
//  MultiKaTalkFix
//
//  Created by Seo Hyun-gyu on 2023/05/23.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <Intents/Intents.h>
#import <Security/Security.h>
#import "SideLoadFix.h"
#import "fishhook.h"
#import "MethodSwizzling.h"

static IMP origIMP_containerURLForSecurityApplicationGroupIdentifier = NULL;
static IMP origIMP_siriAuthorizationStatus = NULL;
static NSString* keychainAccessGroup = @"";
static NSURL* fakeGroupContainerURL;


static NSString* stringEntitlement(NSString* entitlementName)
{
    SecTaskRef task = SecTaskCreateFromSelf(kCFAllocatorDefault);
    if(!task) {
        return @"";
    }

    CFTypeRef value = SecTaskCopyValueForEntitlement(task, (__bridge CFStringRef)entitlementName, NULL);
    CFRelease(task);

    if(!value) {
        return @"";
    }

    id object = CFBridgingRelease(value);
    return [object isKindOfClass:[NSString class]] ? object : @"";
}

static NSString* normalizeAppIdentifierPrefix(NSString* prefix)
{
    if(![prefix isKindOfClass:[NSString class]] || prefix.length == 0) {
        return @"";
    }

    return [prefix hasSuffix:@"."] ? prefix : [prefix stringByAppendingString:@"."];
}

static NSString* loadAppIdentifierPrefix(NSString* bundleIdentifier)
{
    NSString* applicationIdentifier = stringEntitlement(@"application-identifier");
    if(applicationIdentifier.length > bundleIdentifier.length && [applicationIdentifier hasSuffix:bundleIdentifier]) {
        NSUInteger prefixLength = applicationIdentifier.length - bundleIdentifier.length;
        return normalizeAppIdentifierPrefix([applicationIdentifier substringToIndex:prefixLength]);
    }

    NSString* teamIdentifier = stringEntitlement(@"com.apple.developer.team-identifier");
    if(teamIdentifier.length > 0) {
        return normalizeAppIdentifierPrefix(teamIdentifier);
    }

    NSString* infoPrefix = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AppIdentifierPrefix"];
    return normalizeAppIdentifierPrefix(infoPrefix);
}

void createDirectoryIfNotExists(NSURL* URL)
{
    if(![URL checkResourceIsReachableAndReturnError:nil])
    {
        [[NSFileManager defaultManager] createDirectoryAtURL:URL withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

static CFDictionaryRef copyDictionaryReplacingAccessGroup(CFDictionaryRef dictionary)
{
    if(keychainAccessGroup.length == 0 || !dictionary || !CFDictionaryContainsKey(dictionary, kSecAttrAccessGroup)) {
        return NULL;
    }

    CFMutableDictionaryRef mutableDictionary = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, dictionary);
    if(!mutableDictionary) {
        return NULL;
    }

    CFDictionarySetValue(mutableDictionary, kSecAttrAccessGroup, (__bridge const void*)keychainAccessGroup);
    CFDictionaryRef copiedDictionary = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableDictionary);
    CFRelease(mutableDictionary);
    return copiedDictionary;
}

static OSStatus (*orig_SecItemAdd)(CFDictionaryRef, CFTypeRef*);
static OSStatus hook_SecItemAdd(CFDictionaryRef attributes, CFTypeRef* result) {
    CFDictionaryRef rewrittenAttributes = copyDictionaryReplacingAccessGroup(attributes);
    OSStatus status = orig_SecItemAdd(rewrittenAttributes ? rewrittenAttributes : attributes, result);
    if(rewrittenAttributes) {
        CFRelease(rewrittenAttributes);
    }
    return status;
}

static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef, CFTypeRef*);
static OSStatus hook_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef* result) {
    CFDictionaryRef rewrittenQuery = copyDictionaryReplacingAccessGroup(query);
    OSStatus status = orig_SecItemCopyMatching(rewrittenQuery ? rewrittenQuery : query, result);
    if(rewrittenQuery) {
        CFRelease(rewrittenQuery);
    }
    return status;
}

static OSStatus (*orig_SecItemUpdate)(CFDictionaryRef, CFDictionaryRef);
static OSStatus hook_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    CFDictionaryRef rewrittenQuery = copyDictionaryReplacingAccessGroup(query);
    CFDictionaryRef rewrittenAttributesToUpdate = copyDictionaryReplacingAccessGroup(attributesToUpdate);
    OSStatus status = orig_SecItemUpdate(rewrittenQuery ? rewrittenQuery : query, rewrittenAttributesToUpdate ? rewrittenAttributesToUpdate : attributesToUpdate);
    if(rewrittenQuery) {
        CFRelease(rewrittenQuery);
    }
    if(rewrittenAttributesToUpdate) {
        CFRelease(rewrittenAttributesToUpdate);
    }
    return status;
}

static OSStatus (*orig_SecItemDelete)(CFDictionaryRef);
static OSStatus hook_SecItemDelete(CFDictionaryRef query) {
    CFDictionaryRef rewrittenQuery = copyDictionaryReplacingAccessGroup(query);
    OSStatus status = orig_SecItemDelete(rewrittenQuery ? rewrittenQuery : query);
    if(rewrittenQuery) {
        CFRelease(rewrittenQuery);
    }
    return status;
}

void loadKeychainAccessGroup(void)
{
    NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier] ?: @"";
    NSString* appIdentifierPrefix = loadAppIdentifierPrefix(bundleIdentifier);

    if(appIdentifierPrefix.length > 0 && bundleIdentifier.length > 0) {
        keychainAccessGroup = [appIdentifierPrefix stringByAppendingString:bundleIdentifier];
        NSLog(@"[MultiKaTalkFix] Loaded keychainAccessGroup: %@", keychainAccessGroup);
    } else {
        NSLog(@"[MultiKaTalkFix] Failed to load keychainAccessGroup. prefix: %@, bundle: %@", appIdentifierPrefix, bundleIdentifier);
    }
}


@implementation SideLoadFix

+(void)load {
    NSLog(@"[MultiKaTalkFix] Loaded SideLoadFix.");
    
    Class fileManagerClass = NSClassFromString(@"NSFileManager");
    Method containerMethod = class_getInstanceMethod(fileManagerClass, @selector(containerURLForSecurityApplicationGroupIdentifier:));
    if(containerMethod) {
        origIMP_containerURLForSecurityApplicationGroupIdentifier = method_getImplementation(containerMethod);
        SwizzleInstanceMethod(fileManagerClass, [self class], @selector(containerURLForSecurityApplicationGroupIdentifier:), @selector(hook_containerURLForSecurityApplicationGroupIdentifier:));
    }
    
    Class preferencesClass = NSClassFromString(@"INPreferences");
    Method siriMethod = class_getClassMethod(preferencesClass, @selector(siriAuthorizationStatus));
    if(siriMethod) {
        origIMP_siriAuthorizationStatus = method_getImplementation(siriMethod);
        SwizzleClassMethod(preferencesClass, [self class], @selector(siriAuthorizationStatus), @selector(hook_siriAuthorizationStatus));
    }
    
    
    fakeGroupContainerURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/FakeGroupContainers"] isDirectory:YES];
    
    loadKeychainAccessGroup();
    rebind_symbols((struct rebinding[1]){{"SecItemCopyMatching", (void *)hook_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching}}, 1);
    rebind_symbols((struct rebinding[1]){{"SecItemAdd", (void *)hook_SecItemAdd, (void **)&orig_SecItemAdd}}, 1);
    rebind_symbols((struct rebinding[1]){{"SecItemUpdate", (void *)hook_SecItemUpdate, (void **)&orig_SecItemUpdate}}, 1);
    rebind_symbols((struct rebinding[1]){{"SecItemDelete", (void *)hook_SecItemDelete, (void **)&orig_SecItemDelete}}, 1);
}

+(INSiriAuthorizationStatus)hook_siriAuthorizationStatus {
    return INSiriAuthorizationStatusRestricted;
}

-(NSURL *)hook_containerURLForSecurityApplicationGroupIdentifier:(NSString *)groupIdentifier {
    NSURL *ret = nil;
    if(origIMP_containerURLForSecurityApplicationGroupIdentifier) {
        ret = ((NSURL *(*)(id, SEL, NSString *))origIMP_containerURLForSecurityApplicationGroupIdentifier)(self, @selector(containerURLForSecurityApplicationGroupIdentifier:), groupIdentifier);
    }
    if(!ret) {
        return [NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
        //        NSURL* fakeURL = [fakeGroupContainerURL URLByAppendingPathComponent:groupIdentifier];
        //        createDirectoryIfNotExists(fakeURL);
        //        createDirectoryIfNotExists([fakeURL URLByAppendingPathComponent:@"Library"]);
        //        createDirectoryIfNotExists([fakeURL URLByAppendingPathComponent:@"Library/Caches"]);
        //        return fakeURL;
    }
    return ret;
}

@end
