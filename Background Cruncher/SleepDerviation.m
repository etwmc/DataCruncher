//
//  SleepDerviation.m
//  Data Crunchers
//
//  Created by Wai Man Chan on 3/11/16.
//
//

#import "SleepDerviation.h"
#import <IOKit/pwr_mgt/IOPMLib.h>

@implementation SleepDerviation

+ (void)stopSleep {
    CFStringRef reasonForActivity= CFSTR("Cruncher Background");
    
    IOPMAssertionID assertionID;
    IOReturn success = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep,
                                                   kIOPMAssertionLevelOn, reasonForActivity, &assertionID);
    if (success == kIOReturnSuccess)
    {
        
        //Add the work you need to do without
        //  the system sleeping here.
        
        success = IOPMAssertionRelease(assertionID);
        //The system will be able to sleep again.
    }

}

@end
