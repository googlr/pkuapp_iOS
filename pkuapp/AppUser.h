//
//  AppUser.h
//  pkuapp
//
//  Created by wuhaotian on 13-3-5.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Assignment, Course;

@interface AppUser : NSManagedObject

@property (nonatomic, retain) NSString * deanid;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * realname;
@property (nonatomic, retain) NSSet *assignset;
@property (nonatomic, retain) NSSet *courses;
@property (nonatomic, retain) NSSet *localcourses;
@end

@interface AppUser (CoreDataGeneratedAccessors)

- (void)addAssignsetObject:(Assignment *)value;
- (void)removeAssignsetObject:(Assignment *)value;
- (void)addAssignset:(NSSet *)values;
- (void)removeAssignset:(NSSet *)values;

- (void)addCoursesObject:(Course *)value;
- (void)removeCoursesObject:(Course *)value;
- (void)addCourses:(NSSet *)values;
- (void)removeCourses:(NSSet *)values;

- (void)addLocalcoursesObject:(Course *)value;
- (void)removeLocalcoursesObject:(Course *)value;
- (void)addLocalcourses:(NSSet *)values;
- (void)removeLocalcourses:(NSSet *)values;

@end
