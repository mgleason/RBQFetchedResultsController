//
//  RBQFetchRequest.m
//  RBQFetchedResultsControllerTest
//
//  Created by Lauren Smith on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQFetchRequest.h"

@interface RBQFetchRequest ()

@property (weak, nonatomic) RLMRealm *inMemoryRealm;
@property (strong, nonatomic) RLMRealm *realmForMainThread; // Improves scroll performance

@end

@implementation RBQFetchRequest
@synthesize entityName = _entityName,
realmPath = _realmPath;

+ (RBQFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName
                                        inRealm:(RLMRealm *)realm
                                      predicate:(NSPredicate *)predicate
{
    RBQFetchRequest *fetchRequest = [[RBQFetchRequest alloc] initWithEntityName:entityName
                                                                        inRealm:realm];
    fetchRequest.predicate = predicate;
    
    return fetchRequest;
}

+ (RBQFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName
                                  inMemoryRealm:(RLMRealm *)inMemoryRealm
                                      predicate:(NSPredicate *)predicate
{
    RBQFetchRequest *fetchRequest = [[RBQFetchRequest alloc] initWithEntityName:entityName
                                                        inMemoryRealm:inMemoryRealm];
    fetchRequest.predicate = predicate;
    
    return fetchRequest;
}

- (instancetype)initWithEntityName:(NSString *)entityName
                     inMemoryRealm:(RLMRealm *)inMemoryRealm
{
    self = [super init];
    
    if (self) {
        _entityName = entityName;
        _inMemoryRealm = inMemoryRealm;
        _realmPath = inMemoryRealm.path;
    }
    
    return self;
}

- (instancetype)initWithEntityName:(NSString *)entityName
                           inRealm:(RLMRealm *)realm
{
    self = [super init];
    
    if (self) {
        _entityName = entityName;
        _realmPath = realm.path;
    }
    
    return self;
}

- (RLMResults *)fetchObjects {
    return [self fetchObjectsInRealm:self.realm];
}

- (RLMResults *)fetchObjectsInRealm:(RLMRealm *)realm
{
    RLMResults *fetchResults = [NSClassFromString(self.entityName) allObjectsInRealm:realm];
    
    // If we have a predicate use it
    if (self.predicate) {
        fetchResults = [fetchResults objectsWithPredicate:self.predicate];
    }
    
    // If we have sort descriptors then use them
    if (self.sortDescriptors.count > 0) {
        fetchResults = [fetchResults sortedResultsUsingDescriptors:self.sortDescriptors];
    }
    
    return fetchResults;
}

- (BOOL)evaluateObject:(RLMObject *)object
{
    return [self.predicate evaluateWithObject:object];
}

#pragma mark - Getter

- (RLMRealm *)realm
{
    if (self.inMemoryRealm) {
        return self.inMemoryRealm;
    }
    
    if ([NSThread isMainThread] &&
        !self.realmForMainThread) {
        
        self.realmForMainThread = [RLMRealm realmWithPath:self.realmPath];
    }
    
    if ([NSThread isMainThread]) {
        
        return self.realmForMainThread;
    }
    
    return [RLMRealm realmWithPath:self.realmPath];
}

#pragma mark - Hash

- (NSUInteger)hash
{
    if (self.predicate &&
        self.sortDescriptors) {
        
        NSUInteger sortHash = 1;
        
        for (RLMSortDescriptor *sortDescriptor in self.sortDescriptors) {
            sortHash = sortHash ^ sortDescriptor.hash;
        }
        
        return self.predicate.hash ^ sortHash ^ self.entityName.hash;
    }
    else if (self.predicate &&
             self.entityName) {
        return self.predicate.hash ^ self.entityName.hash;
    }
    else {
        return [super hash];
    }
}

@end
