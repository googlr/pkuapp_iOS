//
//  NoticeCenterDataSource.m
//  iOSOne
//
//  Created by  on 11-12-23.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "NoticeCenterHepler.h"
//#import <EventKit/EventKit.h>


@implementation Notice
@synthesize object,type,dictInfo;
+ (Notice *)noticeWithObject:(id) object Type:(PKUNoticeType)atype{
    Notice *notice = [[self alloc] init];
    notice.object = object;
    notice.type = atype;
    return notice;
}

- (NSString *)description {
    return [self.object description];
}

@end

@implementation NoticeCenterHepler
@synthesize arrayAssignments;
@synthesize latestCourse,latestAssignment;
@synthesize nowCourse;
@synthesize dictLatestCourse;

- (EKEventStore *)eventStore
{
    if (_eventStore == nil) {
        _eventStore = [[EKEventStore alloc] init];
    }
    return _eventStore;
}

- (Notice *)getNoticeNextCourse {
    if (self.latestCourse != nil) {
        Notice *_notice = [Notice noticeWithObject:self.latestCourse Type:PKUNoticeTypeLatestCourse];
        _notice.dictInfo = self.dictLatestCourse;
        return _notice;
    }
    return nil;
}

- (NSArray *)getNews{
    return nil;
}


- (NSArray *)getAllNotice {
    [self loadData];

    NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
    if (self.nowCourse != nil) {
        [array addObject:[Notice noticeWithObject:self.nowCourse Type:PKUNoticeTypeNowCourse]];
    }
    if (self.latestCourse != nil) {
        Notice *_notice = [Notice noticeWithObject:self.latestCourse Type:PKUNoticeTypeLatestCourse];
        _notice.dictInfo = self.dictLatestCourse;
        [array addObject:_notice];
    }
    if (self.latestEvent!= nil) {
        [array addObject:[Notice noticeWithObject:self.latestEvent Type:PKUNoticeTypeLatestEvent]];
    }
    
    for (Assignment *assign in self.arrayAssignments) {
        [array addObject:[Notice noticeWithObject:assign Type:PKUNoticeTypeAssignment]];
    }
    return array;
}

- (NSArray *) getCourseNotice {
    [self loadData];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
    if (self.nowCourse != nil) {
        [array addObject:[Notice noticeWithObject:self.nowCourse Type:PKUNoticeTypeNowCourse]];
    }
    if (self.latestCourse != nil) {
        [array addObject:[Notice noticeWithObject:self.latestCourse Type:PKUNoticeTypeLatestCourse]];

    }
    return array;
}

- (NSArray *)getEventNotice {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:1];
    if (self.latestEvent!= nil) {
        [array addObject:[Notice noticeWithObject:self.nowCourse Type:PKUNoticeTypeLatestEvent]];
    }
    return array;
}

- (NSArray *)getAssignmentNotice {
    return nil;
}

- (void)getCourseNoticeInWeekOffset:(NSInteger)weekOffset {
    NSDate *nowDate = [NSDate date];

    NSMutableArray *arrayCourseDicts = [NSMutableArray arrayWithCapacity:10];
    
    for (Course *course in AppUser.sharedUser.courses) {
        
        [arrayCourseDicts addObjectsFromArray:[course arrayEventsForWeek:[SystemHelper getPkuWeeknumberNow]+weekOffset]];
    }
    for (Course *course in AppUser.sharedUser.localcourses) {
        [arrayCourseDicts addObjectsFromArray:[course arrayEventsForWeek:[SystemHelper getPkuWeeknumberNow]+weekOffset]];    
    }
    
    NSInteger PKUWeekDayNow = [SystemHelper getDayNow];
    //    NSLog(@"now it's weekday %d",PKUWeekDayNow);
    //NSDateComponents *components = [[NSDateComponents alloc] init];
    
    NSCalendar *nsCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    unsigned uniflag = NSHourCalendarUnit|NSMinuteCalendarUnit;
    NSDateComponents *components = [nsCalendar components:uniflag fromDate:nowDate];
    
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    
    NSInteger dayMinuteNow = hour*60 +minute;
    NSInteger minMinuteInterVal = 10080;
    
    
    for (NSDictionary *dict in arrayCourseDicts) {
        
        NSInteger day = [dict[@"day"] intValue] - PKUWeekDayNow + 7*weekOffset;
        
        if (day < 0) {
            continue;
        }
        //NSLog(@"course %@ is in day %d",[dict objectForKey:@"name"],day);
        float start = [dict[@"start"] floatValue];
        NSInteger minute = start * 60;
        
        NSInteger minuteInterval = day *24 * 60 + minute - dayMinuteNow;
        
        //NSLog(@"and minute interval is %d",minuteInterval);
        
        if (minuteInterval < minMinuteInterVal && minuteInterval > 0) {
            minMinuteInterVal = minuteInterval;
            self.latestCourse = dict[@"course"];
            NSNumber *numDay = @(day);
            
            NSNumber *numMinute = @(minute);
            
            self.dictLatestCourse = @{@"dayOffset": numDay,@"startMinute": numMinute};  
        }
        if (day == 0 && [dict[@"start"] floatValue] * 60 <= dayMinuteNow && [dict[@"end"] floatValue]*60 > dayMinuteNow) {
            if (!nowCourse) {
                self.nowCourse = dict[@"course"];
            }
//            self.dictLatestCourse = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:day+PKUWeekDayNow],@"weekDay", NSNumber numberWithInt:(),nil];
        }
    }
    

}



- (void) loadData {
    self.latestCourse = nil;
    self.nowCourse = nil;
    NSDate *nowDate = [NSDate date];

    NSDate *endDate = [NSDate dateWithTimeInterval:86400*7*30 sinceDate:nowDate];
            
    NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:nowDate endDate:endDate calendars:[self.eventStore calendars]];
    
    NSArray *arrayEvents = [self.eventStore eventsMatchingPredicate:predicate];
    if ([arrayEvents count] != 0) {
        self.latestEvent = arrayEvents[0];
    }
    
    
    //fetch all courses event
    
    [self getCourseNoticeInWeekOffset:0];
    if (!latestCourse) {
        [self getCourseNoticeInWeekOffset:1];
    }
    
    //setup latest event in code below
    
    
    self.arrayAssignments = [AppUser.sharedUser sortedAssignmentNotDone];
}

- (void)loadCourse {

}


@end
