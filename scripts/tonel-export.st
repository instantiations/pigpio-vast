| writer path |
path := (CfsPath named: '<insert path to root pigpio-vast local repo here>').
writer := TonelWriter new.
writer
	addLatestConfigurationMapNamed: 'RaspberryHardwareInterfaceCore';
	addLatestConfigurationMapNamed: 'RaspberryHardwareInterfaceTest';
	addApplicationsFromConfigurationMaps.
writer writeProjectInto: path.
