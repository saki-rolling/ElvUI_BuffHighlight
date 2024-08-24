# ElvUI SHighlight Plugin
Forked from https://github.com/Vekkt/ElvUI_BuffHighlight

Allows you to highlight unit frames according to specified player buffs, for healer classes.

This version:
* Does not support fade coloring
* Adds gradient coloring for buffs (controlled by ElvUI > UnitFrames > General > Colors > Health By Value)

**Crappy Preview**

![image](https://user-images.githubusercontent.com/82050743/129960749-475f86b8-3bb8-4c21-891a-3a2599567b7d.png)

# Usage
<img width="609" alt="image" src="https://github.com/user-attachments/assets/4ebe019e-c1dc-4f3d-929b-8a68fbc926b0">

**Enable** - Enable/disables plugin

**Colored backdrop** - Enables/disables coloring of the backdrop of the unit frame.

![image](https://github.com/user-attachments/assets/a1dd8bbf-daa1-4332-a5e6-d5ad782d3817)

**Frames Options** - Party, Raid1, Raid2, Raid3: Categories match the categories under UnitFrames > Group Units. 
Limit On 5: Performance enhancement that will stop parsing raid frames when in a group <= 5. /reload required after changing a frame option.

**Spell Options** - Add the SpellID of the buff you want to track

**Glow Options** - 3 colors. This sets the gradient color of the highlight (Enabled by ElvUI > UnitFrames > General > Colors > Health By Value). If you do not have Health By Value checked, then only Color (High Health) is used.

**Class Association** - Associates a class to this buff. This is used for performance enhancement and can be left blank if unwanted.

# ElvUI Recommended  Settings
* Health By Value - Enabled
* Class Backdrop - Disabled
* Class Health - Disabled

It still works if you have different settings, but it'll look the best with the above settings
<img width="609" alt="image" src="https://github.com/user-attachments/assets/bd4cd8d1-dbc1-4a83-8160-033c16cc435b">
