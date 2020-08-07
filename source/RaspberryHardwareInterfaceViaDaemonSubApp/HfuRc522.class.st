"
The following tutorial and python libary has been used as a reference:
https://pimylifeup.com/raspberry-pi-rfid-rc522/
https://github.com/pimylifeup/MFRC522-python

For wiring and assembly, you can see:

https://medium.com/coinmonks/for-beginners-how-to-set-up-a-raspberry-pi-rfid-rc522-reader-and-record-data-on-iota-865f67843a2d
https://www.raspberrypi-spy.co.uk/2018/02/rc522-rfid-tag-read-raspberry-pi/
https://medium.com/@rfkledig/writing-data-on-a-rfid-tag-40b5083794a6

Below is an example:

| theHandler theDevice |
theHandler := RaspberryGpioDaemonInterface raspberryGpioStart.
theDevice := theHandler createSpiDevice: HfuSimpleRc522 channel: 0 speed: 1000000 flags: 0.

theDevice writeStringToCard: 'Hello'.
theDevice readCardAsString
"
Class {
	#name : 'HfuRc522',
	#superclass : 'SpiDevice',
	#instVars : [
		'resetPin'
	],
	#classVars : [
		'PCD_TRANSMIT',
		'PCD_AUTHENT',
		'Status1Reg',
		'PICC_DECREMENT',
		'PICC_READ',
		'Reserved33',
		'Reserved12',
		'MifareReg',
		'TxSelReg',
		'PCD_TRANSCEIVE',
		'WaterLevelReg',
		'PICC_TRANSFER',
		'DivIrqReg',
		'PICC_INCREMENT',
		'PICC_AUTHENT1B',
		'MI_OK',
		'AnalogTestReg',
		'Reserved21',
		'TCounterValueRegL',
		'CRCResultRegL',
		'ModWidthReg',
		'MI_NOTAGERR',
		'TestADCReg',
		'PICC_AUTHENT1A',
		'ControlReg',
		'PCD_RESETPHASE',
		'Reserved32',
		'PICC_REQIDL',
		'TestSel2Reg',
		'Reserved20',
		'ErrorReg',
		'Status2Reg',
		'FIFODataReg',
		'CommIrqReg',
		'TCounterValueRegH',
		'TestPinEnReg',
		'TReloadRegL',
		'Reserved01',
		'Reserved11',
		'GsNReg',
		'AutoTestReg',
		'TReloadRegH',
		'PICC_ANTICOLL',
		'RFCfgReg',
		'PICC_WRITE',
		'TModeReg',
		'DivlEnReg',
		'TestBusReg',
		'TxModeReg',
		'PICC_RESTORE',
		'Reserved00',
		'CWGsPReg',
		'Reserved10',
		'PCD_RECEIVE',
		'TxAutoReg',
		'BitFramingReg',
		'Reserved14',
		'DemodReg',
		'ModGsPReg',
		'PICC_HALT',
		'Reserved31',
		'PCD_IDLE',
		'Reserved22',
		'TestSel1Reg',
		'CollReg',
		'ModeReg',
		'TxControlReg',
		'CRCResultRegM',
		'PCD_CALCCRC',
		'RxModeReg',
		'Reserved13',
		'RxThresholdReg',
		'TestDAC2Reg',
		'Reserved30',
		'CommIEnReg',
		'PICC_SElECTTAG',
		'PICC_REQALL',
		'FIFOLevelReg',
		'Reserved34',
		'CommandReg',
		'SerialSpeedReg',
		'TestDAC1Reg',
		'TPrescalerReg',
		'RxSelReg',
		'MI_ERR',
		'TestPinValueReg',
		'VersionReg'
	],
	#category : 'RaspberryHardwareInterfaceViaDaemonSubApp'
}

{ #category : 'Not categorized' }
HfuRc522 >> antennaOff [
	"Turns the RFID antenna off"
	| temporaries |
	
	self clearBitMask: TxControlReg mask: 16r03.
]

{ #category : 'Not categorized' }
HfuRc522 >> antennaOn [
	"Turns the RFID antenna on"
	| temporaries |
	
	temporaries := (self readFromModule: TxControlReg).
	(((temporaries bitAnd: 16r03) bitInvert) isZero) not
		ifTrue: [ 
			self setBitMask: TxControlReg mask: 16r03 ].
]

{ #category : 'Not categorized' }
HfuRc522 >> antiCollision [
	"Anti Collision"
	| theBackData theStatus theSerialNumberCheck theSerialNumber theResultFromCard theIterator theResult |
	
	theBackData := OrderedCollection new.
	theSerialNumber := OrderedCollection new.
	theResult := Dictionary new.
	theSerialNumberCheck := 0.

	self writeToModule: BitFramingReg value: 0.
	
	theSerialNumber add: PICC_ANTICOLL.
	theSerialNumber add: 16r20.
	
	theResultFromCard := (self commandToCard: PCD_TRANSCEIVE data: theSerialNumber).
	theBackData := (theResultFromCard at: 'backData'). 
	theStatus := (theResultFromCard at: 'status').
	
	(theStatus = MI_OK)
	ifTrue: [
		theIterator := 1.
		(theBackData size) = 5
		ifTrue: [
			[theIterator < 5] whileTrue:[
				theSerialNumberCheck := theSerialNumberCheck bitXor: (theBackData at: theIterator).
				theIterator := theIterator + 1].
		
			((theSerialNumberCheck = (theBackData at: 5)) not)
			ifTrue: [
				theStatus := MI_ERR].
		]
		ifFalse: [
			theStatus := MI_ERR].
	].
	theResult at: 'status' put: theStatus.
	theResult at: 'backData' put: theBackData.
	
	^theResult.
	
]

{ #category : 'Not categorized' }
HfuRc522 >> authentication: aMode blockAddress: aBLockAdress sectorKey: aKey serialNumber: aSerialNumber [
	"Authentication"
	| theBuffer theIterator theStatus |

	theBuffer := OrderedCollection new.
	
	"First byte should be the authMode (A or B)"
	theBuffer add: aMode.
	
	"Second byte is the trailerBlock (usually 7)"
	theBuffer add: aBLockAdress.
	
	"Now we need to append the authKey which usually is 6 bytes of 0xFF"
	aKey do: [ :eachElement |
		theBuffer add: eachElement].
	
	"Next we append the first 4 bytes of the UID"
	theIterator := 1.
	[theIterator < 5] whileTrue: [
		theBuffer add: (aSerialNumber at: theIterator).
		theIterator := theIterator + 1].
	
	theStatus := ((self commandToCard: PCD_AUTHENT data: theBuffer) at: 'status').
	
	((theStatus = MI_OK) not) 
	ifTrue: [
		Transcript show: 'AUTH ERROR!!!'].
	
	^theStatus
]

{ #category : 'Not categorized' }
HfuRc522 >> calculateCRC: aInData [
	"Calculates a CRC"
	| theIterator theOutData theReadResult |
	
	theOutData := OrderedCollection new.
	
	self clearBitMask: DivIrqReg mask: 16r04.
	self setBitMask: FIFOLevelReg mask: 16r80.
	
	aInData do: [:eachElement |
		self writeToModule: FIFODataReg value: eachElement].
	
	self writeToModule: CommandReg value: PCD_CALCCRC.
	
	theIterator := 16rFF.
	theReadResult := 0.
	[((theIterator isZero not) and: [((theReadResult bitAnd: 16r04) == 4)])] whileFalse: [
		theReadResult := self readFromModule: DivIrqReg.
		theIterator := theIterator - 1].
	
	theOutData add: (self readFromModule: CRCResultRegL).
	theOutData add: (self readFromModule: CRCResultRegM).
	
	^theOutData. 
]

{ #category : 'Not categorized' }
HfuRc522 >> clearBitMask: aRegister mask: aMask [
	"clears a BitMask from a adress"
	| temporaries |
	temporaries := self readFromModule: aRegister.
	self writeToModule: aRegister value: (temporaries bitAnd: (aMask bitInvert)).
]

{ #category : 'Not categorized' }
HfuRc522 >> close [
	"Sends closes the connection to the reader"
	| temporaries |
	
]

{ #category : 'Not categorized' }
HfuRc522 >> commandToCard: aCommand data: aData [
	"Sends command and data to a card"
	| theResult theBackData theBackLen theStatus theIrqEn theWaitIrq theLastBits theTries theReadResult theDelay |
	
	theResult := Dictionary new.
	theBackLen := 0.
	theStatus := MI_ERR.
	theIrqEn := 0.
	theWaitIrq := 0.
	theLastBits := 0.
	theTries := 0.
	theReadResult := 0.
	theBackData := OrderedCollection new.
	theDelay := Delay forMilliseconds: 5.
	
	aCommand = PCD_AUTHENT
	ifTrue: [
		theIrqEn := 16r12.
		theWaitIrq := 16r10].
	
	aCommand = PCD_TRANSCEIVE
	ifTrue: [
		theIrqEn := 16r77.
		theWaitIrq := 16r30].
	
	self writeToModule: CommIEnReg value: (theIrqEn bitOr: 16r80).
	self clearBitMask: CommIrqReg mask: 16r80.
	self setBitMask: FIFOLevelReg mask: 16r80.
	
	self writeToModule: CommandReg value: PCD_IDLE.
	
	aData do: [:eachElement |
		self writeToModule: FIFODataReg value: (eachElement)].
	
	self writeToModule: CommandReg value: aCommand.
	
	aCommand = PCD_TRANSCEIVE
	ifTrue: [
		self setBitMask: BitFramingReg mask: 16r80.
		theDelay wait.].
	
	theTries := 1000.
	theReadResult := self readFromModule: CommIrqReg.
	"~((i != 0) and ~(n & 0x01) and ~(n & waitIRq))"
	[(((theTries isZero) not) and: [((((theReadResult bitAnd: 1) bitInvert) isZero) not) and: [((((theReadResult bitAnd: theWaitIrq) bitInvert) isZero) not)]]) not] whileTrue: [
		theReadResult := self readFromModule: CommIrqReg.
		theTries := theTries - 1].
	
	self clearBitMask: BitFramingReg mask: 16r80.
	
	((theTries isZero) not)
	ifTrue: [
		((self readFromModule: ErrorReg) bitAnd: 16r1B) = 0
		ifTrue: [
			theStatus := MI_OK.
			
			(((theReadResult bitAnd: (theIrqEn bitAnd: 16r01)) isZero) not)
			ifTrue: [
				theStatus := MI_NOTAGERR].
			
			aCommand = PCD_TRANSCEIVE
			ifTrue: [
				theReadResult := (self readFromModule: FIFOLevelReg).
				theLastBits := ((self readFromModule: ControlReg) bitAnd: 16r07).
				theDelay wait.
				
				((theLastBits isZero) not)
				ifTrue: [
					theBackLen := ((theReadResult - 1) * 8) + theLastBits]
				ifFalse: [
					theBackLen := theReadResult * 8].
				
				(theReadResult isZero)
				ifTrue: [
					theReadResult := 1].
				
				(theReadResult > 16)
				ifTrue: [
					theReadResult := 16].
				
				
				
				theTries := 0.
				[theTries < theReadResult] whileTrue: [
					theBackData add: (self readFromModule: FIFODataReg).
					theTries := theTries + 1].
			].
		]
		ifFalse: [
			theStatus := MI_ERR]. 
	].

	theResult at: 'status' put: (theStatus).
	theResult at: 'backData' put: (theBackData).
	theResult at: 'backLen' put: (theBackLen).
	
	^theResult
]

{ #category : 'Not categorized' }
HfuRc522 >> dumpClassic: key uId: aId [
	"Prints all data from a classic 1K"
	| temporaries |
]

{ #category : 'Not categorized' }
HfuRc522 >> isUndefined [
	^false
]

{ #category : 'Not categorized' }
HfuRc522 >> moduleInit [
	"Starts the Module"
	| temporaries |
	
	self reset.
	
	self writeToModule: TModeReg value: 16r8D.
	self writeToModule: TPrescalerReg value: 16r3E.
	self writeToModule: TReloadRegL value: 30.
	self writeToModule: TReloadRegH value: 0.
	
	self writeToModule: TxAutoReg value: 16r40.
	self writeToModule: ModeReg value: 16r3D.
	
	self antennaOn.
]

{ #category : 'Not categorized' }
HfuRc522 >> readFromCard: aBlockAdress [
	"Reads from cards Block Adress"
	| theBuffer theOut theResult theStatus theBackData |
	
	theBuffer := OrderedCollection new.
	theBuffer add: PICC_READ.
	theBuffer add: aBlockAdress.
	
	theOut := self calculateCRC: theBuffer.
	
	theBuffer add: (theOut at: 1).
	theBuffer add: (theOut at: 2).
	
	theResult := self commandToCard: PCD_TRANSCEIVE data: theBuffer.
	theStatus := (theResult at: 'status').
	theBackData := (theResult at: 'backData').
	
	((theResult at: 'status') = MI_OK and: [theBackData size = 16])
	ifTrue: [^theBackData]
	ifFalse: [^nil].
]

{ #category : 'Not categorized' }
HfuRc522 >> readFromModule: anAdress [
	"Reads data from the Modul"
	^(bus readBytesUsingBuffer: (ByteArray with: (((anAdress bitShift: 1) bitAnd: 16r7E) bitOr: 16r80) with: 0)) at: 2.
	
]

{ #category : 'Not categorized' }
HfuRc522 >> request: aRequestMode [
	"Sends a request"
	| theStatus theBackBits theTagType theResultFromCard theResult |
	
	theStatus := 0.
	theBackBits := 0.
	theTagType := OrderedCollection new.
	theResult := Dictionary new.
	
	self writeToModule: BitFramingReg value: 16r07.
	
	theTagType add: aRequestMode.
	
	theResultFromCard := self commandToCard: PCD_TRANSCEIVE data: theTagType.
	theStatus := (theResultFromCard at: 'status').
	
	"
	theResult at: 'status' put: (theStatus).
	theResult at: 'backData' put: (theBackData).
	theResult at: 'backLen' put: (theBackLen).
	"
	
	((theStatus = MI_OK) not or: [((theResultFromCard at: 'backLen') = 16r10) not])
	ifTrue: [theStatus = MI_ERR].
	
	theResult at: 'status' put: theStatus.
	theResult at: 'backLen' put: (theResultFromCard at: 'backLen').
	
	^theResult.
]

{ #category : 'Not categorized' }
HfuRc522 >> reset [
	"Send a Reset Command to the Reader"
	| temporaries |
	
	self writeToModule: CommandReg value: PCD_RESETPHASE.
]

{ #category : 'Not categorized' }
HfuRc522 >> selectTag: aSerialnumber [
	"Selects a tag"
	| theBuffer theResultFromCard theIterator theOut |
	
	theBuffer := OrderedCollection new.
	theBuffer add: PICC_SElECTTAG.
	theBuffer add: 16r70.
	
	theIterator := 1.
	"[theIterator < 6] whileTrue: [
		theBuffer add: (aSerialnumber at: theIterator).
		theIterator := theIterator + 1]."
		
	aSerialnumber do: [:eachElement |
		theBuffer add: eachElement].
	
	theOut := self calculateCRC: theBuffer.
	
	theBuffer add: (theOut at: 1).
	theBuffer add: (theOut at: 2).
	
	theResultFromCard := self commandToCard: PCD_TRANSCEIVE data: theBuffer.
	
	(((theResultFromCard at: 'status') = MI_OK) and: [((theResultFromCard at: 'backLen') = 16r18)])
	ifTrue: [
		^((theResultFromCard at: 'backData') at: 1)]
	ifFalse: [^0].
]

{ #category : 'Not categorized' }
HfuRc522 >> setBitMask: aRegister mask: aMask [
	"Sends a BitMask to an adress"
	| temporaries |
	temporaries := self readFromModule: aRegister.
	self writeToModule: aRegister value: (temporaries bitOr: aMask).
]

{ #category : 'Not categorized' }
HfuRc522 >> spiBus: anSpiBus [
	| buff |
	
	bus := anSpiBus.
	
	resetPin := 25.
	Transcript show: 'Hello'.
	
	(bus interface) pinSetAsOutput: resetPin.
	(bus interface) pin: resetPin write: 1.
	
	PCD_IDLE := 16r00.
	PCD_AUTHENT := 16r0E.
	PCD_RECEIVE := 16r08.
	PCD_TRANSMIT := 16r04.
	PCD_TRANSCEIVE := 16r0C.
	PCD_RESETPHASE := 16r0F.
	PCD_CALCCRC := 16r03.
	PICC_REQIDL := 16r26.
	PICC_REQALL := 16r52.
	PICC_ANTICOLL := 16r93.
	PICC_SElECTTAG := 16r93.
	PICC_AUTHENT1A := 16r60.
	PICC_AUTHENT1B := 16r61.
	PICC_READ := 16r30.
	PICC_WRITE := 16rA0.
	PICC_DECREMENT := 16rC0.
	PICC_INCREMENT := 16rC1.
	PICC_RESTORE := 16rC2.
	PICC_TRANSFER := 16rB0.
	PICC_HALT := 16r50.
	MI_OK := 0.
	MI_NOTAGERR := 1.
	MI_ERR := 2.
	Reserved00 := 16r00.
	CommandReg := 16r01.
	CommIEnReg := 16r02.
	DivlEnReg := 16r03.
	CommIrqReg := 16r04.
	DivIrqReg := 16r05.
	ErrorReg := 16r06.
	Status1Reg := 16r07.
	Status2Reg := 16r08.
	FIFODataReg := 16r09.
	FIFOLevelReg := 16r0A.
	WaterLevelReg := 16r0B.
	ControlReg := 16r0C.
	BitFramingReg := 16r0D.
	CollReg := 16r0E.
	Reserved01 := 16r0F.
	Reserved10 := 16r10.
	ModeReg := 16r11.
	TxModeReg := 16r12.
	RxModeReg := 16r13.
	TxControlReg := 16r14.
	TxAutoReg := 16r15.
	TxSelReg := 16r16.
	RxSelReg := 16r17.
	RxThresholdReg := 16r18.
	DemodReg := 16r19.
	Reserved11 := 16r1A.
	Reserved12 := 16r1B.
	MifareReg := 16r1C.
	Reserved13 := 16r1D.
	Reserved14 := 16r1E.
	SerialSpeedReg := 16r1F.
	Reserved20 := 16r20.
	CRCResultRegM := 16r21.
	CRCResultRegL := 16r22.
	Reserved21 := 16r23.
	ModWidthReg := 16r24.
	Reserved22 := 16r25.
	RFCfgReg := 16r26.
	GsNReg := 16r27.
	CWGsPReg := 16r28.
	ModGsPReg := 16r29.
	TModeReg := 16r2A.
	TPrescalerReg := 16r2B.
	TReloadRegH := 16r2C.
	TReloadRegL := 16r2D.
	TCounterValueRegH := 16r2E.
	TCounterValueRegL := 16r2F.
	Reserved30 := 16r30.
	TestSel1Reg := 16r31.
	TestSel2Reg := 16r32.
	TestPinEnReg := 16r33.
	TestPinValueReg := 16r34.
	TestBusReg := 16r35.
	AutoTestReg := 16r36.
	VersionReg := 16r37.
	AnalogTestReg := 16r38.
	TestDAC1Reg := 16r39.
	TestDAC2Reg := 16r3A.
	TestADCReg := 16r3B.
	Reserved31 := 16r3C.
	Reserved32 := 16r3D.
	Reserved33 := 16r3E.
	Reserved34 := 16r3F.
	
	self moduleInit.
	
]

{ #category : 'Not categorized' }
HfuRc522 >> stopCrypto [
	"Stops Crypto 1"
	| temporaries |
	
	self clearBitMask: Status2Reg mask: 16r08.
]

{ #category : 'Not categorized' }
HfuRc522 >> writeToCard: anAdress data: aData [
	"Writes Data To Card"
	| theBuffer theRedundancyCheck theCommandResult theStatus theBackLen theBackData |
	
	theBuffer := OrderedCollection new.
	
	theBuffer add: PICC_WRITE.
	theBuffer add: anAdress.
	theRedundancyCheck := self calculateCRC: theBuffer.
	theBuffer add: (theRedundancyCheck at: 1).
	theBuffer add: (theRedundancyCheck at: 2).
	
	theCommandResult := self commandToCard: PCD_TRANSCEIVE data: theBuffer.
	
	theBackData := (theCommandResult at: 'backData').
	theStatus := (theCommandResult at: 'status').
	theBackLen := (theCommandResult at: 'backLen').
	
	((theStatus = MI_OK) or: [(theBackLen = 4) or: [(((theBackData at: 1) bitAnd: 16r0F) = 16r0A)]])
	ifFalse: [
		theStatus = MI_ERR.].
	
	theStatus = MI_OK
	ifTrue: [
		theBuffer := OrderedCollection new.
		
		aData do: [ :eachData |
			theBuffer add: eachData].
		
		theRedundancyCheck := self calculateCRC: theBuffer.
		theBuffer add: (theRedundancyCheck at: 1).
		theBuffer add: (theRedundancyCheck at: 2).
		
		theCommandResult := self commandToCard: PCD_TRANSCEIVE data: theBuffer.
	
		theBackData := (theCommandResult at: 'backData').
		theStatus := (theCommandResult at: 'status').
		theBackLen := (theCommandResult at: 'backLen').
		
		((theStatus = MI_OK) or: [(theBackLen = 4) or: [(((theBackData at: 1) bitAnd: 16r0F) = 16r0A)]])
		ifTrue: [^true]
		ifFalse: [^false]].
	^false.
]

{ #category : 'Not categorized' }
HfuRc522 >> writeToModule: anAdress value: anValue [
	"Sends data to the Reader"
	| temporaries |
	bus readBytesUsingBuffer: (ByteArray with: ((anAdress bitShift: 1) bitAnd: 16r7E) with: anValue)
	
]
