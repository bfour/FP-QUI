=============
General notes
=============

    FP-QUI allows you to show notifications (popups) in the tray area.
	It can be controlled via command line or named pipes.
    Copyright (C) 2010 Florian Pollak

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  
	If not, see http://www.gnu.org/licenses/gpl.html.

==========
How to use
==========

	1)  start FP-QUICore.exe
	2a) create a message via command line, using FP-QUI.exe
		example: FP-QUI.exe "<text>Hello world.</text>"
	2b) create a message via named pipe
		In your program, create a named pipe called "\\.\pipe\FP-QUICore".
		Now simply use the command line, for instance "<text>Hello world.</text>",
		to create a notification.
	2c) Use the GUI that shows up when FP-QUI.exe is executed while 		
		FP-QUICore is running.

====================
Command line options
====================

	 0 <text>
	 1 <delay>
	 2 <textColor>
	 3 <width>
	 4 <height>
	 5 <bkColor>
		0x****** hex color-code
		blue
		green
		red
		orange
		white
		black
		gray
		purple
		yellow
	 6 <ico>
	 7 <onClick> 
		<any> ... on any click
		<left> ... on left mouse button
		<right> ... on right mouse button
		<includeButton> ... process clicks on button, too
	 8 <untilProcessExists>
	 9 <untilProcessClose>
	 10 <noDouble> ... if <>"", a notification will only be genereated if its signature (cmd-params) is unique. If it is not, the handle of the existing notification with the same signature will be returned (there can't be many, since they would all need at least noDouble<>"" to be equal,).
	 11 <untilClick>
			<any> ... on any click
			<left> ... on left mouse button
			<right> ... on right mouse button
			<includeButton> ... process clicks on button, too
	 12 <beep>
			<string> ... freq;duration|freq;duration|...
			<repeat> ... number of repetitions
			<pause> ... pause between repeats
			<shake> ... shake notification on beep
	 13 <x>
	 14 <y>
	 15 <talk> ... use %text% to read out <text>
	 16 <font>
	 17 <fontSize>
	 18 <trans> transparency
	 19 <focus> grabs focus if <>"" 
	 20 <audio> plays back an audio-file
			<path> ... path to sound file
			<repeat> ... number of repetitions
			<pause> ... pause between repeats
			<maxVol> ... maximize volume before playback
			<overwriteMute> ... overwrites mute
			<shake> ... shake notification on playback
	 21 <replaceVar> if <>"" variables in all options will be replaced by _stringReplaceVariables
	 22 <avi> use "default" to show busy indicator, path to show specific avi, empty to show no avi
	 23 <run>
			<cmd>
			<repeat>
			<pause>
	 24 <progress> ... <>"" --> show bar
	 25 <button>
			one button: <button><1><label>test</label><cmd>notepad</cmd></1></button>
			three buttons: 	<button>
								<a><label>test</label><cmd>notepad</cmd></a>
								<d><label>test2</label><cmd>notepad</cmd></d>
								<third><label>test3</label><cmd>notepad</cmd></third>
							</button>
	 26 <winHandle>
	 27 <reply>
			<pipe> set to <>"" and provide a valid pipe name if you want a pipe reply
			<stdout> set to <>"" if you want an stdout reply
	 28 <dispatcherArea> ... overwrite config; [screen1|screen2|screen3 …|x,y,width,height]
	 29 <startPos> ... overwrite config; [upperleft|upperright|lowerleft|lowerright|x,y] … relative to dispatcherArea
	 30 <direction> ... overwrite config; [down,right|down,left|up,right|up,left] … relative to startPos
	 31 <delete> ... deletes winHandle, all other arguments are ignored (.exe <delete>0x000000</delete>)
	 32 <update> ... if you want to explicitly declare an update (else any request with <winHandle> <> "" will force an update of all attributes of this notification according to the parameters you provided) you may enclose your request in <update> (<update>[request]</update>)
		
		example: <update><winHandle>0x000000</winHandle><text>hello :-)</text></update> will change the text of 0x000000, but will leave all other attributes unchanged
 