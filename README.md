# MATLAB Based PicoScope 4824A Block Data Acquisition System

This is a simple MATLAB-based PicoScope 4824A Block Data Acquisition System, preliminarily achieving block data acquisition, display and storage.

![image](/_assets/img/snapshot.png)

<br>

# Requirements

- Hardware: [PicoScope 4824A Oscilloscope (PicoScope 4000A Series)](https://www.picotech.com/oscilloscope/4000/picoscope-4000-series) by [Pico Technology Ltd](https://www.picotech.com/).
- Oscilloscope Software Development Kit (SDK): [PicoScope oscilloscope software and PicoLog data logging software](https://www.picotech.com/downloads).
- MATLAB and Required Toolboxes
  - MATLAB: the GUI is created and test by MATLAB R2022a Version 9.12.
  - MATLAB Instrument Control Toolbox: [Instrument Control Toolbox](https://ww2.mathworks.cn/en/products/instrument.html).
  - MATLAB PicoScope Support Toolbox: [picotech/picosdk-matlab-picoscope-support-toolbox](https://github.com/picotech/picosdk-matlab-picoscope-support-toolbox).
  - MATLAB PicoScope 4000 Series A API MATLAB Generic Instrument Driver: [picotech/picosdk-ps4000a-matlab-instrument-driver](https://github.com/picotech/picosdk-ps4000a-matlab-instrument-driver).

Additionally, icons of GUI Buttons are available at: [Remix-Design/RemixIcon](https://github.com/Remix-Design/RemixIcon), and the MVC (Mode-View-Controller) programming principles for constructing GUI in MATLAB, which is adopted in this demo, could be found in *MATLAB 面向对象编程: 从入门到设计模式* by 徐潇.

<br>

# Usage

Run the file `\gui\run.m`.
