//
//  HelloWorldLayer.m
//  TrigBlaster
//
//  Created by Ryan Salton on 30/04/2013.
//  Copyright __MyCompanyName__ 2013. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

const float MaxPlayerAccel = 400.0;
const float MaxPlayerSpeed = 200.0;
const float BorderCollisionDamping = 3.0f;
const float HealthBarWidth = 40.0;
const float HealthBarHeight = 4.0;
const int MaxHP = 100;

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer
{
    CGSize _winSize;
    CCSprite *_playerSprite;
    CCSprite *_cannonSprite;
    CCSprite *_turretSprite;
    UIAccelerationValue _accelerometerX;
    UIAccelerationValue _accelerometerY;
    float _playerAccelX;
    float _playerAccelY;
    float _playerSpeedX;
    float _playerSpeedY;
    float _playerAngle;
    float _turretAngle;
    float _lastAngle;
    float _lastTurAngle;
    int _playerHP;
    int _cannonHP;
    CCDrawNode *_playerHeathBar;
    CCDrawNode *_cannonHealthBar;
}

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	HelloWorldLayer *layer = [HelloWorldLayer node];
	[scene addChild: layer];
	return scene;
}

-(id)init
{
    if((self = [super initWithColor:ccc4(94, 63, 107, 255)]))
    {
        _winSize = [CCDirector sharedDirector].winSize;
        
        _cannonSprite = [CCSprite spriteWithFile:@"Cannon.png"];
        _cannonSprite.position = ccp(_winSize.width/2.0, _winSize.height/2.0);
        [self addChild:_cannonSprite];
        
        _turretSprite = [CCSprite spriteWithFile:@"Turret.png"];
        _turretSprite.position = ccp(_winSize.width/2.0, _winSize.height/2.0);
        [self addChild:_turretSprite];
        
        _playerSprite = [CCSprite spriteWithFile:@"Player.png"];
        _playerSprite.position = ccp(_winSize.width - 50.0, 50.0);
        [self addChild:_playerSprite];
        
        self.isAccelerometerEnabled = YES;
        [self scheduleUpdate];
    }
    return self;
}

-(void)update:(ccTime)dt
{
    [self updatePlayer:dt];
    [self updateTurret:dt];
}

-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    const double FilteringFactor = 0.75;
    
    NSLog(@"%f",acceleration.x);
    _accelerometerX = (acceleration.x + 0.55) * FilteringFactor + _accelerometerX * (1.0 - FilteringFactor);
    _accelerometerY = acceleration.y * FilteringFactor + _accelerometerY * (1.0 - FilteringFactor);
    
    if(_accelerometerY > 0.05)
    {
        _playerAccelX = -MaxPlayerAccel;
    }
    else if(_accelerometerY < -0.05)
    {
        _playerAccelX = MaxPlayerAccel;
    }
    if(_accelerometerX < -0.05)
    {
        _playerAccelY = -MaxPlayerAccel;
    }
    if(_accelerometerX > 0.05)
    {
        _playerAccelY = MaxPlayerAccel;
    }
}

-(void)updatePlayer:(ccTime)dt
{
    _playerSpeedX += _playerAccelX * dt;
    _playerSpeedY += _playerAccelY * dt;
    
    _playerSpeedX = fmaxf(fminf(_playerSpeedX, MaxPlayerSpeed), -MaxPlayerSpeed);
    _playerSpeedY = fmaxf(fminf(_playerSpeedY, MaxPlayerSpeed), -MaxPlayerSpeed);
    
    float newX = _playerSprite.position.x + _playerSpeedX * dt;
    float newY = _playerSprite.position.y + _playerSpeedY * dt;
    
//    newX = MIN(_winSize.width, MAX(newX, 0));
//    newY = MIN(_winSize.height, MAX(newY, 0));

    BOOL collidedWithVerticalBorder = NO;
    BOOL collidedWithHorizontalBorder = NO;
    
    if (newX < 0.0f)
    {
        newX = 0.0f;
        collidedWithVerticalBorder = YES;
    }
    else if (newX > _winSize.width)
    {
        newX = _winSize.width;
        collidedWithVerticalBorder = YES;
    }
    if (newY < 0.0f)
    {
        newY = 0.0f;
        collidedWithHorizontalBorder = YES;
    }
    else if (newY > _winSize.height)
    {
        newY = _winSize.height;
        collidedWithHorizontalBorder = YES;
    }
    if (collidedWithVerticalBorder)
    {
        _playerAccelX = -_playerAccelX * BorderCollisionDamping;
        _playerSpeedX = -_playerSpeedX * BorderCollisionDamping;
        _playerAccelY = _playerAccelY * BorderCollisionDamping;
        _playerSpeedY = _playerSpeedY * BorderCollisionDamping;
    }
    if (collidedWithHorizontalBorder)
    {
        _playerAccelX = _playerAccelX * BorderCollisionDamping;
        _playerSpeedX = _playerSpeedX * BorderCollisionDamping;
        _playerAccelY = -_playerAccelY * BorderCollisionDamping;
        _playerSpeedY = -_playerSpeedY * BorderCollisionDamping;
    }
    
    _playerSprite.position = ccp(newX, newY);
    
    float speed = sqrtf(_playerSpeedX*_playerSpeedX + _playerSpeedY*_playerSpeedY);
    if(speed > 40.0)
    {
        float angle = atan2f(_playerSpeedY, _playerSpeedX);
        
        if(_lastAngle < -3.0 && angle > 3.0)
        {
            _playerAngle += M_PI * 2.0;
        }
        else if(_lastAngle > 3.0 && angle < -3.0)
        {
            _playerAngle -= M_PI * 2.0;
        }
        
        _lastAngle = angle;
        const float RotationBlendFactor = 0.1;
        _playerAngle = angle * RotationBlendFactor + _playerAngle * (1.0 - RotationBlendFactor);
    }
    _playerSprite.rotation = 90.0 - CC_RADIANS_TO_DEGREES(_playerAngle);
}

-(void)updateTurret:(ccTime)dt
{
    float deltaX = _playerSprite.position.x - _turretSprite.position.x;
    float deltaY = _playerSprite.position.y - _turretSprite.position.y;
    
    float angle = atan2f(deltaY, deltaX);
    
    if(_lastTurAngle < -3.0 && angle > 3.0)
    {
        _turretAngle += M_PI * 2.0;
    }
    else if(_lastTurAngle > 3.0 && angle < -3.0)
    {
        _turretAngle -= M_PI * 2.0;
    }
    
    _lastTurAngle = angle;
    
    const float RotationBlendFactor = 0.04;
    _turretAngle = angle * RotationBlendFactor + _turretAngle * (1.0 - RotationBlendFactor);
    
    _turretSprite.rotation = 90.0 - CC_RADIANS_TO_DEGREES(_turretAngle);
}

@end
