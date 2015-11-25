//
//  mergZumero.mm
//  mergZumero
//
//  Created by Monte Goulding on 24/07/2015.
//  Copyright 2015 M E R Goulding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LiveCode.h>
#import <ZumeroSync.h>

static bool isSyncing = false;

NSString * mergZumeroSync(NSString * pFileName, NSString * pServerURL, NSString * pRemote, NSString * pAuthSchemeJSON, NSString * pUser, NSString * pPassword)
{
    if (isSyncing)
        return @"Already syncing";
    
    if ([pAuthSchemeJSON isEqualToString:@""]) {
        pAuthSchemeJSON = nil;
    }
    
    if ([pUser isEqualToString:@""]) {
        pUser = nil;
    }
    
    if ([pPassword isEqualToString:@""]) {
        pPassword = nil;
    }
    
    __block LCObjectRef me;
    LCContextMe(&me);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                             (unsigned long)NULL), ^(void) {
        NSError * t_error = nil;
        
        isSyncing = true;
        
        BOOL ok = [ZumeroSync Sync:pFileName cipherKey:nil serverUrl:pServerURL remote:pRemote authSchemeJS:pAuthSchemeJSON user:pUser password:pPassword error: &t_error];
    
        isSyncing = false;
        
        if (!ok || t_error != nil)
            LCObjectPost(me, "mergZumeroSyncError", "S", t_error != nil ? t_error.localizedDescription : @"unknown error" );
        else
            LCObjectPost(me, "mergZumeroSyncCompleted", "");
        
    });
    
    
    return @"";
}

bool mergZumeroIsSyncing(void)
{
    return isSyncing;
}

NSString * mergZumeroQuarantineSinceLastSync(NSString * pFileName)
{
    
    NSError * t_error = nil;
    
    sqlite3_int64 t_ID;
    
    BOOL ok = [ZumeroSync QuarantineSinceLastSync:pFileName cipherKey:nil pqid:&t_ID error:&t_error];
    
    if (!ok || t_error != nil)
        return t_error != nil ? t_error.localizedDescription : @"unknown error";
    
    return [NSString stringWithFormat:@"%lld", t_ID];
}

NSString * mergZumeroSyncQuarantine(NSString * pFileName, NSString * pQuarantineID, NSString * pServerURL, NSString * pRemote, NSString * pAuthSchemeJSON, NSString * pUser, NSString * pPassword)
{
    if (isSyncing)
        return @"Already syncing";
    
    if ([pAuthSchemeJSON isEqualToString:@""]) {
        pAuthSchemeJSON = nil;
    }
    
    if ([pUser isEqualToString:@""]) {
        pUser = nil;
    }
    
    if ([pPassword isEqualToString:@""]) {
        pPassword = nil;
    }
    
    __block LCObjectRef me;
    LCContextMe(&me);
    
    __block sqlite3_int64 t_ID;
    if (sscanf([pQuarantineID cStringUsingEncoding: NSMacOSRomanStringEncoding], " %lld ", &t_ID) != 1)
        return @"Could not parse quarantine ID";
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                             (unsigned long)NULL), ^(void) {
        NSError * t_error = nil;
        
        BOOL t_partial = YES;
        
        
        while (t_partial)
        {
            BOOL ok = [ZumeroSync SyncQuarantine:pFileName cipherKey:nil qid:t_ID serverUrl:pServerURL remote:pRemote authSchemeJS:pAuthSchemeJSON user:pUser password:pPassword partial:&t_partial error:&t_error];
            if (t_error != nil)
                break;
        }
        
        isSyncing = false;
        
        if (t_error != nil)
            LCObjectPost(me, "mergZumeroSyncError", "S", t_error != nil ? t_error.localizedDescription : @"unknown error" );
        else
            LCObjectPost(me, "mergZumeroSyncCompleted", "");
        
    });
    
    
    return @"";
}