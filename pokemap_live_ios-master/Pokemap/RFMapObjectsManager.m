//
//  RFMapObjectsManager.m
//  Pokemap
//
//  Created by Михаил on 21.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "RFMapObjectsManager.h"
#import "RFLocationManager.h"
#import "RFNetworkManager.h"
#import "RFCoordinate.h"

#import <AudioToolbox/AudioServices.h>

#define MAX_KMH 2000

@implementation RFMapObjectsManager

+ (instancetype)instance {
    static RFMapObjectsManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.pokemonsArray = [NSMutableArray new];
        //instance.pastFake = NULL;
        instance.fakePokemon = [NSMutableArray new];
        //instance.clearScan = false;
        instance.concurrentScanNumber = 0;
        
        CLLocationCoordinate2D coord;
        coord.latitude = 0;
        coord.longitude = 0;
        instance.centerCoordinate = coord;
        instance.coordinatesArray = [NSMutableArray new];
        [instance.coordinatesArray addObjectsFromArray:[instance coordinatesAroundArrayWithCoordinate:coord]];
        [instance resumeUpdateTimer];
        instance.scanLocation = 0;
    });
    
    return instance;
}

- (void) pauseUpdateTimer {
    [_updateTimer invalidate];
    _updateTimer = NULL;
}
- (void) resumeUpdateTimer {
    if (_updateTimer != NULL) return;
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(updateForPokemans) userInfo:nil repeats:true];
}

- (void)updateForPokemans {
    /*
     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
     if (_gettingData) {
     return;
     }
     */
    if (![RFAuthManager instance].apiUrl) {
        return;
    }
    
    //if ([[NSDate date] timeIntervalSince1970] - _lastGlobalTimeStamp < 25) {
    //NSLog(@"need wait");
    //return;
    //}
    
    //dispatch_async(dispatch_get_main_queue(), ^{
    //[_delegate showLoader];
    //});
    
    
    
    
    
    //_gettingData = YES;
    
    //prepare coordinates array
    
    //self.coordinatesArray = [NSMutableArray new];
    //[self.coordinatesArray addObjectsFromArray:[self coordinatesAroundArrayWithCoordinate:coordinate]];
    
    //if (!self.coordinatesArray) {
    //    _gettingData = NO;
    
    //dispatch_async(dispatch_get_main_queue(), ^{
    //    [_delegate hideLoader];
    //});
    //    return;
    //}
    
    
    
    
    //while (_gettingData) {
    //    RFCoordinate *coordToGet = nil;
    
    //search for next coordinate to get
    
    //Clear if need to
    
    //    if (_clearScan)
    //    {
    //        _clearScan = false;
    //        [_coordinatesArray removeAllObjects];
    //    }
    
    //    for (RFCoordinate *coord in _coordinatesArray) {
    //        if (!coord.received) {
    //            coordToGet = coord;
    //            break;
    //        }
    //    }
    
    
    //    if (coordToGet) {
    //[self internal_getMapObjectsWithCoordinate:coordToGet];
    //    } else if (_gettingData) {
    //        _lastGlobalTimeStamp = [[NSDate date] timeIntervalSince1970];
    //        _gettingData = NO;
    //dispatch_async(dispatch_get_main_queue(), ^{
    //    [_delegate hideLoader];
    //});
    //        return;
    //    }
    //if (_concurrentScanNumber >= maxConcurrentNumber) {
    //usleep(1000 * 15); //Sleep 15 milliseconds
    //}
    //}
    //});
    //if (_clearScan)
    //{
    //    _clearScan = false;
    //    [_coordinatesArray removeAllObjects];
    //}
    if (_concurrentScanNumber < maxConcurrentNumber) {
        [self internal_getMapObjectsWithCoordinate:[_coordinatesArray objectAtIndex:_scanLocation]];
        _scanLocation++;
        if (_scanLocation >= _coordinatesArray.count) _scanLocation = 0;
    }
}

- (double)radiansFromDegrees:(double)degrees {
    return degrees * (M_PI/180.0);
}

- (double)degreesFromRadians:(double)radians {
    return radians * (180.0/M_PI);
}

- (CLLocationCoordinate2D)coordinateFromCoord:
(CLLocationCoordinate2D)fromCoord
                                 atDistanceKm:(double)distanceKm
                             atBearingDegrees:(double)bearingDegrees
{
    double distanceRadians = distanceKm / 6371.0;
    //6,371 = Earth's radius in km
    double bearingRadians = [self radiansFromDegrees:bearingDegrees];
    double fromLatRadians = [self radiansFromDegrees:fromCoord.latitude];
    double fromLonRadians = [self radiansFromDegrees:fromCoord.longitude];
    
    double toLatRadians = asin( sin(fromLatRadians) * cos(distanceRadians)
                               + cos(fromLatRadians) * sin(distanceRadians) * cos(bearingRadians) );
    
    double toLonRadians = fromLonRadians + atan2(sin(bearingRadians)
                                                 * sin(distanceRadians) * cos(fromLatRadians), cos(distanceRadians)
                                                 - sin(fromLatRadians) * sin(toLatRadians));
    
    // adjust toLonRadians to be in the range -180 to +180...
    toLonRadians = fmod((toLonRadians + 3*M_PI), (2*M_PI)) - M_PI;
    
    CLLocationCoordinate2D result;
    result.latitude = [self degreesFromRadians:toLatRadians];
    result.longitude = [self degreesFromRadians:toLonRadians];
    return result;
}

- (NSArray *)coordinatesAroundArrayWithCoordinate:(CLLocationCoordinate2D)coordinate {
    
    //_centerCoordinate = coordinate;
    //NSLog(@"Center lat: %f, long: %f", _centerCoordinate.latitude, _centerCoordinate.longitude);
    
    NSMutableArray * locations = [NSMutableArray new];
    
    double dist = 0.05;
    double maxDist = 3.0; //1.0 is good for not going far
    double distIncrement = 0.05;
    double baseRadiusScan = 28;
    
    //CLLocationCoordinate2D center = coordinate;
    
    RFCoordinate *centerCoord = [RFCoordinate new];
    CLLocationCoordinate2D center;
    center.latitude = 0;
    center.longitude = 0;
    centerCoord.coordinate = center;
    [locations addObject:centerCoord];
    
    //NSMutableArray *newPokemons = [NSMutableArray new];
    
    for (double distance = dist; distance <= maxDist; distance += distIncrement) {
        double scanRotation = baseRadiusScan * (0.1 / distance);
        for (double i = 0; i < 360 + scanRotation; i+=scanRotation) {
            CLLocationCoordinate2D location = [self coordinateFromCoord:center
                                                           atDistanceKm:distance
                                                       atBearingDegrees:i];
            
            
            
            RFCoordinate *locationCoord = [RFCoordinate new];
            //location.latitude -= _centerCoordinate.latitude;
            //location.longitude -= _centerCoordinate.longitude;
            locationCoord.coordinate = location;
            [locations addObject:locationCoord];
 
            
        }
    }
    //[_delegate newPokemonsReceived:newPokemons];
    
    return locations;
}

- (void)internal_getMapObjectsWithCoordinate:(RFCoordinate *)coordinate {
    ////@synchronized (self) {
    if (/*_internal_gettingData || */_concurrentScanNumber >= maxConcurrentNumber) {
        return;
    }
    
    if (_lastCoordinate.latitude != 0 && _lastCoordinate.longitude != 0) {
        //CHECK that position changes not too fast
        
        NSTimeInterval timeElapsed = [[NSDate date] timeIntervalSince1970] - _lastTimeStamp;
        double distanceFromLast = GMSGeometryDistance(coordinate.coordinate, _lastCoordinate);
        
        double metersPassedInSec = distanceFromLast / timeElapsed;
        double metersPassedInHour = metersPassedInSec * 60 * 60;
        
        double kmPassedInHour = metersPassedInHour / 1000;
        
        // NSLog(@"speed %f", kmPassedInHour);
        
        if (kmPassedInHour > MAX_KMH) {
            //NSLog(@"too fast speed");
            //return;
        }
    }
    
    //_internal_gettingData = YES;
    
    coordinate.received = YES;
    //_internal_gettingData = NO;
    
    _concurrentScanNumber++;
    
    //NSLog(@"Concurrent scan number: %d", _concurrentScanNumber);
    
    CLLocationCoordinate2D coord = coordinate.coordinate;
    coord.latitude += _centerCoordinate.latitude;
    coord.longitude += _centerCoordinate.longitude;
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [[RFNetworkManager instance] getMapObjectsWithCoordinate:coord
                                                       onSuccess:
         ^(GetMapObjectsResponse *mapObjects) {
             _lastTimeStamp = [[NSDate date] timeIntervalSince1970];
             _lastCoordinate = coordinate.coordinate;
             
             dispatch_sync(dispatch_get_main_queue(), ^{
                 
                 if (mapObjects) {
                     
                     [self updateMarkersWithData:mapObjects];
                     //[_delegate debug_drawCircleAround:_lastCoordinate];
                     
                     //coordinate.received = YES;
                     //_internal_gettingData = NO;
                     //});
                 }
                 
                 //dispatch_async(dispatch_get_main_queue(), ^{
                 //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                 _concurrentScanNumber--;
                 
                 Float64 lat = coord.latitude;
                 Float64 lon = coord.longitude;
                 
                 
                 if (_fakePokemon.count == 0) {
                     RFPokemonMarker *pokemonMarker = [[RFPokemonMarker alloc] initWithFakePokemon:lat long:lon];
                     pokemonMarker.delegate = self;
                     NSMutableArray *newPokemons = [NSMutableArray new];
                     [newPokemons addObject:pokemonMarker];
                     
                     [_delegate newPokemonsReceived:newPokemons];
                     
                     [_fakePokemon addObject:pokemonMarker];
                 } else {
                     RFPokemonMarker* p = [_fakePokemon firstObject];
                     [p setLocation:lat long:lon];
                 }
                 /*
                  for (int i = 0; i < _fakePokemon.count - 1; i++) {
                  RFPokemonMarker* p = [_fakePokemon objectAtIndex:0];
                  [self needRemovePokemon:p];
                  [_fakePokemon removeObjectAtIndex:0];
                  }*/
                 
             });
             
             
             
         }
                                                       onFailure:
         ^(NSString *description) {
             _concurrentScanNumber--;
             //coordinate.received = NO;
             //_internal_gettingData = NO;
         }];
    });
    //}
}

- (void)getMapObjectsWithCoordinate:(CLLocationCoordinate2D)coordinate {
    _centerCoordinate = coordinate;
}

- (BOOL)isPokemonSpawnPointExists:(NSString *)spawnPoint inArray:(NSArray *)array {
    
    //@synchronized (array) {
    
    BOOL exists = NO;
    
    for (RFPokemonMarker *marker in array) {
        if ([marker.pokemonSpawnId isEqualToString:spawnPoint]) {
            exists = YES;
            
            break;
        }
    }
    
    return exists;
    
    //}
}

- (void)updateMarkersWithData:(GetMapObjectsResponse *)data {
    
    ////@synchronized (_pokemonsArray) {
    
    NSMutableArray *newPokemons = [NSMutableArray new];
    
    for (MapCell *cell in data.mapCells) {
        for (MapPokemon *mapPok in cell.catchablePokemons) {
            // NSLog(@"map id %i spawn %@",(int)mapPok.pokemonId, mapPok.spawnpointId);
            if (![self isPokemonSpawnPointExists:mapPok.spawnpointId inArray:_pokemonsArray] &&
                ![self isPokemonSpawnPointExists:mapPok.spawnpointId inArray:newPokemons]) {
                RFPokemonMarker *pokemonMarker = [[RFPokemonMarker alloc] initWithMapPokemon:mapPok];
                pokemonMarker.delegate = self;
                [newPokemons addObject:pokemonMarker];
                
                
            }
        }
        
        for (WildPokemon *wild in cell.wildPokemons) {
            // NSLog(@"wild id %i spawn %@",(int)wild.pokemonData.pokemonId, wild.spawnpointId);
            if (![self isPokemonSpawnPointExists:wild.spawnpointId inArray:_pokemonsArray] &&
                ![self isPokemonSpawnPointExists:wild.spawnpointId inArray:newPokemons]) {
                RFPokemonMarker *pokemonMarker = [[RFPokemonMarker alloc] initWithWildPokemon:wild];
                pokemonMarker.delegate = self;
                [newPokemons addObject:pokemonMarker];
                
                
            } else {
                //NSLog(@"exists wild %@", wild.spawnpointId);
            }
        }
    }
    
    [_pokemonsArray addObjectsFromArray:newPokemons];
    
    [self vibrateForRarePokemon: newPokemons];
    
    // NSLog(@"new pokemons count %i", newPokemons.count);
    
    [_delegate newPokemonsReceived:newPokemons];
    
    //}
    
}

- (void)vibrateForRarePokemon:(NSArray *)pokemon {
    bool vibrate = false;
    NSString *pokeString = @"";
    
    //Name pokemon
    for (int i = 0; i < pokemon.count; i++) {
        RFPokemonMarker* p = pokemon[i];
        switch (p.pokemonId) {
            case PokemonIdBulbasaur:
                p.pokemonName = @"Bulbasaur";
                break;
            case PokemonIdIvysaur:
                p.pokemonName = @"Ivysaur";
                break;
            case PokemonIdVenusaur:
                p.pokemonName = @"Venusaur";
                break;
            case PokemonIdCharmender:
                p.pokemonName = @"Charmender";
                break;
            case PokemonIdCharmeleon:
                p.pokemonName = @"Charmeleon";
                break;
            case PokemonIdCharizard:
                p.pokemonName = @"Charizard";
                break;
            case PokemonIdSquirtle:
                p.pokemonName = @"Squirtle";
                break;
            case PokemonIdWartortle:
                p.pokemonName = @"Wartortle";
                break;
            case PokemonIdBlastoise:
                p.pokemonName = @"Blastoise";
                break;
            case PokemonIdCaterpie:
                p.pokemonName = @"Caterpie";
                break;
            case PokemonIdMetapod:
                p.pokemonName = @"Metapod";
                break;
            case PokemonIdButterfree:
                p.pokemonName = @"Butterfree";
                break;
            case PokemonIdWeedle:
                p.pokemonName = @"Weedle";
                break;
            case PokemonIdKakuna:
                p.pokemonName = @"Kakuna";
                break;
            case PokemonIdBeedrill:
                p.pokemonName = @"Beedrill";
                break;
            case PokemonIdPidgey:
                p.pokemonName = @"Pidgey";
                break;
            case PokemonIdPidgeotto:
                p.pokemonName = @"Pidgeotto";
                break;
            case PokemonIdPidgeot:
                p.pokemonName = @"Pidgeot";
                break;
            case PokemonIdRattata:
                p.pokemonName = @"Rattata";
                break;
            case PokemonIdRaticate:
                p.pokemonName = @"Raticate";
                break;
            case PokemonIdSpearow:
                p.pokemonName = @"Spearow";
                break;
            case PokemonIdFearow:
                p.pokemonName = @"Fearow";
                break;
            case PokemonIdEkans:
                p.pokemonName = @"Ekans";
                break;
            case PokemonIdArbok:
                p.pokemonName = @"Arbok";
                break;
            case PokemonIdPikachu:
                p.pokemonName = @"Pikachu";
                break;
            case PokemonIdRaichu:
                p.pokemonName = @"Raichu";
                break;
            case PokemonIdSandshrew:
                p.pokemonName = @"Sandshrew";
                break;
            case PokemonIdSandlash:
                p.pokemonName = @"Sandlash";
                break;
            case PokemonIdNidoranFemale:
                p.pokemonName = @"Nidoran";
                break;
            case PokemonIdNidorina:
                p.pokemonName = @"Nidorina";
                break;
            case PokemonIdNidoqueen:
                p.pokemonName = @"Nidoqueen";
                break;
            case PokemonIdNidoranMale:
                p.pokemonName = @"Nidoran";
                break;
            case PokemonIdNidorino:
                p.pokemonName = @"Nidorino";
                break;
            case PokemonIdNidoking:
                p.pokemonName = @"Nidoking";
                break;
            case PokemonIdClefary:
                p.pokemonName = @"Clefary";
                break;
            case PokemonIdClefable:
                p.pokemonName = @"Clefable";
                break;
            case PokemonIdVulpix:
                p.pokemonName = @"Vulpix";
                break;
            case PokemonIdNinetales:
                p.pokemonName = @"Ninetales";
                break;
            case PokemonIdJigglypuff:
                p.pokemonName = @"Jigglypuff";
                break;
            case PokemonIdWigglytuff:
                p.pokemonName = @"Wigglytuff";
                break;
            case PokemonIdZubat:
                p.pokemonName = @"Zubat";
                break;
            case PokemonIdGolbat:
                p.pokemonName = @"Golbat";
                break;
            case PokemonIdOddish:
                p.pokemonName = @"Oddish";
                break;
            case PokemonIdGloom:
                p.pokemonName = @"Gloom";
                break;
            case PokemonIdVileplume:
                p.pokemonName = @"Vileplume";
                break;
            case PokemonIdParas:
                p.pokemonName = @"Paras";
                break;
            case PokemonIdParasect:
                p.pokemonName = @"Parasect";
                break;
            case PokemonIdVenonat:
                p.pokemonName = @"Venonat";
                break;
            case PokemonIdVenomoth:
                p.pokemonName = @"Venomoth";
                break;
            case PokemonIdDiglett:
                p.pokemonName = @"Diglett";
                break;
            case PokemonIdDugtrio:
                p.pokemonName = @"Dugtrio";
                break;
            case PokemonIdMeowth:
                p.pokemonName = @"Meowth";
                break;
            case PokemonIdPersian:
                p.pokemonName = @"Persian";
                break;
            case PokemonIdPsyduck:
                p.pokemonName = @"Psyduck";
                break;
            case PokemonIdGolduck:
                p.pokemonName = @"Golduck";
                break;
            case PokemonIdMankey:
                p.pokemonName = @"Mankey";
                break;
            case PokemonIdPrimeape:
                p.pokemonName = @"Primeape";
                break;
            case PokemonIdGrowlithe:
                p.pokemonName = @"Growlithe";
                break;
            case PokemonIdArcanine:
                p.pokemonName = @"Arcanine";
                break;
            case PokemonIdPoliwag:
                p.pokemonName = @"Poliwag";
                break;
            case PokemonIdPoliwhirl:
                p.pokemonName = @"Poliwhirl";
                break;
            case PokemonIdPoliwrath:
                p.pokemonName = @"Poliwrath";
                break;
            case PokemonIdAbra:
                p.pokemonName = @"Abra";
                break;
            case PokemonIdKadabra:
                p.pokemonName = @"Kadabra";
                break;
            case PokemonIdAlakhazam:
                p.pokemonName = @"Alakhazam";
                break;
            case PokemonIdMachop:
                p.pokemonName = @"Machop";
                break;
            case PokemonIdMachoke:
                p.pokemonName = @"Machoke";
                break;
            case PokemonIdMachamp:
                p.pokemonName = @"Machamp";
                break;
            case PokemonIdBellsprout:
                p.pokemonName = @"Bellsprout";
                break;
            case PokemonIdWeepinbell:
                p.pokemonName = @"Weepinbell";
                break;
            case PokemonIdVictreebell:
                p.pokemonName = @"Victreebell";
                break;
            case PokemonIdTentacool:
                p.pokemonName = @"Tentacool";
                break;
            case PokemonIdTentacruel:
                p.pokemonName = @"Tentacruel";
                break;
            case PokemonIdGeoduge:
                p.pokemonName = @"Geodude";
                break;
            case PokemonIdGraveler:
                p.pokemonName = @"Graveler";
                break;
            case PokemonIdGolem:
                p.pokemonName = @"Golem";
                break;
            case PokemonIdPonyta:
                p.pokemonName = @"Ponyta";
                break;
            case PokemonIdRapidash:
                p.pokemonName = @"Rapidash";
                break;
            case PokemonIdSlowpoke:
                p.pokemonName = @"Slowpoke";
                break;
            case PokemonIdSlowbro:
                p.pokemonName = @"Slowbro";
                break;
            case PokemonIdMagnemite:
                p.pokemonName = @"Magnemite";
                break;
            case PokemonIdMagneton:
                p.pokemonName = @"Magneton";
                break;
            case PokemonIdFarfetchd:
                p.pokemonName = @"Farfetchd";
                break;
            case PokemonIdDoduo:
                p.pokemonName = @"Doduo";
                break;
            case PokemonIdDodrio:
                p.pokemonName = @"Dodrio";
                break;
            case PokemonIdSeel:
                p.pokemonName = @"Seel";
                break;
            case PokemonIdDewgong:
                p.pokemonName = @"Dewgong";
                break;
            case PokemonIdGrimer:
                p.pokemonName = @"Grimer";
                break;
            case PokemonIdMuk:
                p.pokemonName = @"Muk";
                break;
            case PokemonIdShellder:
                p.pokemonName = @"Shellder";
                break;
            case PokemonIdCloyster:
                p.pokemonName = @"Cloyster";
                break;
            case PokemonIdGastly:
                p.pokemonName = @"Gastly";
                break;
            case PokemonIdHaunter:
                p.pokemonName = @"Haunter";
                break;
            case PokemonIdGengar:
                p.pokemonName = @"Gengar";
                break;
            case PokemonIdOnix:
                p.pokemonName = @"Onix";
                break;
            case PokemonIdDrowzee:
                p.pokemonName = @"Drowzee";
                break;
            case PokemonIdHypno:
                p.pokemonName = @"Hypno";
                break;
            case PokemonIdKrabby:
                p.pokemonName = @"Krabby";
                break;
            case PokemonIdKingler:
                p.pokemonName = @"Kingler";
                break;
            case PokemonIdVoltorb:
                p.pokemonName = @"Voltorb";
                break;
            case PokemonIdElectrode:
                p.pokemonName = @"Electrode";
                break;
            case PokemonIdExeggcute:
                p.pokemonName = @"Exeggcute";
                break;
            case PokemonIdExeggutor:
                p.pokemonName = @"Exeggutor";
                break;
            case PokemonIdCubone:
                p.pokemonName = @"Cubone";
                break;
            case PokemonIdMarowak:
                p.pokemonName = @"Marowak";
                break;
            case PokemonIdHitmonlee:
                p.pokemonName = @"Hitmonlee";
                break;
            case PokemonIdHitmonchan:
                p.pokemonName = @"Hitmonchan";
                break;
            case PokemonIdLickitung:
                p.pokemonName = @"Lickitung";
                break;
            case PokemonIdKoffing:
                p.pokemonName = @"Koffing";
                break;
            case PokemonIdWeezing:
                p.pokemonName = @"Weezing";
                break;
            case PokemonIdRhyhorn:
                p.pokemonName = @"Rhyhorn";
                break;
            case PokemonIdRhydon:
                p.pokemonName = @"Rhydon";
                break;
            case PokemonIdChansey:
                p.pokemonName = @"Chansey";
                break;
            case PokemonIdTangela:
                p.pokemonName = @"Tangela";
                break;
            case PokemonIdKangaskhan:
                p.pokemonName = @"Kangaskhan";
                break;
            case PokemonIdHorsea:
                p.pokemonName = @"Horsea";
                break;
            case PokemonIdSeadra:
                p.pokemonName = @"Seadra";
                break;
            case PokemonIdGoldeen:
                p.pokemonName = @"Goldeen";
                break;
            case PokemonIdSeaking:
                p.pokemonName = @"Seaking";
                break;
            case PokemonIdStaryu:
                p.pokemonName = @"Staryu";
                break;
            case PokemonIdStarmie:
                p.pokemonName = @"Starmie";
                break;
            case PokemonIdMrMime:
                p.pokemonName = @"MrMime";
                break;
            case PokemonIdScyther:
                p.pokemonName = @"Scyther";
                break;
            case PokemonIdJynx:
                p.pokemonName = @"Jynx";
                break;
            case PokemonIdElectabuzz:
                p.pokemonName = @"Electabuzz";
                break;
            case PokemonIdMagmar:
                p.pokemonName = @"Magmar";
                break;
            case PokemonIdPinsir:
                p.pokemonName = @"Pinsir";
                break;
            case PokemonIdTauros:
                p.pokemonName = @"Tauros";
                break;
            case PokemonIdMagikarp:
                p.pokemonName = @"Magikarp";
                break;
            case PokemonIdGyarados:
                p.pokemonName = @"Gyarados";
                break;
            case PokemonIdLapras:
                p.pokemonName = @"Lapras";
                break;
            case PokemonIdDitto:
                p.pokemonName = @"Ditto";
                break;
            case PokemonIdEevee:
                p.pokemonName = @"Eevee";
                break;
            case PokemonIdVaporeon:
                p.pokemonName = @"Vaporeon";
                break;
            case PokemonIdJolteon:
                p.pokemonName = @"Jolteon";
                break;
            case PokemonIdFlareon:
                p.pokemonName = @"Flareon";
                break;
            case PokemonIdPorygon:
                p.pokemonName = @"Porygon";
                break;
            case PokemonIdOmanyte:
                p.pokemonName = @"Omanyte";
                break;
            case PokemonIdOmastar:
                p.pokemonName = @"Omastar";
                break;
            case PokemonIdKabuto:
                p.pokemonName = @"Kabuto";
                break;
            case PokemonIdKabutops:
                p.pokemonName = @"Kabutops";
                break;
            case PokemonIdAerodactyl:
                p.pokemonName = @"Aerodactyl";
                break;
            case PokemonIdSnorlax:
                p.pokemonName = @"Snorlax";
                break;
            case PokemonIdArticuno:
                p.pokemonName = @"Articuno";
                break;
            case PokemonIdZapdos:
                p.pokemonName = @"Zapdos";
                break;
            case PokemonIdMoltres:
                p.pokemonName = @"Moltres";
                break;
            case PokemonIdDratini:
                p.pokemonName = @"Dratini";
                break;
            case PokemonIdDragonair:
                p.pokemonName = @"Dragonair";
                break;
            case PokemonIdDragonite:
                p.pokemonName = @"Dragonite";
                break;
            case PokemonIdMewtwo:
                p.pokemonName = @"Mewtwo";
                break;
            case PokemonIdMew:
                p.pokemonName = @"Mew";
                break;
        }
    }

    
    
    for (int i = 0; i < pokemon.count; i++) {
        RFPokemonMarker* p = pokemon[i];
        switch (p.pokemonId) {
            case PokemonIdIvysaur:
            case PokemonIdVenusaur:
            case PokemonIdCharmeleon:
            case PokemonIdCharizard:
            case PokemonIdWartortle:
            case PokemonIdBlastoise:
            case PokemonIdRaichu:
            case PokemonIdSandlash:
            case PokemonIdNidoqueen:
            case PokemonIdNidoking:
            case PokemonIdClefable:
            case PokemonIdNinetales:
            case PokemonIdWigglytuff:
            case PokemonIdVileplume:
            case PokemonIdArcanine:
            case PokemonIdPoliwrath:
            case PokemonIdKadabra:
            case PokemonIdAlakhazam:
            case PokemonIdMachoke:
            case PokemonIdMachamp:
            case PokemonIdVictreebell:
            case PokemonIdTentacruel:
            case PokemonIdGolem:
            case PokemonIdRapidash:
            case PokemonIdSlowbro:
            case PokemonIdMagneton:
            case PokemonIdFarfetchd:
            case PokemonIdDewgong:
            case PokemonIdMuk:
            case PokemonIdCloyster:
            case PokemonIdGengar:
            case PokemonIdOnix:
            case PokemonIdHypno:
            case PokemonIdElectrode:
            case PokemonIdExeggutor:
            case PokemonIdMarowak:
            case PokemonIdHitmonlee:
            case PokemonIdHitmonchan:
            case PokemonIdWeezing:
            case PokemonIdRhydon:
            case PokemonIdChansey:
            case PokemonIdKangaskhan:
            case PokemonIdMrMime:
            case PokemonIdJynx:
            case PokemonIdElectabuzz:
            case PokemonIdGyarados:
            case PokemonIdLapras:
            case PokemonIdPorygon:
            case PokemonIdOmastar:
            case PokemonIdKabutops:
            case PokemonIdAerodactyl:
            case PokemonIdSnorlax:
            case PokemonIdArticuno:
            case PokemonIdZapdos:
            case PokemonIdMoltres:
            case PokemonIdDratini:
            case PokemonIdDragonair:
            case PokemonIdDragonite:
            case PokemonIdMewtwo:
            case PokemonIdMew:
                vibrate = true;
                if ([pokeString isEqualToString:@""]) {
                    pokeString = [NSString stringWithFormat:@"%@", p.pokemonName];
                } else {
                    pokeString = [NSString stringWithFormat:@"%@, %@", pokeString, p.pokemonName];
                }
        }
    }
    if (vibrate) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        
        //[[UIApplication sharedApplication]cancelAllLocalNotifications];
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        if (localNotification == nil)
        {
            return;
        }
        else
        {
            localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
            localNotification.alertAction = nil;
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.alertBody = [NSString stringWithFormat:@"%@%@",  @"Spotted Pokemon: ", pokeString];
            localNotification.alertAction = NSLocalizedString(@"Rare Pokemanz", nil);
            //localNotification.applicationIconBadgeNumber=1;
            localNotification.repeatInterval=0;
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        }
    }
}

- (void) resetPokemonScan {
    //_clearScan = true;
    _scanLocation = 0;
}

- (void)needRemovePokemon:(RFPokemonMarker *)marker {
    //NSLog(@"removing pokemon %@", marker.pokemonSpawnId);
    
    ////@synchronized (_pokemonsArray) {
    
    //    dispatch_async(dispatch_get_main_queue(), ^{
    
    [_delegate needRemovePokemonFromMap:marker];
    
    //  });
    
    //NSLog(@"before %i", _pokemonsArray.count);
    [_pokemonsArray removeObject:marker];
    //NSLog(@"after %i", _pokemonsArray.count);
    //}
    
}

- (void)cleanExpiredPokemons {
    ////@synchronized (_pokemonsArray) {
    for (RFPokemonMarker *marker in [_pokemonsArray copy]) {
        if (marker.timeExpireDate < [[NSDate date] timeIntervalSince1970]) {
            [self needRemovePokemon:marker];
        }
    }
    //}
}
@end
