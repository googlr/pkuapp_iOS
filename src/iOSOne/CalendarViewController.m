//
//  CalendarViewController.m
//  iOSOne
//
//  Created by wuhaotian on 11-7-12.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "CalendarViewController.h"
#import "CoreData/CoreData.h"
#import "iOSOneAppDelegate.h"
#import "CalendarGroudView.h"
#import "ModelsAddon.h"
#import "SystemHelper.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "AppUser.h"
#import "CourseDetailsViewController.h"

@implementation CalendarViewController
@synthesize barListView;
@synthesize dayViewBar,weekViewBar;
@synthesize calSwithSegment;
@synthesize weekView;
@synthesize dayView;
@synthesize scrollDayView;
@synthesize scrollWeekView;
//@synthesize eventResults;
@synthesize didInitWeekView,didInitDayView;
@synthesize dateInDayView,dateInWeekView;
@synthesize arrayEventGroups,arrayClassGroup;
@synthesize delegate;
@synthesize listView,tableView = _tableView;
@synthesize bitListControl = _bitListControl;
//@synthesize dateOffset;
@synthesize noticeCenter;
#pragma mark - getter method setup
- (NSMutableArray *)arrayClassGroup {
    if (nil == arrayClassGroup) {
        arrayClassGroup = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return arrayClassGroup;
}

- (NSArray *)serverCourses
{
    if (nil == serverCourses) {
        serverCourses = [[self.delegate.appUser.courses allObjects] retain];
    }
    return serverCourses;
}

- (NSInteger)numDayInDayView
{
    NSInteger num = [SystemHelper getDayForDate:self.dateInDayView];
    return num;
}

- (NSInteger)numWeekInDayView
{
    return [SystemHelper getPkuWeeknumberForDate:self.dateInDayView];
}

- (NSInteger)numWeekInWeekView
{
    return [SystemHelper getPkuWeeknumberForDate:self.dateInWeekView];
}
#pragma mark - PKUCalendarBar delegate
- (void)increaseDateByOneDay
{
    self.dateInDayView = [NSDate dateWithTimeInterval:86400 sinceDate:self.dateInDayView];
}

- (void)decreaseDateByOneDay
{
    self.dateInDayView = [NSDate dateWithTimeInterval:-86400 sinceDate:self.dateInDayView];
}


#pragma mark - EventViewDelegate

- (void)didSelectEKEventForIndex:(NSInteger)index
{
    // Upon selecting an event, create an EKEventViewController to display the event.
	self.detailViewController = [[EKEventViewController alloc] initWithNibName:nil bundle:nil];			
	detailViewController.event = [self.systemEventDayList objectAtIndex:index];
	
	// Allow event editing.
	detailViewController.allowsEditing = YES;
	
	//	Push detailViewController onto the navigation controller stack
	//	If the underlying event gets deleted, detailViewController will remove itself from
	//	the stack and clear its event property.
	[self.navigationController pushViewController:detailViewController animated:YES];
}


#pragma mark - UISegementedControl
- (void)toListView {
    self.dayView.hidden = YES;
    self.weekView.hidden = YES;

    self.listView.hidden = NO;

    [self prepareListViewDataSource];
    [self.tableView reloadData];
    for (ClassGroup *group in self.arrayClassGroup) {
    }
//    [self.view bringSubviewToFront:self.listView];
}

- (void)toDayView
{
    if (!self.didInitDayView) {
        [self displayCoursesInDayView];
    }
    self.weekView.hidden = YES;
    self.listView.hidden = YES;
    self.dayView.hidden = NO;
}

-(void)toWeekView
{
    if (!self.didInitWeekView) {
        [self displayCoursesInWeekView];
    }
    self.dayView.hidden = YES;
    self.listView.hidden = YES;
    self.weekView.hidden = NO;
}

- (void)didSelectCalSegementControl
{
    switch (self.calSwithSegment.selectedSegmentIndex) {
        case 0:
            [self toListView];
            break;
        case 1:
            [self toDayView];
            break;
        case 2:
            [self toWeekView];
            break;
        default:
            break;
    }
}

#pragma  Data Setup
/*- (void) performFetch
{
    
    
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Person" inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
	[fetchRequest setFetchBatchSize:20]; 
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:nil];
	NSArray *descriptors = [NSArray arrayWithObject:sortDescriptor];
	[fetchRequest setSortDescriptors:descriptors];
	
    
	NSError *error;
	self.eventResults = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    self.eventResults.delegate = self;
    
	if (![self.eventResults performFetch:&error])
        NSLog(@"FetchError: %@", [error localizedDescription]);
	[fetchRequest release];
	[sortDescriptor release];
    NSLog(@"FetchCourse%d",[self.eventResults.fetchedObjects count] );
}*/

- (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext == nil)
    {
        UIApplication *application = [UIApplication sharedApplication];
        iOSOneAppDelegate* appdelegate = (iOSOneAppDelegate*) application.delegate;
        managedObjectContext = appdelegate.managedObjectContext;
    }
    return managedObjectContext;
}

- (NSArray *)arrayEventDict
{
    if (nil == arrayEventDict) {
   
        NSMutableArray *tempmarray = [[NSMutableArray alloc] initWithCapacity:0];
        
        for (int i = 0; i < [self.serverCourses count]; i++) {
            
            Course *tempcourse = [self.serverCourses objectAtIndex:i];
            
            [tempmarray addObjectsFromArray:[tempcourse arrayEventsForWeek:[SystemHelper getPkuWeeknumberNow]]];
        }
        arrayEventDict = tempmarray;
    }

    return arrayEventDict;
}

- (IBAction)toAssignmentView:(id)sender {
    AssignmentsListViewController *asVC = [[AssignmentsListViewController alloc] init];
//    asVC.delegate = self.delegate;
    
    [self.navigationController pushViewController:asVC animated:YES];
}

#pragma mark - View Setup

- (void)prepareListViewDataSource {
    
    NSCalendar *nsCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    unsigned uniflag = NSHourCalendarUnit|NSMinuteCalendarUnit;
    NSDateComponents *components = [nsCalendar components:uniflag fromDate:self.dateInDayView];
    
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    
    NSInteger dayMinuteNow = hour*60 +minute;
    
    [self.barListView setupForDisplay];
    
    _bitListControl = 0;
    _bitListControl |= 1 << 13;
    
    [self.arrayClassGroup removeAllObjects];
    
    NSInteger weekNow = [SystemHelper getPkuWeeknumberForDate:self.dateInDayView];
    NSMutableSet *waitSet = [NSMutableSet setWithCapacity:0];
    Notice *_notice = [self.noticeCenter getNoticeNextCourse];
    NSInteger dayOffset = [[_notice.dictInfo objectForKey:@"dayOffset"] intValue];
    NSInteger startMinuteNextCourse = [[_notice.dictInfo objectForKey:@"startMinute"] intValue];
    BOOL foundCoursePresent = NO;
    
    for (Course *course in self.delegate.appUser.courses) {
        DayVector _v = [course dayVectorInDay:[SystemHelper getDayForDate:self.dateInDayView]];
        
        if (_v.startclass != -1) {
            
            foundCoursePresent = YES;
            
            ClassGroup *group = [[ClassGroup alloc] init];
            group.startclass = _v.startclass;
            group.endclass = _v.endclass;
            group.course = course;
            group.type = ClassGroupTypeCourse;
            
            NSInteger startMinute = [Course starthourForClass:group.startclass] * 60;
            float endMinute = [Course starthourForClass:group.endclass] *60 +50;
            
            if (startMinute <= dayMinuteNow && endMinute > dayMinuteNow && fabs([dateInDayView timeIntervalSinceNow]) <= 1) {
                group.type = ClassGroupTypeNow;
            }

            if (fabs([self.dateBegInDayView timeIntervalSinceDate:[SystemHelper dateBeginForDate:[NSDate date]]] - dayOffset*86400) <= 1 && startMinute == startMinuteNextCourse ) {
                group.type = ClassGroupTypeNext;
            }
            
            if ((weekNow%2 ==0 && _v.doubleType == doubleTypeSingle) || (weekNow%2==1 &&_v.doubleType == doubleTypeDouble)) {
                group.type = ClassGroupTypeDisable;
                [waitSet addObject:group];
                continue;
            }

            [self.arrayClassGroup addObject:group];
            for (int i = _v.startclass; i <= _v.endclass; i++) {
                _bitListControl |= 1<<i;
            }
        }
    }
    
//    if (!foundCoursePresent) {
//        ClassGroup *group = [[ClassGroup alloc] init];
//        group.type = ClassGroupTypeAllNone;
//    }
//    
    for (ClassGroup *group in waitSet) {
        BOOL found = NO;
        for (int i = group.startclass; i <= group.endclass; i++) {
            if (_bitListControl & 1<<i) {
                found = YES;
                break;
            }
        }
        if (!found) {
            [self.arrayClassGroup addObject:group];
            for (int i = group.startclass; i <= group.endclass; i++) {
                _bitListControl |= 1<<i;
            }
        }
    }
    int _bitClass = 0;
    BOOL _bitState = NO;
    for (int i = 1 ; i <= 12; i++) {
        _bitState = ! (_bitListControl & 1<<i);
        
        if (_bitState) {
            _bitClass ++;
            if (i == 9 || i == 12) {
                _bitClass --;
                ClassGroup *group = [[ClassGroup alloc] init];
                group.startclass = i;
                group.endclass = i;
                group.type = ClassgroupTypeEmpty;
                [self.arrayClassGroup addObject:group];
            }
        }
        else if (_bitClass != 0){
            ClassGroup *group = [[ClassGroup alloc] init];
            group.startclass = i - _bitClass;
            group.endclass = i - 1;
            group.type = ClassgroupTypeEmpty;
            [self.arrayClassGroup addObject:group];
            _bitClass = 0;
            
        }
        if (i == 9 || i == 12) {
            if (_bitClass != 0){
                ClassGroup *group = [[ClassGroup alloc] init];
                group.startclass = i - _bitClass;
                group.endclass = i - 1;
                group.type = ClassgroupTypeEmpty;
                [self.arrayClassGroup addObject:group];
                _bitClass = 0;
            }
        }
        if (_bitClass == 2) {
            ClassGroup *group = [[ClassGroup alloc] init];
            group.startclass = i - _bitClass+1;
            group.endclass = i;
            group.type = ClassgroupTypeEmpty;
            [self.arrayClassGroup addObject:group];
            _bitClass = 0;
        }
    }
    
    [self.arrayClassGroup sortUsingComparator:^NSComparisonResult(id obj1, id obj2){
        ClassGroup *group1 = obj1;
        ClassGroup *group2 = obj2;
        if (group1.startclass < group2.startclass) {
            return NSOrderedAscending;
        }
        else return NSOrderedDescending;
    }];
    ClassGroup *group = [[ClassGroup alloc] init];
    group.type = ClassGroupTypeEnd;
    [self.arrayClassGroup addObject:group];
    [group release];
    
}

/*this function is the main body for displaying day view, aiming to handle view-layer locgic 
 and fetching and merging raw event data ,leaving detail adjustment to subview itself*/

- (void)displayCoursesInDayView
{
    [self.systemEventDayList removeAllObjects];
    [self.systemEventDayList addObjectsFromArray:[self fetchEventsForDay]];
    
    CalendarDayGroundView *groundView = [[CalendarDayGroundView alloc] initWithFrame:CGRectMake(0.0, 0.0, widthTotal, heightTotal)];
    
    NSMutableArray *arrayEvent = [[NSMutableArray alloc] initWithCapacity:0];
  
    for (int i = 0; i < [self.serverCourses count]; i++) {
        Course *course = [self.serverCourses objectAtIndex:i];
        
        NSDictionary *tempdict = [course dictEventForDay:self.numDayInDayView inWeek:self.numWeekInDayView];
        
        if (tempdict) {
            
            EventView *tempEvent = [[EventView alloc] initWithDict:tempdict ForGroundType:CalendarGroundTypeDay ViewType:EventViewCourse];
            
            tempEvent.delegate = self;
            tempEvent.objIndex = i;
            [arrayEvent addObject:tempEvent];
            
        }
        
    }
    
    for (int i = 0; i < [self.systemEventDayList count]; i++) {
        EKEvent *event = [self.systemEventDayList objectAtIndex:i];
        
        EventView *tempEvent = [[EventView alloc] initWithEKEvent:event ForGroudType:CalendarGroundTypeDay inDate:self.dateBegInDayView];
        
        tempEvent.delegate = self;
        
        tempEvent.objIndex = i;
        
        [arrayEvent addObject:tempEvent];
    }

    [self prepareEventViewsForDayDisplay:arrayEvent];

    for (EventView *event in arrayEvent) {
        
        //NSLog(@"%@",event.EventName);
        [groundView addSubview:event];
    }

    [self.scrollDayView addSubview:groundView];
    
    self.scrollDayView.contentSize = CGSizeMake(widthTotal, heightTotal);
    
    self.didInitDayView = YES;
    
    [groundView setupForDisplay];

    [groundView release];
    
    [self.dayViewBar setupForDisplay];
    
    [self.view setNeedsDisplay];


}
- (void)prepareEventViewsForDayDisplay:(NSArray *)arrayEventViews
{
    if ([arrayEventViews count]== 0) {
        return;
    }
    
    [self.arrayEventGroups removeAllObjects];
    
    for (EventView *event in arrayEventViews) {
        
        eventGroup *group = [[eventGroup alloc] initWithEvent:event];
        
        [self.arrayEventGroups addObject:group];
        
        [group release];
        
    }
    BOOL needReGroup = YES;
    
    while (needReGroup) {
        
        needReGroup = NO;
        
        for (int i = 0 ; i < [self.arrayEventGroups count]; i++) {
            
            eventGroup *group = [self.arrayEventGroups objectAtIndex:i];
            
            for (int j = i+1; j < [self.arrayEventGroups count]; j++) {
                
                if ([group mergeWithGroup:[self.arrayEventGroups objectAtIndex:j]]){
                    
                    [self.arrayEventGroups removeObjectAtIndex:j];
                    
                    j -= 1;
                    
                    needReGroup =YES;
                    
                }
            }
        }
    }
    for (eventGroup *group in self.arrayEventGroups) {
        
        [group setupEventsForDayDisplay];
        
    }
}
- (void) displayCoursesInWeekView;
{
    [self.systemEventWeekList removeAllObjects];
    
    [self.systemEventWeekList addObjectsFromArray:[self fetchEventsForWeek]];
    
    CalendarWeekGroundView *groundView = [[CalendarWeekGroundView alloc] initWithFrame:CGRectMake(0.0, 0.0, widthTotal, heightTotal)];
    
    NSMutableArray *arrayEvent = [[NSMutableArray alloc] initWithCapacity:0];
    
    for (int i = 0; i < [self.arrayEventDict count];i++) {
        
        NSDictionary *tempdict = [self.arrayEventDict objectAtIndex:i];
        
        EventView *tempEvent = [[EventView alloc] initWithDict:tempdict ForGroundType:CalendarGroundTypeWeek ViewType:EventViewCourse];
        
        [arrayEvent addObject:tempEvent];    
        
        [tempEvent release];
    }
    for (EKEvent *event in self.systemEventWeekList) {
        
        if (event.allDay) {
            [self.alldayList addObject:event];
        }
        else {
            
            EventView *tempEvent = [[EventView alloc] initWithEKEvent:event ForGroudType:CalendarGroundTypeWeek inDate:nil];
            
            if (tempEvent) {
                [arrayEvent addObject:tempEvent];
            }
        }
    }
    
    [self prepareEventViewsForWeekDisplay:arrayEvent];
    
    for (EventView *eventView in arrayEvent) {
        [groundView addSubview:eventView];
    }
    
    [self.scrollWeekView addSubview:groundView];
    
    self.scrollWeekView.contentSize = CGSizeMake(widthTotal, heightTotal);
    
    [groundView setupForDisplay];
    
    [groundView release];
    
    self.didInitWeekView = YES;
    
    [self.weekViewBar setupForDisplay];
}

- (void)prepareEventViewsForWeekDisplay:(NSArray *)arrayEventViews
{
    if ([arrayEventViews count] == 0) {
        return;
    }
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:0];
    
    for (int i = 0; i < 7; i++) {
        
        [tempArray removeAllObjects];
        
        for (EventView *tempEvtView in arrayEventViews) {
            if (tempEvtView.numDay == i+1) {
                [tempArray addObject:tempEvtView];
            }
        }
        
        if ([tempArray count]== 0) {
            continue;
        }
        
        [self.arrayEventGroups removeAllObjects];
        
        for (EventView *event in tempArray) {
            
            eventGroup *group = [[eventGroup alloc] initWithEvent:event];
            [self.arrayEventGroups addObject:group];
            [group release];
            
        }
        BOOL needReGroup = YES;
        
        while (needReGroup) {
            
            needReGroup = NO;
            
            for (int i = 0 ; i < [self.arrayEventGroups count]; i++) {
                
                eventGroup *group = [self.arrayEventGroups objectAtIndex:i];
                
                for (int j = i+1; j < [self.arrayEventGroups count]; j++) {
                    
                    if ([group mergeWithGroup:[self.arrayEventGroups objectAtIndex:j]]) {
                        [self.arrayEventGroups removeObjectAtIndex:j];
                        j -= 1;
                        needReGroup =YES;
                        
                    }
                }
            }
        }
        for (eventGroup *group in self.arrayEventGroups) {
            [group setupEventsForWeekDisplay];
        }
    }
}

#pragma mark - TableView delegate and DataSource



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ClassGroup *group = [self.arrayClassGroup objectAtIndex:indexPath.row];
    
    if (group.type == ClassGroupTypeCourse || group.type == ClassGroupTypeNext || group.type == ClassGroupTypeNow) {
        CourseDetailsViewController *cdv = [[CourseDetailsViewController alloc] init];
        cdv.course = group.course;
        [self.navigationController pushViewController:cdv animated:YES];
        [cdv release];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrayClassGroup.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifer = @"listCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
    }
    [cell.contentView removeAllSubviews];

    ClassGroup *group = [self.arrayClassGroup objectAtIndex:indexPath.row];
    [self setupDefaultCell:cell withClassGroup:group];
//    cell.textLabel.text = group.course.name;
    if (group.type == ClassGroupTypeCourse ) {
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 4, 250, 22)];
        nameLabel.text = group.course.name;
        nameLabel.font = [UIFont boldSystemFontOfSize:18];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.highlightedTextColor = [UIColor whiteColor];
        [cell.contentView addSubview:nameLabel];
        
        
        UILabel *placeLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 26, 250, 18)];
        placeLabel.text = group.course.rawplace;
        placeLabel.font = [UIFont systemFontOfSize:12];
        placeLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
        placeLabel.backgroundColor = [UIColor clearColor];
        placeLabel.highlightedTextColor = [UIColor whiteColor];
        [cell.contentView addSubview:placeLabel];
        [cell.contentView addSubview:nameLabel];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
//       
//        cell.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.85];
//        cell.accessoryView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.85];
    }
    else if (group.type == ClassGroupTypeNow) {
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 4, 250, 22)];
        nameLabel.text = group.course.name;
        nameLabel.textColor = UIColorFromRGB(0x0074E6);
        nameLabel.font = [UIFont boldSystemFontOfSize:18];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.highlightedTextColor = [UIColor whiteColor];
        [cell.contentView addSubview:nameLabel];
        
        
        UILabel *placeLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 26, 250, 18)];
        placeLabel.text = group.course.rawplace;
        placeLabel.font = [UIFont systemFontOfSize:12];
        placeLabel.textColor = [UIColor colorWithRed:0 green:116/255.0 blue:230.0 alpha:0.597656];
        placeLabel.backgroundColor = [UIColor clearColor];
        placeLabel.highlightedTextColor = [UIColor whiteColor];
        [cell.contentView addSubview:placeLabel];
        [cell.contentView addSubview:nameLabel];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;

        //        

    }
    else if (group.type == ClassGroupTypeNext) {
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 4, 250, 22)];
        nameLabel.text = group.course.name;
        nameLabel.textColor = UIColorFromRGB(0x538A2A);
        nameLabel.font = [UIFont boldSystemFontOfSize:18];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.highlightedTextColor = [UIColor whiteColor];
        [cell.contentView addSubview:nameLabel];
        
        
        UILabel *placeLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 26, 250, 18)];
        placeLabel.text = group.course.rawplace;
        placeLabel.font = [UIFont systemFontOfSize:12];
        placeLabel.textColor = [UIColor colorWithRed:83/255.0 green:138/255.0 blue:42/255.0 alpha:0.597656];
//        placeLabel.textColor = UIColorFromRGB(0xCCCCCC);
        placeLabel.backgroundColor = [UIColor clearColor];
        placeLabel.highlightedTextColor = [UIColor whiteColor];
        [cell.contentView addSubview:placeLabel];
        [cell.contentView addSubview:nameLabel];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;

    }
    else if (group.type == ClassGroupTypeDisable) {
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 4, 250, 22)];
        nameLabel.text = group.course.name;
        nameLabel.textColor = UIColorFromRGB(0xCCCCCC);
        nameLabel.font = [UIFont boldSystemFontOfSize:18];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.highlightedTextColor = [UIColor whiteColor];
        [cell.contentView addSubview:nameLabel];
        
        
        UILabel *placeLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 26, 250, 18)];
        placeLabel.text = group.course.rawplace;
        placeLabel.font = [UIFont systemFontOfSize:12];
//        placeLabel.textColor = [UIColor colorWithRed:83 green:138 blue:42 alpha:0.597656];
        placeLabel.textColor = UIColorFromRGB(0xCCCCCC);
        placeLabel.backgroundColor = [UIColor clearColor];
        placeLabel.highlightedTextColor = [UIColor whiteColor];
        [cell.contentView addSubview:placeLabel];
        [cell.contentView addSubview:nameLabel];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
    }

    else {
//        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ClassGroup *group = [self.arrayClassGroup objectAtIndex:indexPath.row];
    
    if (group.type == ClassGroupTypeCourse || group.type == ClassGroupTypeNow || group.type == ClassGroupTypeNext) {
        cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.85];
    }
    else {
    
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ClassGroup *group = [self.arrayClassGroup objectAtIndex:indexPath.row];
    if (group.type == ClassGroupTypeEnd) {
        return 28;
    }
    return (group.endclass - group.startclass+1)*26;
}

#pragma mark -
#pragma mark EKEvent Delegate
@synthesize systemEventDayList,systemEventWeekList,eventStore,defaultCalendar,alldayList,detailViewController,dateBegInDayView;

- (IBAction)chooseDateNow:(id)sender {
    self.dateInDayView = [NSDate date];
//    self.tableView
}

- (NSArray *)fetchEventsForWeek
{
	
	// endDate is 1 day = 60*60*24 seconds = 86400 seconds from startDate
	NSDate *endDate = [NSDate dateWithTimeInterval:86400*7 sinceDate:self.dateBegInDayView];
	
	// Create the predicate. Pass it the default calendar.
	NSArray *calendarArray = [NSArray arrayWithObject:defaultCalendar];
	NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:self.dateBegInDayView endDate:endDate 
                                                                    calendars:calendarArray]; 
	
	// Fetch all events that match the predicate.
	NSArray *events = [self.eventStore eventsMatchingPredicate:predicate];
    
	return events;

}


- (NSArray *)fetchEventsForDay{
	
	
	// endDate is 1 day = 60*60*24 seconds = 86400 seconds from startDate
	NSDate *endDate = [NSDate dateWithTimeInterval:86400 sinceDate:self.dateBegInDayView];
	
	// Create the predicate. Pass it the default calendar.
	NSArray *calendarArray = [NSArray arrayWithObject:defaultCalendar];
	NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:self.dateBegInDayView endDate:endDate 
                                                                    calendars:calendarArray]; 
	
	// Fetch all events that match the predicate.
	NSArray *events = [self.eventStore eventsMatchingPredicate:predicate];
    
	return events;
}

// Overriding EKEventEditViewDelegate method to update event store according to user actions.
- (void)eventEditViewController:(EKEventEditViewController *)controller 
          didCompleteWithAction:(EKEventEditViewAction)action {
	
	NSError *error = nil;
	EKEvent *thisEvent = controller.event;
	
	switch (action) {
		case EKEventEditViewActionCanceled:
			// Edit action canceled, do nothing. 
			break;
			
		case EKEventEditViewActionSaved:
			// When user hit "Done" button, save the newly created event to the event store, 
			// and reload table view.
			// If the new event is being added to the default calendar, then update its 
			// systemEventDayList.
			if (self.defaultCalendar ==  thisEvent.calendar) {
				[self.systemEventDayList addObject:thisEvent];
			}
			[controller.eventStore saveEvent:controller.event span:EKSpanThisEvent error:&error];
			break;
			
		case EKEventEditViewActionDeleted:
			// When deleting an event, remove the event from the event store, 
			// and reload table view.
			// If deleting an event from the currenly default calendar, then update its 
			// systemEventDayList.
			if (self.defaultCalendar ==  thisEvent.calendar) {
				[self.systemEventDayList removeObject:thisEvent];
			}
			[controller.eventStore removeEvent:thisEvent span:EKSpanThisEvent error:&error];
			break;
		default:
			break;
	}
	// Dismiss the modal view controller
	[controller dismissModalViewControllerAnimated:YES];
	
}


// Set the calendar edited by EKEventEditViewController to our chosen calendar - the default calendar.
- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller {
	EKCalendar *calendarForEdit = self.defaultCalendar;
	return calendarForEdit;
}


#pragma mark - Action

- (void)didSelectCourseForIndex:(NSInteger)index {

}

- (void)didSelectDizBtnForCourseIndex:(NSInteger)index {

}

- (void)didSelectAssignBtnForCourseIndex:(NSInteger)index {

}

- (void)chooseDate:(id)sender
{
    
}

- (void)addEvent:(id)sender {
	EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
	
	addController.eventStore = self.eventStore;
    [self presentModalViewController:addController animated:YES];
	
	addController.editViewDelegate = self;
	[addController release];
}

#pragma mark - appearance
- (void)setupDefaultCell:(UITableViewCell *)cell withClassGroup:(ClassGroup *)group{
    if (group.startclass == 0) {
        return;
    }
    for (int i = group.startclass; i <= group.endclass; i++) {
        UILabel *numLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,(i-group.startclass)*25, 20, 25)];
        numLabel.font = [UIFont boldSystemFontOfSize:16];
        numLabel.textAlignment = UITextAlignmentRight;
        numLabel.backgroundColor = [UIColor clearColor];
        numLabel.highlightedTextColor = [UIColor whiteColor];
        numLabel.text = [NSString stringWithFormat:@"%d",i];
        [cell.contentView addSubview:numLabel];
        [numLabel release];
    }
}

- (void)configureGlobalAppearance {
//    [[UILabel appearance] setFontSize:16];
    [[UILabel appearance] setBackgroundColor:[UIColor clearColor]];
//    [UITableView.appearance setBackgroundColor: tableBgColor];
}

#pragma mark - KVO
- (void)didChangeValueForKey:(NSString *)key
{
    if (key == @"dateInDayView") {
        self.dateBegInDayView = [SystemHelper dateBeginForDate:self.dateInDayView];
        [self displayCoursesInDayView];
        [self prepareListViewDataSource];
        [self.tableView reloadData];        
    }
    else if (key == @"dateInWeekView")
        NSLog(@"wait for action dateInWeekView");
}


#pragma mark - View lifecycle
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/
- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"dateInDayView"];
    [self removeObserver:self forKeyPath:@"dateInWeekView"];

    [scrollDayView release];
    [calSwithSegment release];
    [weekView release];
    [scrollWeekView release];
    [dayView release];
    [dayViewBar release];
    [barListView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
   
}

- (void)viewDidLoad
{

    [super viewDidLoad];
    [self configureGlobalAppearance];
    self.bitListControl = 0;
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addEvent:)];

    
    self.navigationItem.rightBarButtonItem = rightButton;
    
    self.title = @"日程";
    
//    self.scrollDayView.decelerationRate = 0.5;
//    self.scrollWeekView.decelerationRate = 0.5;
    [[UIScrollView appearance] setDecelerationRate:0.5];
    self.dateInDayView = [NSDate date];
    self.dateInWeekView = [NSDate date];
    self.dateBegInDayView = [SystemHelper dateBeginForDate:self.dateInDayView];
    
    [self addObserver:self forKeyPath:@"dateInDayView" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"dateInWeekView" options:NSKeyValueObservingOptionNew context:nil];
    
    //[self.weekView removeFromSuperview];
    [self.calSwithSegment addTarget:self action:@selector(didSelectCalSegementControl) forControlEvents:UIControlEventValueChanged];
    
    self.eventStore = [[EKEventStore alloc] init];
    
	self.systemEventDayList = [[NSMutableArray alloc] initWithArray:0];
    self.systemEventWeekList = [[NSMutableArray alloc] initWithCapacity:0];    
    self.arrayEventGroups = [[NSMutableArray alloc] initWithCapacity:0];
    self.alldayList = [[NSMutableArray alloc] initWithCapacity:0];
	self.defaultCalendar = [self.eventStore defaultCalendarForNewEvents];
    //[self performFetch];
//    [self displayCoursesInDayView];
//    [self prepareListViewDataSource];
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"calendar-list-bg.png"]];
//    UIImageView *bgImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 328)];
//    bgImageView.image = [[UIImage imageNamed:@"calendar-list-bg.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:328];
//    self.tableView.backgroundView = bgImageView;
    
    [self toListView];
}

- (void)viewDidUnload
{
    [self removeObserver:self forKeyPath:@"dateInDayView"];
    [self removeObserver:self forKeyPath:@"dateInWeekView"];
    [self setScrollDayView:nil];
    [self setCalSwithSegment:nil];
    [self setWeekView:nil];
    [self setScrollWeekView:nil];
    [self setDayView:nil];
    [self setDayViewBar:nil];
    [self setBarListView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end


@implementation eventGroup

@synthesize startHour,endHour,array;
- (eventGroup *)initWithEvent:(EventView *)event
{
    self = [super init];
    if (self) {
        self.startHour = event.startHour;
        self.endHour = event.endHour;
        self.array = [[NSMutableArray alloc] initWithObjects:event, nil];
    }
    return self;
}

- (BOOL)mergeWithGroup:(eventGroup *)group
{
    if (group.startHour >= self.endHour - 6/48 || group.endHour <= self.startHour + 6/48){
        return NO;
    }
    else {
        self.startHour = MIN(self.startHour, group.startHour);
        self.endHour = MAX(self.endHour,group.endHour);
        [self.array addObjectsFromArray:group.array];
        return YES;
    }
    return YES;
}
- (void)setupEventsForDayDisplay
{
    for (int i = 0; i < [self.array count];  i++) {
        EventView *event = [self.array objectAtIndex:i];
        event.weight =1.0 / [self.array count];
        event.xIndent = i;
        [event setupForDayDisplay];
    }
}

- (void)setupEventsForWeekDisplay
{
    for (int i = 0; i < [self.array count];  i++) {
        EventView *event = [self.array objectAtIndex:i];
        event.weight =1.0 / [self.array count];
        event.xIndent = i;
        [event setupForWeekDisplay];
    }
}
@end
