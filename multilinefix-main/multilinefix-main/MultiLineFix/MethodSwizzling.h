//
//  MethodSwizzling.h
//  KaTalkRevealerJailed
//
//  Created by Seo Hyun-gyu on 2023/03/02.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MethodSwizzling : NSObject

void SwizzleInstanceMethod(Class origClass, Class newClass, SEL orig, SEL new);
void SwizzleClassMethod(Class orig_class, Class new_class, SEL orig_sel, SEL new_sel);

@end

NS_ASSUME_NONNULL_END
