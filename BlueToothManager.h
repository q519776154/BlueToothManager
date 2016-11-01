//
//  BlueToothManager.h
//  蓝牙
//
//  Created by yyh on 16/10/14.
//  Copyright © 2016年 Ahui. All rights reserved.
//

/*
 1.创建中心角色
 2.扫描外部设备
 3.连接外部设备
 4.扫描外部设备中服务和特征。
 5.发送或者接收数据
 6.蓝牙断开
 */

#import <Foundation/Foundation.h>
//导入头文件
#import <CoreBluetooth/CoreBluetooth.h>


//扫描到外部设备的回调
typedef void(^BlueToothDidScanPeripheralsCallback)(NSArray *peripherals);

//收到外部设备的数据的回调
typedef void(^BlueToothDidUpdateValueCallback)(CBCharacteristic *characteristic, NSData *value);

@interface BlueToothManager : NSObject

+ (instancetype)shareManager;

//扫描到外部设置的回调
@property (nonatomic, copy) BlueToothDidScanPeripheralsCallback blueToothDidScanPeripheralsCallback;
//收到外部设备的数据的回调
@property (nonatomic, copy) BlueToothDidUpdateValueCallback blueToothDidUpdateValueCallback;

//设置扫描到外部设置的回调
- (void)setBlueToothDidScanPeripheralsCallback:(BlueToothDidScanPeripheralsCallback)blueToothDidScanPeripheralsCallback;
//设置收到外部设备的数据的回调
- (void)setBlueToothDidUpdateValueCallback:(BlueToothDidUpdateValueCallback)blueToothDidUpdateValueCallback;


/**
 开始扫描
 */
- (void)scan;


/**
 连接外部设备

 @param peripheral <#peripheral description#>
 */
- (void)connect:(CBPeripheral *)peripheral;


/**
 发送数据

 @param data       <#data description#>
 @param uuidString <#uuidString description#>
 */
- (void)writeData:(NSData *)data characteristicUUIDString:(NSString *)uuidString type:(CBCharacteristicWriteType)type;

@end
