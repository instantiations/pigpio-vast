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
	#name : 'HfuSimpleRc522',
	#superclass : 'HfuRc522',
	#classVars : [
		'RfidKey',
		'BlockAdresses'
	],
	#category : 'RaspberryHardwareInterfaceViaDaemonSubApp'
}

{ #category : 'Not categorized' }
HfuSimpleRc522 class >> blockAdresses [

	^BlockAdresses
]

{ #category : 'Not categorized' }
HfuSimpleRc522 class >> blockAdresses: anObject [

	BlockAdresses := anObject
]

{ #category : 'Not categorized' }
HfuSimpleRc522 class >> rfidKey [

	^RfidKey
]

{ #category : 'Not categorized' }
HfuSimpleRc522 class >> rfidKey: anObject [

	RfidKey := anObject
]

{ #category : 'Not categorized' }
HfuSimpleRc522 >> readCardAsOrderedList [
	| theUid |
	"Returns the content of the RFID-Chip as a OrderedList. This function will wait until a card is hold on to the reader."
	theUid := self readCardSerialNumber.
	((theUid size) <= 4)
	ifTrue: [^nil].
	
	^(self readCardAsOrderedList: theUid).
	
	
]

{ #category : 'Not categorized' }
HfuSimpleRc522 >> readCardAsOrderedList: aSerialNumber [
	"Returns the content of the RFID-Chip as a OrderedList. This function will wait until a card is hold on to the reader."
	| theSelectResult theAuthStatus theData theResult |
	
	theResult := nil.
	
	theSelectResult := self selectTag: aSerialNumber.
	
	theAuthStatus := self authentication: PICC_AUTHENT1A blockAddress: 11 sectorKey: RfidKey serialNumber: aSerialNumber.
	
	theAuthStatus isZero
	ifTrue: [
		"Transcript show: 'Erfolg'."
		theResult := OrderedCollection new.
		BlockAdresses do: [:eachAdress |
			theData := self readFromCard: eachAdress.
			theData isNil
			ifFalse: [
				"Transcript show: ''; cr."
				
				theData do: [:eachByte |
					"Transcript show: ((eachByte asCharacter) asString)."
					theResult add: eachByte.
				].
			].
		].
	]. 
	self stopCrypto.
	^theResult.
]

{ #category : 'Not categorized' }
HfuSimpleRc522 >> readCardAsString [
	"Returns the content of the RFID-Chip as a string. This function will wait until a card is hold on to the reader."
	| theData theResult |
	
	theData := self readCardAsOrderedList.
	theData isNil
	ifTrue: [^nil].
	
	theResult := ''.
	
	theData do: [:eachByte | 
		theResult := (theResult, ((eachByte asCharacter) asString))].
	
	^theResult.
	
	
]

{ #category : 'Not categorized' }
HfuSimpleRc522 >> readCardAsUserID [
	"Returns the User ID which is read from the RFID-Chip. This function will wait until a card is hold on to the reader."
	
	^((self readCardAsString) asNumber).
	
	
]

{ #category : 'Not categorized' }
HfuSimpleRc522 >> readCardSerialNumber [
	"Returns the Serialnumber of the RFID-Chip as a OrderedList. This function will wait until a card is hold on to the reader."
	| theRequestResult theAntiCollResult |
	
	[true] whileTrue: [
		theRequestResult := self request: PICC_REQIDL.
	
		(theRequestResult at: 'status') = MI_OK
		ifTrue: [
			theAntiCollResult := self antiCollision.
			(theAntiCollResult at: 'status') = MI_OK
			ifTrue: [^(theAntiCollResult at: 'backData')].].
	].
	
]

{ #category : 'Not categorized' }
HfuSimpleRc522 >> spiBus: anSpiBus [
	
	super spiBus: anSpiBus.
	
	RfidKey := OrderedCollection  new.
	RfidKey add: 16rFF.
	RfidKey add: 16rFF.
	RfidKey add: 16rFF.
	RfidKey add: 16rFF.
	RfidKey add: 16rFF.
	RfidKey add: 16rFF.
	
	BlockAdresses := OrderedCollection new.
	BlockAdresses add: 8.
	BlockAdresses add: 9.
	BlockAdresses add: 10.
]

{ #category : 'Not categorized' }
HfuSimpleRc522 >> writeStringToCard: aString [
	| theUid |
	
	theUid := self readCardSerialNumber.
	((theUid size) <= 4)
	ifTrue: [^nil].
	
	^(self writeStringToCard: aString serialNumber: theUid)
	
	
	
	
	
	
]

{ #category : 'Not categorized' }
HfuSimpleRc522 >> writeStringToCard: aString serialNumber: aSerialNumber [
	| theSelectResult theAuthStatus theOutData theTempData theResult theIterator theSecondIterator |
	
	theResult := false.
	
	theSelectResult := self selectTag: aSerialNumber.
	
	theAuthStatus := self authentication: PICC_AUTHENT1A blockAddress: 11 sectorKey: RfidKey serialNumber: aSerialNumber.
	self readFromCard: 11. 
	theAuthStatus isZero
	ifTrue: [
		"Transcript show: 'Erfolg'."
		theResult := true.
		theOutData := OrderedCollection new. 
		aString do: [:eachChar | 
			theOutData add: (eachChar value)].
		
		"Fuelle mit 32 auf - 32 steht fuer Leerzeichen"
		[(theOutData size < (16 * (BlockAdresses size)))] whileTrue: [
			theOutData add: 32.].
		
		theIterator := 0.
		BlockAdresses do: [ :eachAdress | 
			theTempData := OrderedCollection new.
			
			theSecondIterator := 1.
			[(theTempData size < 16)] whileTrue: [
				theTempData add: (theOutData at: (theSecondIterator + (theIterator * 16))).
				theSecondIterator := theSecondIterator + 1].
			theIterator := theIterator + 1.
			
			theResult := (((self writeToCard: eachAdress data: theTempData) and: [theResult])).
		].
	].
	self stopCrypto.
	^theResult.

]
