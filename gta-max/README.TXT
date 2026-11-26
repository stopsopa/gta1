GRAND THEFT AUTO: MAX PACK gathers GTA1, London 69 & 61, both soundtracks.

It is meant for recent Windows systems like Windows 8.1 and Windows 10.
City maps are in the DOCS folder.


1. INSTRUCTIONS +STEAM
2. TROUBLESHOOTING & PERFORMANCE
3. CHANGELOG
4. CREDITS
5. LEGAL


1. INSTRUCTIONS +STEAM
^^^^^^^^^^^^^^^^^^^^^^
INSTALL: Just extract the content of the archive to a new folder.

STEAM: Extract the content of the archive into the WINO folder to launch
    the pack from Steam (it will replace the main executable).
    (Program Files (x86)\Steam\steamapps\common\Grand Theft Auto\WINO)
    The Steam overlay should work fine with this pack's default settings.

GLIDE: Run nGlide_config.exe to set Glide settings. Recommended settings:
    Screen resolution:  By desktop
    Aspect ratio:       Preserve original
    Refresh rate:       By app (Default)
    Vertical sync':     On (Default)
    Gamma correction:   0.8
    3Dfx logo splash:   Off

TOP MENU BAR: If the top menu bar appears ingame, hit ALT+ENTER two times.

WINDOWED: It is possible to run the pack in windowed mode by editing
    the file dosbox.conf with a text editor and change the line:
        fullscreen=true  to  fullscreen=false
    The game will then run in a window at the game's original resolution.
    This can also be changed by editing the following line:
        windowresolution=original  to  windowresolution=1024x768  for example.

MAC OSX: This pack is also available for Mac OSX, search it on Google!

LINUX: The pack works with Dosbox SVN builds for Linux. As you're on Linux,
    I expect you to know your way around. i.e. just get it to load dosbox.conf.
    Wine can run the pack as well by the way.

WIN XP: You don't really need this pack as the Rockstar Classics release works
    on Windows XP. You can download Dosbox and drop (only) the main executable
    in the pack's main folder to get it working though.
    You can also search for ThirteenAG's GTA1+Widescreen Pack.


2. TROUBLESHOOTING & PERFORMANCE
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TOP MENU BAR: As said up there, if the top menu bar partially appears ingame,
    just hit ALT+ENTER twice (2x), to exit and re-enter fullscreen mode.

GAME IS SLOW: a. Test the Glide mode, it might perform better than normal mode.
              b. Ingame, press F11 and lower the resolution to 640x480x32.
              c. Run the game in a WINDOW as explained in point 1. up there.

DISABLE MUSIC: Sound and/or music can be disabled from the game menu.

LONDON 69 CUTSCENES: For some reason, the cutscenes don't play properly within
    London '69 in normal mode. Try to bypass them or use either the Glide mode
    or 8bit mode (from the setup) to play them correctly.
    That bug also generates hundreds of screenshots within the game files. The
    launcher deletes them upon starting and quitting the game in that mode.

CRASHES ON INGAME RESOLUTION CHANGE: Delete PLAYER_A/E.DAT files from folders
    \GTADATA and \GTADATA\UK. It can also be done from the Options panel in the
    launcher. This also resets the scores.

LOW COLOR/RES GTA: The 8bit version of each game can be launched from their
    respective setup which can be found in [4] Options > [4] Run Setup.
    London 61 lowres mode is unofficial and incomplete (based on L'69 exec).

DOSBOX SAVE STATES: Save states sadly make the Glide mode crash. If you want to
    use save state, you have to play in normal mode.

GLIDE WRAPPER ISSUES: dgVoodoo2 is an alternative to the included nGlide that
    you can download and try in the latter's place. Just make sure to replace
    the original glide2x.dll with dgVoodoo2's and put nglide_config.exe aside.


3. CHANGELOG
^^^^^^^^^^^^
V1.3: Minor tweaks. More bugs and infos referenced in the Readme.
V1.2: Split Mac version apart. Fixed UK setups and 8bit modes.
      Fixed a Glide mishap.
V1.1: Improved launcher. Added Glide mode. Experimental Mac OSX support.
      Base ingame resolution set to 800x600x32. New README.TXT.
v1.0: First release. Spiritual successor to the "LONDON 69 & 61 for XP" pack.


4. CREDITS
^^^^^^^^^^
This pack is using Dosbox DAUM and nGlide 1.05.
Pack by Toshiba-3, 2016.


5. LEGAL
^^^^^^^^
Sadly, this pack and its distribution are probably illegal one way or another.
If you decide to share this pack online, expect that your publication might be
moderated/truncated/deleted if moderators don't feel like tolerating links with
questionable legality.

The initiative of this pack comes from the fact the Steam release of GTA1 
doesn't work well or at all for many people, but also that Rockstar made GTA1 
and London 61 freely available online for a while (L'61 still is). 
It is expected that people interested in this pack already own GTA1 at least 
once (be it a physical copy or here on Steam) and I personally think that this
is a reasonable expectation.

That is obviously just my personal standpoint on the matter and I totally 
understand that views on this might differ greatly. However I've applied this
state of mind while retro-modding/gaming for years now and must say it makes
for a more serene approach to enjoy and modify old games.