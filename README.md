# FOR UPDATED VERSION, SEE THIS REPO: https://github.com/Jacky-He/EasyEmoteMacOS

# EasyEmote
A very small-scale application that allows users to type emojis almost everywhere in a similar fashion as Discord and Slack. 

Deployment Target: MacOS 10.15+

Application Zip File: https://github.com/Jacky-He/EasyEmote/releases/download/v0.0/EasyEmoteMacOS.2020-11-24.23-52-19.zip

When using the application, make sure you are using the Unicode Hex Input Keyboard.

Make sure EasyEmote is checked under System Preferences -> Privacy -> Accessibility.

The emojis are currently not subject to customization. Only those representable by Unicode are available. 

Further, the availability is subject to the environment in which the application runs

Emoji data are retrieved from: https://unicode.org/emoji/charts/full-emoji-list.html

**Demo**
![Demo](https://user-images.githubusercontent.com/39445499/100185698-76f8b800-2eb2-11eb-8004-2b67fae9b25e.gif)

# Known Issues:
Popup appears where the mouse is, not where the cursor is in selected textfield

Popup appears even when no textfield is selected

Emojis and popup behavior might not be correct if the character sequence is created with insertions in the middle or front of the sequence.
