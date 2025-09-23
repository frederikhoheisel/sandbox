# AR-VR Sandbox
Two player asynchronous AR-VR game on the AR-Sandbox. With one player manipulating the sandbox and another exploring the environment in VR.

## Installation
- connect Kinect to pc via usb
- connect projector and configure it as second screen to the right of the main monitor with resolution 1920*1080
- connect VR headset to pc
- start the program

### Potential Error sources
The Kinect sdk include and lib paths are hardcoded to

	'C:/Program Files/Azure Kinect SDK v1.4.1/sdk/include'
	'C:/Program Files/Azure Kinect SDK v1.4.1/sdk/windows-desktop/amd64/release/lib'

in the SConstruct file. If the sdk path is different, change the paths in this file and rebuild the extension using scons.

## Usage
- with the program running, press 'space' to toggle terrain updates and start the game
- if there is no VR HMD connected to the pc, you can control the camera with the mouse and 'wasd'

## Calibration
- with the program running, press 'c' to start the calibration
- 4 squares appear with one having a different color
- position the squares in the corners of the physical sandbox
	- use the arrow keys move a square
	- use 'tab' to select the next square
- if the calibration is still not good afterwards, try to adjust the kinect above the sandbox or adjust something in code :)