//
//  GamePlayLayer.m
//  TileTutorial
//
//  Created by ScreenCast on 6/19/13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "GamePlayLayer.h"
#import "SimpleAudioEngine.h"

#define kBOARDBOTTOMLEFTX 160
#define kBOARDBOTTOMLEFTY 32
#define kTILEBORDER 10
#define kTILEGAP 6
#define kTILEWIDTH 130

// HACK can now change to whatever you want
/*
 The tutorial was done in a lazy (fast) way - assuming the boardOcc[sq]==tileNum. This is only the case when the last sq is the empty
 */
#define kEMPTY 9

#define UpperLimitY kBOARDBOTTOMLEFTY + kTILEBORDER + (kTILEWIDTH * 5) + kTILEGAP * 4
#define UpperLimitX kBOARDBOTTOMLEFTX + kTILEBORDER + (kTILEWIDTH * 5) + kTILEGAP * 4
#define LowerLimitY kBOARDBOTTOMLEFTY + kTILEBORDER
#define LowerLimitX kBOARDBOTTOMLEFTX + kTILEBORDER

const int Cols[25] = {
    0,1,2,3,4,
    0,1,2,3,4,
    0,1,2,3,4,
    0,1,2,3,4,
    0,1,2,3,4
};

const int Rows[25] = {
    0,0,0,0,0,
    1,1,1,1,1,
    2,2,2,2,2,
    3,3,3,3,3,
    4,4,4,4,4
};

@implementation GamePlayLayer

// HACK this is the key function - now we need to match the tileNumber and boardOcc, as we can no longer assume the tilenumber and boardOcc match
-(int)GetTileIndexFromBoardAtIndex:(int)index {
	for(int i = 0; i < 24; ++i) {
		if(spriteBoard[i].TileNumber==boardOcc[index]) {
			return i;
		}
	}
	return 0; // HACK NO ERROR CHECK !!!!!
}

-(int)GetXCoordFromTileCol:(int)Col {
    return kBOARDBOTTOMLEFTX + kTILEBORDER + ( (kTILEWIDTH + kTILEGAP) * Col );
}

-(int)GetYCoordFromTileRow:(int)Row {
    return kBOARDBOTTOMLEFTY + kTILEBORDER + ( (kTILEWIDTH + kTILEGAP) * Row );
}

-(void)PrintBoard{
    NSLog(@"Board:");
    for(int rank = 4; rank >= 0; rank--) {
        NSLog(@"%d %d %d %d %d",
              boardOcc[rank * 5],
              boardOcc[(rank * 5) + 1],
              boardOcc[(rank * 5) + 2],
              boardOcc[(rank * 5) + 3],
              boardOcc[(rank * 5) + 4]);
    }
}

-(BOOL)OutOfBoard:(CGPoint)touchPoint{
    if(touchPoint.y > UpperLimitY) return YES;
    else if(touchPoint.y < LowerLimitY) return YES;
    else if(touchPoint.x > UpperLimitX) return YES;
    else if(touchPoint.x < LowerLimitX) return YES;
    
    return NO;
}

// no border check here!! Assumes drag will go outside board
-(BOOL)CanMoveToSq:(int)sq fromSq:(int)sqf {

    if(boardOcc[sq] != kEMPTY) return NO;
    
    int diff = sqf - sq;
    
    if(diff < 0) diff *= -1;
    
    if(diff != 5 && diff != 1) {
        return NO;
    }
    
    return YES;
}

-(int)GetBoardSquareFromPoint:(CGPoint)point {
    
    if([self OutOfBoard:point]) {
        return -1;
    }
    
    int x = point.x - kTILEBORDER - kBOARDBOTTOMLEFTX;
    int y = point.y - kTILEBORDER - kBOARDBOTTOMLEFTY;
    
    int totalTileWidth = kTILEWIDTH + kTILEGAP;
    
    int row = y / totalTileWidth;
    int col = x / totalTileWidth;
    
    int sq = row * 5 + col;
    NSLog(@"GetBoardSquareFromPoint:%d",sq);
    
    return sq;
    
}


-(int)GetTileSquareFromPoint:(CGPoint)point {
    
    
    for(int sq = 0; sq < 24; ++sq) {
        if( CGRectContainsPoint([spriteBoard[sq] boundingBox], point) ) {
			NSLog(@"Found Possible Tile On sq %d", sq);
            for(int currIndex = 0; currIndex < 25; ++currIndex) {
				// HACK match up tileNumber and boardOcc
                if(boardOcc[currIndex] == spriteBoard[sq].TileNumber) {
                    NSLog(@"Found Tile On sq %d", currIndex);
                    return currIndex;
                }
            }
        }
    }
    
    return -1;
}

-(void) registerWithTouchDispatcher {
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    NSLog(@"ccTouchBegan() touchLocation (%0.f,%0.f)", touchLocation.x, touchLocation.y);
    
    if(isAnimating) {
        NSLog(@"ccTouchBegan isAnimating return");
        return NO;
    }

    
    if(CGRectContainsPoint(easyButton.boundingBox, touchLocation)) {
        NSLog(@"Easy pressed");
        [self RandomiseBoardForMoves:3];
        inGame = YES;
        return NO;
    }
    
    if(CGRectContainsPoint(hardButton.boundingBox, touchLocation)) {
        NSLog(@"Hard pressed");
        [self RandomiseBoardForMoves:150];
        inGame = YES;
        return NO;
    }
    
    if(CGRectContainsPoint(resetButton.boundingBox, touchLocation)) {
        NSLog(@"Reset pressed");
        [self ResetGame];
        inGame = NO;
        return NO;
    }
    
    if([self OutOfBoard:touchLocation]) {
        NSLog(@"ccTouchBegan() out of board");
        return NO;
    }
    
    DragStartSq = [self GetTileSquareFromPoint:touchLocation];
    
    if(DragStartSq == -1) {
        NSLog(@"ccTouchBegan() DragStartSq -1");
        return NO;
    }
    
    dragCancelled = NO;
    
    return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    
    if(dragCancelled) {
        NSLog(@"ccTouchMoved() no sq, -1");
        return;
    }
    
    if(isAnimating) {
        NSLog(@"isAnimating return");
        return;
    }

    
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    NSLog(@"ccTouchMoved() touchLocation (%0.f,%0.f)", touchLocation.x, touchLocation.y);
    
    if([self OutOfBoard:touchLocation]) {
        NSLog(@"ccTouchMoved() out of board");
        dragCancelled = YES;
    }
    
    int sqt = [self GetBoardSquareFromPoint:touchLocation];
    NSLog(@"Drag from sq %d to %d", DragStartSq, sqt);
    
    if(DragStartSq != sqt) {
        if([self CanMoveToSq:sqt fromSq:DragStartSq]) {
            NSLog(@"Legal!");
			
			// HACK now calls GetTileIndexFromBoardAtIndex()
            [self ExecuteTileDrag:[self GetTileIndexFromBoardAtIndex:DragStartSq] SquareFrom:DragStartSq SquareTo:sqt];
        } else {
            NSLog(@"Illegal!");
        }
    } 
}

-(BOOL)PlayerWins {
    
    int correct = 0;
	
	NSLog(@"Checking Win");
	[self PrintBoard];	

	// HACK - matching up occ and tileNum
	int tileNum=0;
	
    for(int i = 0; i < 25; ++i) {
		if(boardOcc[i]==kEMPTY) continue;
		if(spriteBoard[tileNum].TileNumber==boardOcc[i]) {
			correct++;
		}
		tileNum++;
    }
    
	NSLog(@"Correct Total %d",correct);
    if(correct == 24) return YES;
    return NO;    
}

-(void)newGame {
    
    inGame = NO;
    isAnimating = NO;
    CGSize size = [[CCDirector sharedDirector] winSize];
    winFace.position = ccp(-size.width, -size.height);
    
}

-(void)WonGame {
    
    [[SimpleAudioEngine sharedEngine] playEffect:@"Cheering.wav"]; 
    
    CGSize size = [[CCDirector sharedDirector] winSize];
    winFace.position = ccp(size.width/2, size.height/2);
    
    id fadeInAction = [CCFadeIn actionWithDuration:1.5f];
    id delayAction = [CCDelayTime actionWithDuration:3.0f];
    id fadeOutAction = [CCFadeOut actionWithDuration:1.0f];
    id callResetFunctions = [CCCallFunc actionWithTarget:self selector:@selector(newGame)];
    
    [winFace runAction:
     [CCSequence actions:fadeInAction, delayAction, fadeOutAction, callResetFunctions, nil]];
}

-(void)dragIsFinished {
    
    [[SimpleAudioEngine sharedEngine] playEffect:@"TileLand.wav"];
    
    if(inGame == YES && [self PlayerWins] == YES) {
        [self WonGame];
        return;
    }
    
    isAnimating = NO;
}

-(void)ExecuteTileDrag:(int)TileIndex SquareFrom:(int)sqf SquareTo:(int)sqto {
    
    NSLog(@"Drag from %d to %d tileIndex:%d",sqf,sqto,TileIndex);
    
    float XposTo = (float)[self GetXCoordFromTileCol:Cols[sqto]];
    float YposTo = (float)[self GetYCoordFromTileRow:Rows[sqto]];
    
    CGPoint toPoint = ccp(XposTo, YposTo);
    
    NSLog(@"Action Goes to %0.f,%0.f",toPoint.x, toPoint.y);
    
    float duration = 0.2f;
    isAnimating = YES;
    
    [[SimpleAudioEngine sharedEngine] playEffect:@"TileSlide.wav"];
    
    id moveAction = [CCMoveTo actionWithDuration:duration position:toPoint];
    id callDragDone = [CCCallFunc actionWithTarget:self selector:@selector(dragIsFinished)];
    
    CCSprite *selectedTile = spriteBoard[TileIndex];
    [selectedTile runAction: [CCSequence actions: moveAction, callDragDone, nil]];
    
    boardOcc[sqto] = boardOcc[sqf];
    boardOcc[sqf] = kEMPTY;
    
    [self PrintBoard];
}

-(void)ResetGame {
    
    float x,y;
    int i = 0,tileNum=0;
    
    for(i = 0; i < 25; ++i) {
        
        x = (float)[self GetXCoordFromTileCol:Cols[i]];
        y = (float)[self GetYCoordFromTileRow:Rows[i]];
		
		// HACK tileNum is now used for our indexing
		if(i != kEMPTY) {        
			spriteBoard[tileNum].position = ccp(x, y);
			tileNum++;
		}
    }
    
    for(i = 0; i < 25; ++i) {        
        boardOcc[i] = i;        
    }   
    
}

-(void)MakeRandomMove {
    
    int count = 0;
    int moveArray[5];
    int sq;
    int EmptySq;
    
    for(sq = 0; sq < 25; ++sq) {
        if(boardOcc[sq] == kEMPTY) {
            EmptySq = sq;
            break;
        }
    }
    
    int rowEmpty = Rows[sq];
    int colEmpty = Cols[sq];
    
    if( rowEmpty < 4)  moveArray[count++] = (sq + 5);
    if( rowEmpty > 0)  moveArray[count++] = (sq - 5);
    if( colEmpty < 4)  moveArray[count++] = (sq + 1);
    if( colEmpty > 0)  moveArray[count++] = (sq - 1);
    
    int randomIndex = arc4random() % count;
    int randomFrom = moveArray[randomIndex];
    
    boardOcc[EmptySq] = boardOcc[randomFrom];
    boardOcc[randomFrom] = kEMPTY;
}

-(void)RandomiseBoardForMoves:(int)numMoves {
    
    [self ResetGame];
    
    for(int move = 0; move < numMoves; ++move) {
        [self MakeRandomMove];
    }
    
    float x,y;
    int tileNum;
    for(int sq = 0; sq < 25; ++sq) {        
 
        if(boardOcc[sq] == kEMPTY) continue;
		
		// HACK if the current boardOcc is > kEmpty, our tilenum is boardOcc - 1
		if(boardOcc[sq] > kEMPTY) tileNum = boardOcc[sq]-1;
		else tileNum = boardOcc[sq];
        
        x = (float)[self GetXCoordFromTileCol:Cols[sq]];
        y = (float)[self GetYCoordFromTileRow:Rows[sq]];
        
        spriteBoard[tileNum].position = ccp(x, y);
    }
}



-(id)init {
    
    self = [super init];
    
    if(self != nil) {
        
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"TileLand.wav"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"TileSlide.wav"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"Cheering.wav"];
        
        _batchNode = [CCSpriteBatchNode batchNodeWithFile:@"TileSpriteSheet.png"];
        [self addChild:_batchNode];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile: @"TileSpriteSheet.plist"];
        
        NSString *fileName;
        float x, y;
        bool isRetina = CC_CONTENT_SCALE_FACTOR() == 2.0f ? true : false;
        int tileNum = 0;
        
        for(int i = 0; i < 25; ++i) {
			
			// HACK now we use tileNum as the index skipping kEMPTY
			if(i!=kEMPTY) {
            
				fileName = [NSString stringWithFormat:@"tile%d%@.png", tileNum+1, isRetina ? @"-ipadhd" : @""];
			
				spriteBoard[tileNum] = [GameTile spriteWithSpriteFrameName:fileName];
            
				x = (float)[self GetXCoordFromTileCol:Cols[i]];
				y = (float)[self GetYCoordFromTileRow:Rows[i]];			
            
				spriteBoard[tileNum].anchorPoint = ccp(0, 0);
				spriteBoard[tileNum].position = ccp(x, y);
				spriteBoard[tileNum].TileNumber = i;
			
				[_batchNode addChild:spriteBoard[tileNum] z:1];
				tileNum++;
			}
            
            boardOcc[i] = i;
		}
        
        //boardOcc[24] = kEMPTY;
        [self PrintBoard];
        
        hardButton = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"HardButton%@.png", isRetina ? @"-ipadhd" : @""]];
        hardButton.anchorPoint = ccp(0,0);
        hardButton.position = ccp(5,50);
        [_batchNode addChild:hardButton z:1];
        
        resetButton = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"ResetButton%@.png", isRetina ? @"-ipadhd" : @""]];
        resetButton.anchorPoint = ccp(0,0);
        resetButton.position = ccp(5,669);
        [_batchNode addChild:resetButton z:1];
        
        easyButton = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"EasyButton%@.png", isRetina ? @"-ipadhd" : @""]];
        easyButton.anchorPoint = ccp(0,0);
        easyButton.position = ccp(5,110);
        [_batchNode addChild:easyButton z:1];
        
        CGSize size = [[CCDirector sharedDirector] winSize];
        winFace = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"WinFace%@.png", isRetina ? @"-ipadhd" : @""]];
        winFace.position = ccp(-size.width, -size.height);
        [_batchNode addChild:winFace z:2];
                                       
        self.isTouchEnabled = YES;
        
    }
    
    return self;
}


@end
