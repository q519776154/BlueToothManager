//
//  BlueToothManager.m
//  蓝牙
//
//  Created by yyh on 16/10/14.
//  Copyright © 2016年 Ahui. All rights reserved.
//

#import "BlueToothManager.h"

//服务的UUID
#define kServiceUUID @"00000aF0-0000-1000-8000-00805f9b34fb"

@interface BlueToothManager ()<CBCentralManagerDelegate, CBPeripheralDelegate>

//中心角色管理对象
@property (nonatomic, strong) CBCentralManager *centralManager;


/**
 扫描到的外部设备
 */
@property (nonatomic, strong) NSMutableArray *peripheralArray;


/**
 所有的特征
 */
@property (nonatomic, strong) NSMutableArray *characteristicArray;


/**
 连接的外部设备对象
 */
@property (nonatomic, strong) CBPeripheral *peripheral;

@end

@implementation BlueToothManager

+ (instancetype)shareManager
{
    static BlueToothManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    
    return manager;
}

- (NSMutableArray *)characteristicArray
{
    if (!_characteristicArray)
    {
        _characteristicArray = [NSMutableArray array];
    }
    
    return _characteristicArray;
}

- (NSMutableArray *)peripheralArray
{
    if (!_peripheralArray)
    {
        _peripheralArray = [NSMutableArray array];
    }
    
    return _peripheralArray;
}

/**
 开始扫描
 */
- (void)scan
{
    //创建中心角色对象，初始化完后代理方法就会触发
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
}

/**
 连接外部设备
 
 @param peripheral <#peripheral description#>
 */
- (void)connect:(CBPeripheral *)peripheral
{
    //连接指定的外部设备对象
    [self.centralManager connectPeripheral:peripheral options:nil];
}

/**
 发送数据
 
 @param data       <#data description#>
 @param uuidString <#uuidString description#>
 */
- (void)writeData:(NSData *)data characteristicUUIDString:(NSString *)uuidString type:(CBCharacteristicWriteType)type
{
    //获取CBCharacteristic
    CBCharacteristic *c = [self characteristicWithUUIDString:uuidString];
    
    if (!c)
    {
        return;
    }
    
    //发送数据
    [self.peripheral writeValue:data forCharacteristic:c type:type];
}


/**
 根据uuidstring获取CBCharacteristic

 @param uuidString <#uuidString description#>

 @return <#return value description#>
 */
- (CBCharacteristic *)characteristicWithUUIDString:(NSString *)uuidString
{
    for (CBCharacteristic *c in self.characteristicArray)
    {
        if ([c.UUID.UUIDString isEqualToString:uuidString])
        {
            return c;
        }
    }
    
    return nil;
}

#pragma mark - CBCentralManagerDelegate

/**
 获取蓝牙状态

 @param central <#central description#>
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBManagerStateUnsupported)
    {
        NSLog(@"目前手机不支持蓝牙4.0");
        
        return;
    }
    else if (central.state == CBManagerStatePoweredOff)
    {
        NSLog(@"请先打开蓝牙");
        
        return;
    }
    else if (central.state == CBManagerStatePoweredOn)
    {
        NSLog(@"蓝牙已经打开");
        
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:kServiceUUID];
        
        //开始扫描
        /*
         第1个参数：指定扫描外设的UUID,如果传nil表示扫描所有的外部设备
         */
        [_centralManager scanForPeripheralsWithServices:@[uuid] options:nil];
    }
}


/**
 已经扫描到外部设备

 @param central           <#central description#>
 @param peripheral        <#peripheral description#>
 @param advertisementData <#advertisementData description#>
 @param RSSI              <#RSSI description#>
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    //获取到外部设备的名字
    NSString *name = peripheral.name;
    NSLog(@"%@",name);
    
    //保存扫描的外部设备对象
    if (![self.peripheralArray containsObject:peripheral])
    {
        [self.peripheralArray addObject:peripheral];
    }
    
    //扫描结果的回调
    if (self.peripheralArray.count > 0 && self.blueToothDidScanPeripheralsCallback)
    {
        _blueToothDidScanPeripheralsCallback(self.peripheralArray);
    }
}


/**
 已经连接成功

 @param central    <#central description#>
 @param peripheral <#peripheral description#>
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //1.连接的外部设备
    self.peripheral = peripheral;
    
    //2.设置外部设备的代理
    self.peripheral.delegate = self;
    
    //3.扫描外部设备的服务
    [self.peripheral discoverServices:nil];
}


/**
 扫描到外部设备的服务

 @param peripheral <#peripheral description#>
 @param error      <#error description#>
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    //1.获取外部设备所有的服务
    NSArray *servies = peripheral.services;
    
    //2.遍历服务
    for (CBService *service in servies)
    {
        //3.扫描服务中的特征
        [peripheral discoverCharacteristics:nil forService:service];
    }
}


/**
 扫描到服务中的特征

 @param peripheral <#peripheral description#>
 @param service    <#service description#>
 @param error      <#error description#>
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{
    //1.获取服务中的特征
    NSArray *characteristicsArr = service.characteristics;
    
    //2.遍历特征
    for (CBCharacteristic *c in characteristicsArr)
    {
        if (![self.characteristicArray containsObject:c])
        {
            //3.添加特征
            [self.characteristicArray addObject:c];
        }
    }
}


/**
 发送数据成功

 @param peripheral     <#peripheral description#>
 @param characteristic <#characteristic description#>
 @param error          <#error description#>
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"向外部设备发送数据，发送成功了");
}


/**
 收到外部设备发来的数据会触发

 @param peripheral     <#peripheral description#>
 @param characteristic <#characteristic description#>
 @param error          <#error description#>
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    //1.获取外部设备的数据
    NSData *value = characteristic.value;
    
    //2.回调
    if (_blueToothDidUpdateValueCallback)
    {
        _blueToothDidUpdateValueCallback(characteristic, value);
    }
}


@end
