#cs

   Copyright 2009-2017 Florian Pollak (bfourdev@gmail.com)

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

#cs
Example 1:

	<recip>
		abc
	</recip>
	<msg>
		<recip>
			def
		</recip>
		<msg>
			no message
		</msg>
	</msg>

Example 2:

<recip> %all%
</recip>
<msg> %grid%\FP-Intracom\FP-Intracom.exe
	<recip> FP-SyncStatus
	</recip>
	<msg>
		<profile> '&$CmdLineRaw&'
		</profile>
		<requestType> getStatus
		</requestType>
		<requestData> %grid%\FP-Intercom\FP-IntercomClient.exe
			<recip> '&@ComputerName&'
			</recip>
			<msg> '&_gridDir()&'\FP-Intracom\FP-Intracom.exe
				<recip> FP-SyncPre'&@AutoItPID&'
				</recip>
				<msg> %status%
				</msg>
			</msg>
			<msg> '&_gridDir()&'\FP-Intracom\FP-Intracom.exe
				<recip> FP-SyncPre'&@AutoItPID&'
				</recip>
				<msg> %status%
				</msg>
			</msg>
		</requestData>
	</msg>
</msg>


Multiple descriptors can be distinguished by their relative position: a first level descriptor has its end-marker after all the other lower level descriptors.
--> Retrieving first-level-data: Go through whole command line until the number of opens (<>) equals the number of closes (</>) (including the initial descriptor.

Command line interpreter:
reads CmdLineRaw -> returns 2D-array of first level: [x][0:descriptor 1:data]

$descriptorRequest: 	requested descriptors as string or array --> output-array will contain requested descriptors in the order given
						string-format: descriptor;descriptor;...
						array-format: [0:descriptor 1:descriptor...]
#ce

#include-once
#include <Array.au3>

;test
;~ $cache=_commandLineInterpreter("<1>1</1> <2>2</2> <3>3</3>","5;1")
;~ _ArrayDisplay($cache)

Func _commandLineInterpreter($commandLine,$descriptorRequest="")
	Local $outputBounds=1
	Local $outputIndex=0
	Local $output[$outputBounds][2]
	Local $cmdlineSplit
	Local $descriptor=""
	Local $descriptorBeginIndex=""
	Local $descriptorEndIndex=""
	Local $data

	$cmdlineSplit=StringSplit($commandLine,"<")

	For $i=1 To UBound($cmdlineSplit)-1
		;start ([descriptor]>[data]) or end (/[descriptor>[data])
		If StringLeft($cmdlineSplit[$i],1)="/" Then
			;end of first level descriptor reached if enddescriptor=descriptor --> entries inbetween are data --> reconstruct
			;reset ($)descriptor
			If StringMid($cmdlineSplit[$i],2,StringInStr($cmdlineSplit[$i],">")-2)=$descriptor Then
				;store descriptor
				$output[$outputIndex][0]=$descriptor

				;store data
					;first line ([<descriptor>]data)
					$data&=StringRight($cmdlineSplit[$descriptorBeginIndex],StringLen($cmdlineSplit[$descriptorBeginIndex])-StringInStr($cmdlineSplit[$descriptorBeginIndex],">"))
					;other lines
						;get index of end-marker for this descriptor
						Local $amountOfStartMarkers=1 ;1 for initial marker which end-marker we are looking for
						Local $amountOfEndmarkers=0

						For $j=$descriptorBeginIndex+1 To UBound($cmdlineSplit)-1
							;end-marker
							If StringLeft($cmdlineSplit[$j],1)="/" And StringMid($cmdlineSplit[$j],2,StringInStr($cmdlineSplit[$j],">")-2)=$descriptor Then
								$amountOfEndmarkers+=1
							;start-marker
							ElseIf StringLeft($cmdlineSplit[$j],1)<>"/" And StringMid($cmdlineSplit[$j],1,StringInStr($cmdlineSplit[$j],">")-1)=$descriptor Then
								$amountOfStartMarkers+=1
							EndIf

							If $amountOfStartMarkers=$amountOfEndmarkers Then
								$descriptorEndIndex=$j
								ExitLoop
							EndIf
						Next

						;get data in between and restore missing <'s
						For $j=$descriptorBeginIndex+1 To $descriptorEndIndex-1
							$data&="<"&$cmdlineSplit[$j]
						Next

					;store to array
				$output[$outputIndex][1]=$data

				;adjust output-array
				$outputBounds+=1
				$outputIndex+=1
				ReDim $output[$outputBounds][2]

				;reset
				$descriptor=""
				$descriptorBeginIndex=""
				$descriptorEndIndex=""
				$data=""
			EndIf
		ElseIf $cmdlineSplit[$i]<>"" Then
			;get first-level descriptor (arrayEntries: [descriptor]> ) (first descriptor in array (=first one in cmdline-string)
			;has to be a first level descriptor --> everything between this one and end of this descriptor is lower-level -->
			;descriptor following end of first-level descriptor has to be first-level too
			If $descriptor="" Then
				$descriptor=StringLeft($cmdlineSplit[$i],StringInStr($cmdlineSplit[$i],">")-1)
				$descriptorBeginIndex=$i
			EndIf
		EndIf
	Next

	_ArrayDelete($output,UBound($output)-1)

	;handle explicit request for specific descriptors
		;format request
	Local $formattedDescriptorRequest=""

	If IsString($descriptorRequest) And $descriptorRequest<>"" Then
		$formattedDescriptorRequest=StringSplit($descriptorRequest,";",3)
	ElseIf IsArray($descriptorRequest) Then
		$formattedDescriptorRequest=$descriptorRequest
	EndIf

	If IsArray($formattedDescriptorRequest)==1 Then
			;prepare output-array
		Local $cache[UBound($formattedDescriptorRequest)][2]
		For $i=0 To UBound($cache)-1
			$cache[$i][0]=$formattedDescriptorRequest[$i]
		Next

			;fill output-array
		For $i=0 To UBound($output)-1
			For $j=0 To UBound($cache)-1
				If $output[$i][0]=$cache[$j][0] Then
					$cache[$j][1]=$output[$i][1]
				EndIf
			Next
		Next
		$output=$cache
	EndIf

	Return $output
EndFunc