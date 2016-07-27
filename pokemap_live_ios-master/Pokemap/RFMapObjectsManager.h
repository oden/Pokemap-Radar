//
//  RFMapObjectsManager.h
//  Pokemap
//
//  Created by Михаил on 21.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFPokemonMarker.h"


static const int maxConcurrentNumber = 10;

@protocol RFMapObjectsManagerDelegate <NSObject>

- (void)newPokemonsReceived:(NSArray *)array;
- (void)needRemovePokemonFromMap:(RFPokemonMarker *)marker;
//- (void)showLoader;
//- (void)hideLoader;
//- (void) resetScanCoordinates;

@end
@interface RFMapObjectsManager : NSObject <RFPokemonMarkerDelegate>

@property (nonatomic, weak) id <RFMapObjectsManagerDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *pokemonsArray;
@property (nonatomic, assign) BOOL gettingData;
//@property (nonatomic, assign) BOOL internal_gettingData;
@property (nonatomic, strong) NSMutableArray *coordinatesArray;
@property (nonatomic, assign) NSTimeInterval lastTimeStamp;
@property (nonatomic, assign) CLLocationCoordinate2D lastCoordinate;
@property (nonatomic, assign) CLLocationCoordinate2D centerCoordinate;
//@property (nonatomic) bool clearScan;
@property (nonatomic, strong) NSTimer* updateTimer;
@property (nonatomic) int scanLocation;

@property (nonatomic) int concurrentScanNumber;

@property (nonatomic, strong) NSMutableArray* fakePokemon;

@property (nonatomic, assign) NSTimeInterval lastGlobalTimeStamp;

+ (instancetype)instance;

- (void)getMapObjectsWithCoordinate:(CLLocationCoordinate2D)coordinate;

- (void) resetPokemonScan;

- (void)cleanExpiredPokemons;
- (void)updateForPokemans;

- (void) pauseUpdateTimer;
- (void) resumeUpdateTimer;

@end
