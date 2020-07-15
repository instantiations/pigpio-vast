<p align="center">
 <h1 align="center">Pigpio wrapper for VAST Platform (VA Smalltalk)</h1>
  <p align="center">
    This is a Smalltalk wrapper of the C library pigpio to manage the GPIO pins of a Raspberry Pi
    <br>
    <a href="docs/"><strong>Explore the docs »</strong></a>
    <br>
    <br>
    <a href="https://github.com/vasmalltalk/pigpio-vast/issues/new?labels=Type%3A+Defect">Report a defect</a>
    |
    <a href="https://github.com/vasmalltalk/pigpio-vast/issues/new?labels=Type%3A+Feature">Request feature</a>
  </p>
</p>

This project is designed for anyone wanting to access GPIOs of a Raspberry Pi and starting with IoT. The library provides not just pulling up and down pins but also many of the most important protocols such as 1-Wire, I2C, SPI, etc.


## License
- The code is licensed under [MIT](LICENSE).
- The documentation is licensed under [CC BY-SA 4.0](http://creativecommons.org/licenses/by-sa/4.0/).


## Installation

1. Install [VA Smalltalk 9.2.1 or newer](https://www.instantiations.com/products/vasmalltalk/download.html).
2. Install Tonel support in your development image following [this guide](https://github.com/vasmalltalk/tonel-vast#installation).
3. Clone this repository.
4. The easiest and recommended approach is to install it via a script:

```smalltalk
| loader path |
path := (CfsPath named: '<insert path to root pigpio-vast local repo here>').
loader := TonelLoader readFromPath: path.
loader
	beUnattended; "do not prompt and use all defaults"
	useGitVersion.
loader loadAllMapsWithRequiredMaps.
```

Or you can load the Configuration Map `RaspberryHardwareInterfaceCore` from the context menu of the Configuration Maps Browser: `"Import"` -> `"Load Configuration Maps from Tonel repository..."` -> select path to root `pigpio-vast` local repo. This will open a dialog and will use convenient defaults for the load. Refer to [its documentation](https://github.com/instantiations/tonel-vast#using-gui-menus) for more details.

5. Optionally run the SUnit tests included in the map `RaspberryHardwareInterfaceTest` to ensure correct installation. One easy way is to right-click on the `RaspberryHardwareInterfaceTest` map name in the Name pane (as opposed to version pane ) and then select `Test Loaded Applications`.


## Quick Start

- Download the [latest ECAP from Instantiations](https://www.instantiations.com/ecap/)
- Read some [related blog posts](https://marianopeck.wordpress.com/tag/pigpio/)


## Acknowledgments

- vast-pigpio started as a clone of [RaspberryHardwareInterface](http://vastgoodies.com/projects/Raspberry%2520Pi%2520Hardware%2520Interface) which was was a port done by Louis LaBrunda from Squeak's implementation done by Tim Rowledge.
- [Norbert Schlemmer](https://github.com/Noschvie)
- [Gerardo Richarte](https://github.com/gerasdf)
- [Joan, pigpio author](https://github.com/joan2937)
- Github repository layout was generated with [Ba-St Github-setup project](https://github.com/ba-st/GitHub-setup).

## Contributing

Check the [Contribution Guidelines](CONTRIBUTING.md)
