//
//  MutliLineFix.m
//  MultiLineFix
//
//  Created by Seo Hyun-gyu on 2023/03/04.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import "MultiLineFix.h"
#import "fishhook.h"
#import <objc/runtime.h>
#import "MethodSwizzling.h"

static IMP origIMP_containerURLForSecurityApplicationGroupIdentifier = NULL;
static IMP origIMP_setVocabularyStrings = NULL;

static NSString* keychainAccessGroup = @"";
static NSURL* fakeGroupContainerURL;

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
    CFMutableDictionaryRef mutableAttributes =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, attributes);
    CFDictionarySetValue(mutableAttributes, kSecAttrAccessGroup,
                         (__bridge void*)keychainAccessGroup);
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
    query = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableQuery);
  }

  if (keychainAccessGroup.length > 0 && CFDictionaryContainsKey(attributesToUpdate, kSecAttrAccessGroup)) {
    CFMutableDictionaryRef mutableQuery =
        CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, attributesToUpdate);
    CFDictionarySetValue(mutableQuery, kSecAttrAccessGroup, (__bridge void*)keychainAccessGroup);
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
    query = CFDictionaryCreateCopy(kCFAllocatorDefault, mutableQuery);
  }
  return orig_SecItemDelete(query);
}

void loadKeychainAccessGroup()
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
        NSLog(@"[MultiLineFix] Loaded keychainAccessGroup: %@", keychainAccessGroup);
    }
}



@implementation MultiLineFix

+(void)load {
    NSLog(@"[MultiLineFix] Loaded by 721!");
    
    Class fileManagerClass = NSClassFromString(@"NSFileManager");
    Method containerMethod = class_getInstanceMethod(fileManagerClass, @selector(containerURLForSecurityApplicationGroupIdentifier:));
    if(containerMethod) {
        origIMP_containerURLForSecurityApplicationGroupIdentifier = method_getImplementation(containerMethod);
        SwizzleInstanceMethod(fileManagerClass, [self class], @selector(containerURLForSecurityApplicationGroupIdentifier:), @selector(hook_containerURLForSecurityApplicationGroupIdentifier:));
    }

    Class vocabularyClass = NSClassFromString(@"INVocabulary");
    Method vocabularyMethod = class_getInstanceMethod(vocabularyClass, @selector(setVocabularyStrings:ofType:));
    if(vocabularyMethod) {
        origIMP_setVocabularyStrings = method_getImplementation(vocabularyMethod);
        SwizzleInstanceMethod(vocabularyClass, [self class], @selector(setVocabularyStrings:ofType:), @selector(hook_setVocabularyStrings:ofType:));
    }
    SwizzleClassMethod(vocabularyClass, [self class], @selector(sharedVocabulary), @selector(hook_sharedVocabulary));
    
    fakeGroupContainerURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/FakeGroupContainers"] isDirectory:YES];
    rebind_symbols((struct rebinding[1]){{"SecItemCopyMatching", (void *)hook_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching}}, 1);
    rebind_symbols((struct rebinding[1]){{"SecItemAdd", (void *)hook_SecItemAdd, (void **)&orig_SecItemAdd}}, 1);
    rebind_symbols((struct rebinding[1]){{"SecItemUpdate", (void *)hook_SecItemUpdate, (void **)&orig_SecItemUpdate}}, 1);
    rebind_symbols((struct rebinding[1]){{"SecItemDelete", (void *)hook_SecItemDelete, (void **)&orig_SecItemDelete}}, 1);
    
    loadKeychainAccessGroup();
}

+(instancetype)hook_sharedVocabulary {
  return nil;
}

-(void)hook_setVocabularyStrings:(id)arg1 ofType:(long long)arg2 {
  return;
}

-(NSURL *)hook_containerURLForSecurityApplicationGroupIdentifier:(NSString *)groupIdentifier {
    NSURL* fakeURL = [fakeGroupContainerURL URLByAppendingPathComponent:groupIdentifier];
    
    createDirectoryIfNotExists(fakeURL);
    createDirectoryIfNotExists([fakeURL URLByAppendingPathComponent:@"Library"]);
    createDirectoryIfNotExists([fakeURL URLByAppendingPathComponent:@"Library/Caches"]);
    
    return fakeURL;
}

@end
