Class {
	#name : 'TestOneWireDS18B20ThermometerDevice',
	#superclass : 'Object',
	#category : 'RaspberryHardwareInterfaceTestApp'
}

{ #category : 'Not categorized' }
TestOneWireDS18B20ThermometerDevice class >> dumpTemperatureFetchingOn: aWriteStream [

	aWriteStream
		nextPutAll: Time now printString;
		nextPutAll: ': '.
	OneWireDevice initializeOnLoad.
	OneWireDS18B20ThermometerDevice listDevices do: [:anIdString |
		aWriteStream
			nextPutAll: anIdString;
			nextPutAll: ', '.
		(OneWireDS18B20ThermometerDevice idString: anIdString)
			ifNotNil: [:aDevice | | aTemperature |
				aTemperature := aDevice temperature.
				aWriteStream
					nextPutAll: aTemperature printString;
					nextPutAll: ', '.
				aWriteStream nextPutAll: (
					aTemperature = 999
						ifFalse: ['my temperature %1 = %2' bindWith: anIdString with: aTemperature]
						ifTrue: ['Error reading the temperature (%1)' bindWith: anIdString])]
			ifNil: [aWriteStream nextPutAll: 'Error getting an OneWireDevice']].
	aWriteStream nextPutAll: 'Done!'
]

{ #category : 'Not categorized' }
TestOneWireDS18B20ThermometerDevice class >> dumpTemperatureFetchingOnTranscript [

	self dumpTemperatureFetchingOn: Transcript
]

{ #category : 'Not categorized' }
TestOneWireDS18B20ThermometerDevice class >> fetchTemperature [
	"Answers the temperature as Celsius and as a Float"

	| devices |

	devices := OneWireDS18B20ThermometerDevice listDevices.
	devices isEmpty ifTrue: [self error: 'There is no device detected'].
	devices size > 1 ifTrue: [self error: 'There is more than one device detected'].
	^(OneWireDS18B20ThermometerDevice idString: devices first)
		ifNotNil: [:aDevice | aDevice temperature]
]
