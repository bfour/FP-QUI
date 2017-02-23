#cs

   Copyright 2010-2017 Florian Pollak (bfourdev@gmail.com)

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

#ce

Func _doCheckLifetime($i)

	If ( _
		($notificationsOptions[$i][1]<>"" And TimerDiff($notificationsOptionsData[$i][1])>=$notificationsOptions[$i][1]) Or _ ;delay
		($notificationsOptions[$i][8]<>"" And ProcessExists($notificationsOptions[$i][8])<>0) Or _ ;untilProcessExists
		($notificationsOptions[$i][9]<>"" And ProcessExists($notificationsOptions[$i][9])==0) _ ;untilProcessClose
	   ) _
	Then
		_hideNotification($i)
	EndIf

EndFunc