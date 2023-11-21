# mementomori
A tool for making Anki cards out of any picture. It allows you to drag in a picture and draw rectangles over the picture. It will then generate 
card variations where each rectangle is highlighted and then revealed on the backside of the card.

It uses raylib in the background for rendering and input.

## Supported platforms at the moment:
- MacOS
- Linux
- Windows support coming soon!

### Currently only Finnish text, English translation coming soon!

## Installing:
Use the nightly Zig compiler to build the program and then run it. I will provide binaries at a later date.
Then you need to provide it a conf file in the same directory where you provide the absolute path to Anki's collection media folder and 
on the second line you need to provide a absolute path to the directory where the anki csv files will be generated into.

Then you can just generate the cards and import the CSV from Anki's import section.
