Class {
	#name : 'TestI2cDeviceADXL345Accelerometer',
	#superclass : 'TestCase',
	#instVars : [
		'gpioInterface',
		'device'
	],
	#category : 'RaspberryHardwareInterfaceTestApp'
}

{ #category : 'Examples' }
TestI2cDeviceADXL345Accelerometer class >> printCoordinatesFor: seconds on: aStream [
	
	| gpioInterface device |

	[
		gpioInterface := RaspberryGpioDaemonInterface raspberryGpioStart.
		device :=
			gpioInterface
				createI2cDevice: I2cDeviceADXL345Accelerometer
				slaveAddress: I2cDeviceADXL345Accelerometer defaultI2CAddress.
		aStream
			show: 'Accelerometer X, Y, Z';
			cr.
		seconds timesRepeat: [| coordinates |
			coordinates := device readCoordinates.
			aStream
				show: 'X=' , coordinates first asString;
				show: ', Y=' , coordinates second asString;
				show: ', Z=' , coordinates third asString;
				cr.
			(Delay forSeconds: 1) wait]]
				ensure: [gpioInterface shutDown]
]

{ #category : 'Examples' }
TestI2cDeviceADXL345Accelerometer class >> printCoordinatesToTranscriptFor10secs [

	TestI2cDeviceADXL345Accelerometer printCoordinatesFor: 10 on: TranscriptTTY default
]

{ #category : 'Helpers' }
TestI2cDeviceADXL345Accelerometer >> createI2cDevice [

	device :=
		gpioInterface
			createI2cDevice: I2cDeviceADXL345Accelerometer
			slaveAddress: I2cDeviceADXL345Accelerometer defaultI2CAddress
]

{ #category : 'Running' }
TestI2cDeviceADXL345Accelerometer >> setUp [

	gpioInterface := RaspberryGpioDaemonInterface raspberryGpioStart

]

{ #category : 'Running' }
TestI2cDeviceADXL345Accelerometer >> tearDown [

	gpioInterface shutDown
]

{ #category : 'Tests' }
TestI2cDeviceADXL345Accelerometer >> testConnection [

	self shouldnt: [self createI2cDevice] raise: Error.
	self assert: (device isKindOf: I2cDeviceADXL345Accelerometer)
]

{ #category : 'Tests' }
TestI2cDeviceADXL345Accelerometer >> testReadCoordinates [

	self createI2cDevice.
	self assert: device readCoordinates isArray.
	self assert: device readCoordinates size equals: 3.
	device readCoordinates do: [:each | each isInteger]
]
