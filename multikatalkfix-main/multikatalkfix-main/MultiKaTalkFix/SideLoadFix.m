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
static NSString* keychainService = @"";
static NSURL* fakeGroupContainerURL;


static NSString* appSuffixFromBundleIdentifier(void)
{
    NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier] ?: @"";
    NSString* kakaoPrefix = @"com.iwilab.KakaoTalk";

    if([bundleIdentifier hasPrefix:kakaoPrefix] && bundleIdentifier.length > kakaoPrefix.length) {
        return [bundleIdentifier substringFromIndex:kakaoPrefix.length];
    }

    return @"";
}

void createDirectoryIfNotExists(NSURL* URL)
{
    if(![URL checkResourceIsReachableAndReturnError:nil])
    {
        [[NSFileManager defaultManager] createDirectoryAtURL:URL withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

static OSStatus (*orig_SecItemAdd)(CFDictionaryRef, CFTypeRef*);
static OSStatus hook_SecItemAdd(CFDictionaryRef attributes, CFTypeRef* result) {
    if (keychainAccessGroup.length > 0 && CFDictionaryContainsKey(attributes, kSecAttrAccessGroup)) {
        CFMutableDictionaryRef mutableAttributes = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, attributes);
        CFDictionarySetValue(mutableAttributes, kSecAttrAccessGroup, (__bridge void*)keychainAccessGroup);
        CFDictionarySetValue(mutableAttributes, kSecAttrService, (__bridge void*)keychainService);
        attributes = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableAttributes);
    }
    else if (keychainService.length > 0 && CFDictionaryContainsKey(attributes, kSecAttrService)) {
        CFMutableDictionaryRef mutableAttributes = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, attributes);
        CFDictionarySetValue(mutableAttributes, kSecAttrService, (__bridge void*)keychainService);
        attributes = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableAttributes);
    }
    return orig_SecItemAdd(attributes, result);
}

static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef, CFTypeRef*);
static OSStatus hook_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef* result) {
    if (keychainAccessGroup.length > 0 && CFDictionaryContainsKey(query, kSecAttrAccessGroup)) {
        CFMutableDictionaryRef mutableQuery =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, query);
        CFDictionarySetValue(mutableQuery, kSecAttrAccessGroup, (__bridge void*)keychainAccessGroup);
        CFDictionarySetValue(mutableQuery, kSecAttrService, (__bridge void*)keychainService);
        query = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableQuery);
    }
    else if (keychainService.length > 0 && CFDictionaryContainsKey(query, kSecAttrService)) {
        CFMutableDictionaryRef mutableQuery =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, query);
        CFDictionarySetValue(mutableQuery, kSecAttrService, (__bridge void*)keychainService);
        query = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableQuery);
    }
    return orig_SecItemCopyMatching(query, result);
}

static OSStatus (*orig_SecItemUpdate)(CFDictionaryRef, CFDictionaryRef);
static OSStatus hook_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    if (keychainAccessGroup.length > 0 && CFDictionaryContainsKey(query, kSecAttrAccessGroup)) {
        CFMutableDictionaryRef mutableQuery =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, query);
        CFDictionarySetValue(mutableQuery, kSecAttrAccessGroup, (__bridge void*)keychainAccessGroup);
        CFDictionarySetValue(mutableQuery, kSecAttrService, (__bridge void*)keychainService);
        query = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableQuery);
    }
    else if (keychainService.length > 0 && CFDictionaryContainsKey(query, kSecAttrService)) {
        CFMutableDictionaryRef mutableQuery =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, query);
        CFDictionarySetValue(mutableQuery, kSecAttrService, (__bridge void*)keychainService);
        query = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableQuery);
    }
    
    if (keychainAccessGroup.length > 0 && CFDictionaryContainsKey(attributesToUpdate, kSecAttrAccessGroup)) {
        CFMutableDictionaryRef mutableQuery =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, attributesToUpdate);
        CFDictionarySetValue(mutableQuery, kSecAttrAccessGroup, (__bridge void*)keychainAccessGroup);
        CFDictionarySetValue(mutableQuery, kSecAttrService, (__bridge void*)keychainService);
        attributesToUpdate = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableQuery);
    }
    else if (keychainService.length > 0 && CFDictionaryContainsKey(attributesToUpdate, kSecAttrService)) {
        CFMutableDictionaryRef mutableQuery =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, attributesToUpdate);
        CFDictionarySetValue(mutableQuery, kSecAttrService, (__bridge void*)keychainService);
        attributesToUpdate = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableQuery);
    }
    return orig_SecItemUpdate(query, attributesToUpdate);
}

static OSStatus (*orig_SecItemDelete)(CFDictionaryRef);
static OSStatus hook_SecItemDelete(CFDictionaryRef query) {
    if (keychainAccessGroup.length > 0 && CFDictionaryContainsKey(query, kSecAttrAccessGroup)) {
        CFMutableDictionaryRef mutableQuery =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, query);
        CFDictionarySetValue(mutableQuery, kSecAttrAccessGroup, (__bridge void*)keychainAccessGroup);
        CFDictionarySetValue(mutableQuery, kSecAttrService, (__bridge void*)keychainService);
        query = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableQuery);
    }
    else if (keychainService.length > 0 && CFDictionaryContainsKey(query, kSecAttrService)) {
        CFMutableDictionaryRef mutableQuery =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, query);
        CFDictionarySetValue(mutableQuery, kSecAttrService, (__bridge void*)keychainService);
        query = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableQuery);
    }
    return orig_SecItemDelete(query);
}

void loadKeychainAccessGroup(void)
{
    NSDictionary* dummyItem = @{
        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount : @"dummyItem",
        (__bridge id)kSecAttrService : @"dummyService",
        (__bridge id)kSecReturnAttributes : @YES,
    };
    
    CFTypeRef result = NULL;
    OSStatus ret = SecItemCopyMatching((__bridge CFDictionaryRef)dummyItem, &result);
    if(ret == -25300)
    {
        ret = SecItemAdd((__bridge CFDictionaryRef)dummyItem, &result);
    }
    
    if(ret == 0 && result)
    {
        NSDictionary* resultDict = (__bridge id)result;
        keychainAccessGroup = resultDict[(__bridge id)kSecAttrAccessGroup];
        NSString* suffix = appSuffixFromBundleIdentifier();
        keychainService = suffix.length > 0 ? [@"com.kakao.Talk" stringByAppendingString:suffix] : @"com.kakao.Talk";
        NSLog(@"[MultiKaTalkFix] Loaded keychainAccessGroup: %@, keychainService: %@", keychainAccessGroup, keychainService);
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
