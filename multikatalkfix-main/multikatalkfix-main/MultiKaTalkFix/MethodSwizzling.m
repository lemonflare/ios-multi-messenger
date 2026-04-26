//
//  MethodSwizzling.m
//  MultiKaTalkFix
//
//  Created by Seo Hyun-gyu on 2023/05/23.
//

#import "MethodSwizzling.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation MethodSwizzling : NSObject

void SwizzleInstanceMethod(Class origClass, Class newClass, SEL orig, SEL new)
{
    Method origMethod = class_getInstanceMethod(origClass, orig);
    Method newMethod = class_getInstanceMethod(newClass, new);
    if(class_addMethod(origClass, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(newClass, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
}

void SwizzleClassMethod(Class orig_class, Class new_class, SEL orig_sel, SEL new_sel) {

    Method origMethod = class_getClassMethod(orig_class, orig_sel);
    Method newMethod = class_getClassMethod(new_class, new_sel);

    // c = object_getClass((id)c);

    // if(class_addMethod(c, orig_sel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
    //     class_replaceMethod(c, new_sel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    // else
    method_exchangeImplementations(origMethod, newMethod);
}

@end
