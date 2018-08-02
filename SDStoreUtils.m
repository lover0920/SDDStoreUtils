//
//  SDStoreUtils.m
//  freeStuff
//
//  Created by 孙号斌 on 2017/11/8.
//  Copyright © 2017年 孙号斌. All rights reserved.
//

#import "SDStoreUtils.h"
#import <Security/Security.h>

@implementation SDStoreUtils
#pragma mark - plist文件的存储和读取
+(void)saveArrayDataForPlistFile:(NSMutableArray *)array
                        fileName:(NSString *)fileName
{
    
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [docPath stringByAppendingPathComponent:
                          [fileName stringByAppendingString:@".plist"]];
    
    [array writeToFile:filePath atomically:YES];
}
+(NSArray *)readArrayDataFromePlistFile:(NSString *)fileName
{
    NSString *docPath=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [docPath stringByAppendingPathComponent:
                          [fileName stringByAppendingString:@".plist"]];
    NSArray *arr= [NSArray arrayWithContentsOfFile:filePath];
    return arr;
}

#pragma mark - 归档和解归档
+ (void)saveKeyedArchiverFile:(nullable id)responseObject
                          key:(NSString *)key
{
    NSMutableData *saveData = [NSMutableData data];
    NSKeyedArchiver *keyedArchiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:saveData];
    [keyedArchiver encodeObject:responseObject forKey:key];
    [keyedArchiver finishEncoding];
    
    // 获取沙盒目录
    NSString *fullPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
    }
    //写到文件中
    [saveData writeToFile:fullPath atomically:YES];
}
+ (nullable id)readKeyedUnarchiverFile:(NSString *)key
{
    // 获取数据目录
    NSString *fullPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:key];
    
    NSData *saveData = [NSData dataWithContentsOfFile:fullPath];
    
    NSKeyedUnarchiver *keyedUnarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:saveData];
    
    return [keyedUnarchiver decodeObjectForKey:key];
}
+ (void)deleteKeyedArchiverFile:(NSString *_Nullable)key
{
    // 获取数据目录
    NSString *fullPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:key];
    [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
}


#pragma mark - 🔑钥匙串的存储、读取、删除
+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (id)kSecClassGenericPassword,
            (id)kSecClass,service,
            (id)kSecAttrService,service,
            (id)kSecAttrAccount,
            (id)kSecAttrAccessibleAfterFirstUnlock,
            (id)kSecAttrAccessible,
            nil];

}

+ (void)saveKeychainValue:(NSString *)sValue key:(NSString *)sKey
{
    //Get search dictionary
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:sKey];
    //Delete old item before add new item
    SecItemDelete((CFDictionaryRef)keychainQuery);
    //Add new object to search dictionary(Attention:the data format)
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:sValue] forKey:(id)kSecValueData];
    //Add item to keychain with the search dictionary
    SecItemAdd((CFDictionaryRef)keychainQuery, NULL);
}

+ (NSString *)readKeychainValue:(NSString *)sKey
{
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:sKey];
    //Configure the search setting
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [keychainQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        } @catch (NSException *e) {
            NSLog(@"Unarchive of %@ failed: %@", sKey, e);
        } @finally {
        }
    }
    if (keyData)
        CFRelease(keyData);
    return ret;
}
+ (void)deleteKeychainValue:(NSString *)sKey
{
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:sKey];
    SecItemDelete((CFDictionaryRef)keychainQuery);
}

@end
