--****************T-SQL ASCII Text-Art Creator****************
--************************************************************
--********************Only edit this stuff********************
--************************************************************
DECLARE @Face nvarchar(10) = '4max' --Name of the font (must be available below)
DECLARE @S nvarchar(200) = 'Updates*********' --What you want it to say
--************************************************************
--**********************Revision History**********************
--************************************************************
--20110511 - Added ()[]{}<>/\|-_=+@#$%^&*":; and started to add
--		the Colossal typeface
--20101116 - Narrowed the code to prep for sharing
--20101115 - Added 0-9.!?',(space) and another font
--20101112 - Created original with Banner3 font
--	     Fonts from http://patorjk.com/software/taag/
--	     (admittedly, used without permission)
--	     Created by LongboredSurfer.com
--	     Licensed under Creative Commons Attribution Share Alike
--	     http://creativecommons.org/licenses/by-sa/3.0/
--************************************************************


DECLARE @L1 nvarchar(1000), --The variables used to store
		@L2 nvarchar(1000), --the font to be used
		@L3 nvarchar(1000),
		@L4 nvarchar(1000),
		@L5 nvarchar(1000),
		@L6 nvarchar(1000),
		@L7 nvarchar(1000),
		@L8 nvarchar(1000)
DECLARE @AlphaLen nvarchar(200) = '', --Length of the next character to display
		@AlphaStart nvarchar(200)='', --Starting position of @AlphaLen
		@Final nvarchar(max), --All stored in one variable at the end
		@CharOrder nvarchar(75) --Order of letters in the L1-L7 variables
			= 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?'', ()[]{}<>/\|-_=+@#$%^&*":;'
			

DECLARE @P1 nvarchar(4000) = '', --The final individual lines
		@P2 nvarchar(4000) = '', --which combine to make each
		@P3 nvarchar(4000) = '', --letter when stacked on top
		@P4 nvarchar(4000) = '', --of each other.
		@P5 nvarchar(4000) = '',
		@P6 nvarchar(4000) = '',
		@P7 nvarchar(4000) = '',
		@P8 nvarchar(4000) = ''
DECLARE @SU nvarchar(200) = UPPER(@S) --Convert the string to uppercase
DECLARE @StringLength int = LEN(@S) --How many times to loop through (1 character at a time)
DECLARE @J int = 0 --Counter for the subloop to figure out start position
DECLARE @K int = 0 --Start position for each letter in its @L1-7 string
DECLARE @L int = 0 --0-25 position of the letter for each loop
DECLARE @M int = 0 --Length of the character it's about to grab


IF @Face = '4max'
	BEGIN
		----4max           ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?', ()[]{}<>/\|-_=+@#$%^&*":;
		SET @AlphaLen   = '8677667626668676766678866574657677663364443355666655288688977897734'
		SET @AlphaStart = '1867766762666867676667886657465767766336444335566665528868897789773'
		SET @L1 = '   db    88""Yb  dP""b8 8888b.  888888 888888  dP""b8 88  88 88  88888 88  dP 88     8b    d8 88b 88  dP"Yb  88""Yb  dP"Yb  88""Yb .dP"Y8 888888 88   88 Yb    dP Y      P Yb  dP Yb  dP 8888P  dP"Yb    .d oP"Yb. 88888   dP88  888888   dP"   888888P .dP"o. dP""Yb     d8b oP"Yb.  .o.            dP Yb  88888 88888   d888 888b     .dP" `Yb.      dP Yb    II                             oo     dP""Yb  __88_88__ .dPIIY8 .o. dP    .db.    d888        o    o8o o8o .o.  .o. '
		SET @L2 = '  dPYb   88__dP dP   `"  8I  Yb 88__   88__   dP   `" 88  88 88     88 88odP  88     88b  d88 88Yb88 dP   Yb 88__dP dP   Yb 88__dP `Ybo."   88   88   88  Yb  dP  Yb db dP  YbdP   YbdP    dP  dP   Yb .d88 "" dP"   .dP  dP 88  88oo.  .d8"        dP  `8b.d" Ybood8     Y8P "" dP" ,dP"           dP   Yb 88       88 .dP       Yb. .dP"     `Yb.   dP   Yb   II ________          oooooo ___88___ dP PY Yb ""88"88"" `YbII " `""dP   .dP"`Yb. dP_______ `8.8.8" `"" `"" `""  `"" '
		SET @L3 = ' dP__Yb  88""Yb Yb       8I  dY 88""   88""   Yb  "88 888888 88 o.  88 88"Yb  88  .o 88YbdP88 88 Y88 Yb   dP 88"""  Yb b dP 88"Yb  o.`Y8b   88   Y8   8P   YbdP    YbPYdP   dPYb    8P    dP   Yb   dP   88   dP   o `Yb d888888    `8b 8P"""Yb    dP   d"`Y8b   .8P" .o. `"    8P         .o.      Yb   dP 88       88 `Yb       dP" `Yb.     .dP"  dP     Yb  II """"""""          ______ """88""" Yb boodP __88_88__ o.`II8b   dP.o.          Yb"""88"" .8.8.8.         .o.  .o. '
		SET @L4 = 'dP""""Yb 88oodP  YboodP 8888Y"  888888 88      YboodP 88  88 88 "bodP  88  Yb 88ood8 88 YY 88 88  Y8  YbodP  88      `"YoYo 88  Yb 8bodP    88   `YbodP     YP      Y  P   dP  Yb  dP    d8888  YbodP    88 .d8888 YbodP     88  8888P  `YboodP   dP    `bodP   .dP   `"  (8)  (8)        ,dP"       Yb dP  88888 88888   Y888 888P     `Yb. .dP"   dP       Yb II          oooooooo """"""    ""     Ybooo   ""88"88"" 8boIIP"  dP `""          `Ybo 88      "            `"" ,dP" '
		----       1234567891023456789202345678930234567894023456789502345678960234567897023456789802345678990234567891023456789110345678912034567891303456789140345678915034567891603456789170345678918034567891903456789200345678921034567892203456789230345678924034567892503456789260345678927034567892803456789292903456789300345678931034567893203456789330345678934034567893503456789360345678937034567893803456789390345678940034567894103456789420345678943034567894403456789450345678946034567894703456789




	END
IF @Face = 'Banner3'
	BEGIN
		----Banner3        ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?', ()[]{}<>/\|-_=+@#$%^&*":;
		SET @AlphaLen   = '9989889948889899998899998896999898993494445566665588277569988799944'
		SET @AlphaStart = '1998988994888989999889999889699989899349444556666558827756998879994'
		SET @L1 = '   ###    ########   ######  ########  ######## ########  ######   ##     ## ####       ## ##    ## ##       ##     ## ##    ##  #######  ########   #######  ########   ######  ######## ##     ## ##     ## ##     ## ##     ## ##    ## ########   #####     ##    #######   #######  ##        ########  #######  ########  #######   #######      ####  #######  ####             ### ###   ###### ######   #### ####      ## ##          ## ##       ##                               #######    ## ##    ######  ###   ##   ###     ####              #### ####  ##  #### '
		SET @L2 = '  ## ##   ##     ## ##    ## ##     ## ##       ##       ##    ##  ##     ##  ##        ## ##   ##  ##       ###   ### ###   ## ##     ## ##     ## ##     ## ##     ## ##    ##    ##    ##     ## ##     ## ##  #  ##  ##   ##   ##  ##       ##   ##   ##  ####   ##     ## ##     ## ##    ##  ##       ##     ## ##    ## ##     ## ##     ##     #### ##     ## ####            ##     ##  ##         ##  ##       ##    ##   ##        ##   ##      ##                         ##   ##     ##   ## ##   ## ## ## # #  ##   ## ##   ##  ##    ##   ##  #### #### #### #### '
		SET @L3 = ' ##   ##  ##     ## ##       ##     ## ##       ##       ##        ##     ##  ##        ## ##  ##   ##       #### #### ####  ## ##     ## ##     ## ##     ## ##     ## ##          ##    ##     ## ##     ## ##  #  ##   ## ##     ####       ##   ##     ##   ##          ##        ## ##    ##  ##       ##            ##   ##     ## ##     ##     ####       ##   ##            ##       ## ##         ##  ##       ##   ##     ##      ##     ##     ##                 #####   ##   ## ### ## ######### ## ##    ### ##   ##   ##   ####      ## ##    ##   ##   ##       '
		SET @L4 = '##     ## ########  ##       ##     ## ######   ######   ##   #### #########  ##        ## #####    ##       ## ### ## ## ## ## ##     ## ########  ##     ## ########   ######     ##    ##     ## ##     ## ##  #  ##    ###       ##       ##    ##     ##   ##    #######   #######  ##    ##  #######  ########     ##     #######   ########      ##      ###   ##   ####      ##       ## ##         ## ###       ### ##       ##    ##       ##       #######               ###### ## ### ##   ## ##    ######     ##             ####     #########                #### '
		SET @L5 = '######### ##     ## ##       ##     ## ##       ##       ##    ##  ##     ##  ##  ##    ## ##  ##   ##       ##     ## ##  #### ##     ## ##        ##  ## ## ##   ##         ##    ##    ##     ##  ##   ##  ##  #  ##   ## ##      ##      ##     ##     ##   ##   ##               ## #########       ## ##     ##   ##     ##     ##        ##             ##          ####      ##       ## ##         ##  ##       ##   ##     ##    ##         ##   ##                 #####   ##   ## #####  #########    ## ##   ## ###         ##  ## ##   ## ##              ##  #### '
		SET @L6 = '##     ## ##     ## ##    ## ##     ## ##       ##       ##    ##  ##     ##  ##  ##    ## ##   ##  ##       ##     ## ##   ### ##     ## ##        ##    ##  ##    ##  ##    ##    ##    ##     ##   ## ##   ##  #  ##  ##   ##     ##     ##       ##   ##    ##   ##        ##     ##       ##  ##    ## ##     ##   ##     ##     ## ##     ## ### ####                 ##        ##     ##  ##         ##  ##       ##    ##   ##    ##           ##  ##                         ##   ##          ## ##   ## ## ##  ##  # #         ##   ##    ##   ##            ####  ##  '
		SET @L7 = '##     ## ########   ######  ########  ######## ##        ######   ##     ## ####  ######  ##    ## ######## ##     ## ##    ##  #######  ##         ##### ## ##     ##  ######     ##     #######     ###     ### ###  ##     ##    ##    ########   #####   ###### #########  #######        ##   ######   #######    ##      #######   #######  ### ####    ##          ##          ### ###   ###### ######   #### ####      ## ##    ##             ## ##         #######               #######    ## ##    ######  ##   ###          ####  ##                      ##  ##   '
		----       1234567891023456789202345678930234567894023456789502345678960234567897023456789802345678990234567891023456789110345678912034567891303456789140345678915034567891603456789170345678918034567891903456789200345678921034567892203456789230345678924034567892503456789260345678927034567892803456789292903456789300345678931034567893203456789330345678934034567893503456789360345678937034567893803456789390345678940034567894103456789420345678943034567894403456789450345678946034567894703456789480345678949034567895003456789510345678952034567895303456789540345678955034567895603456789
	END


IF @Face = 'Colossal'
	BEGIN
		----Colossal       ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?', ()[]{}<>/\|-_=+@#$%^&*":;
		SET @AlphaLen   = '9989889948889899998899998896999898993494445566665588277569988799944'
		SET @AlphaStart = '1998988994888989999889999889699989899349444556666558827756998879994'
		SET @L1 = '       d8888 888888b.    .d8888b.  8888888b.  8888888888 8888888888 .d8888b.  888    888 8888888 888888 888    d8P  888      888b     d888 888b    888  .d88888b.  8888888b.   .d88888b.  8888888b.   .d8888b. 88888888888 888     888 888     888 888       888 Y88b   d88P Y88b   d88P 8888888888P  .d8888b.   d888    .d8888b.   .d8888b.      d8888  888888888   .d8888b. 8888888888  .d8888b.   .d8888b.      888  .d8888b.  d8b          .d88 88b.   8888888 8888888   .d888 888b.      d88P Y88b          d88P Y88b         888                              .d8888888b.    888  888        88     d88b   d88P  o    .d8888b.                 88 88        '
		SET @L2 = '      d88888 888  "88b  d88P  Y88b 888  "Y88b 888        888       d88P  Y88b 888    888   888     "88b 888   d8P   888      8888b   d8888 8888b   888 d88P" "Y88b 888   Y88b d88P" "Y88b 888   Y88b d88P  Y88b    888     888     888 888     888 888   o   888  Y88b d88P   Y88b d88P        d88P  d88P  Y88b d8888   d88P  Y88b d88P  Y88b    d8P888  888        d88P  Y88b      d88P d88P  Y88b d88P  Y88b     888 d88P  Y88b 88P         d88P" "Y88b  888         888  d88P"   "Y88b    d88P   Y88b        d88P   Y88b        888                             d88P"   "Y88b   888  888    .d88888b.  Y88P  d88P  d8b  d88P  "88b          o     8P 8P        '
		SET @L3 = '     d88P888 888  .88P  888    888 888    888 888        888       888    888 888    888   888      888 888  d8P    888      88888b.d88888 88888b  888 888     888 888    888 888     888 888    888 Y88b.         888     888     888 888     888 888  d8b  888   Y88o88P     Y88o88P        d88P   888    888   888          888      .d88P   d8P 888  888        888            d88P  Y88b. d88P 888    888     888      .d88P 8P         d88P     Y88b 888         888  888       888   d88P     Y88b      d88P     Y88b       888                             888  d8b  888 888888888888 d88P 88"88b      d88P  d888b Y88b. d88P         d8b    "  "         '
		SET @L4 = '    d88P 888 8888888K.  888        888    888 8888888    8888888   888        8888888888   888      888 888d88K     888      888Y88888P888 888Y88b 888 888     888 888   d88P 888     888 888   d88P  "Y888b.      888     888     888 Y88b   d88P 888 d888b 888    Y888P       Y888P        d88P    888    888   888        .d88P     8888"   d8P  888  8888888b.  888d888b.     d88P    "Y88888"  Y88b. d888     888    .d88P"  "          888       888 888         888 .888       888. d88P       Y88b    d88P       Y88b      888               888888  888   888  888  888   888  888   Y88b.88         d88P  d8P"Y8b "Y8888P"         d888b        d8b d8b '
		SET @L5 = '   d88P  888 888  "Y88b 888        888    888 888        888       888  88888 888    888   888      88P 8888888b    888      888 Y888P 888 888 Y88b888 888     888 8888888P"  888     888 8888888P"      "Y88b.    888     888     888  Y88b d88P  888d88888b888    d888b        888        d88P     888    888   888    .od888P"       "Y8b. d88   888       "Y88b 888P "Y88b 88888888  .d8P""Y8b.  "Y888P888     888    888"               888       888 888         888 888(       )888 Y88b       d88P   d88P         Y88b                             8888888 888  888bd88P   888  888    "Y88888b.     d88P          .d88P88K.d88P "Y888888888P"    Y8P Y8P '
		SET @L6 = '  d88P   888 888    888 888    888 888    888 888        888       888    888 888    888   888      888 888  Y88b   888      888  Y8P  888 888  Y88888 888     888 888        888 Y8b 888 888 T88b         "888    888     888     888   Y88o88P   88888P Y88888   d88888b       888       d88P      888    888   888   d88P"      888    888 8888888888        888 888    888  d88P     888    888        888     Y8P    888                Y88b     d88P 888         888 "888       888"  Y88b     d88P   d88P           Y88b    888  888888       888888  888   888  Y8888P"  888888888888      88"88b   d88P           888"  Y888P"    "Y88888P"              '
		SET @L7 = ' d8888888888 888   d88P Y88b  d88P 888  .d88P 888        888       Y88b  d88P 888    888   888    .d88P 888   Y88b  888      888   "   888 888   Y8888 Y88b. .d88P 888        Y88b.Y8b88P 888  T88b  Y88b  d88P    888     Y88b. .d88P    Y888P    8888P   Y8888  d88P Y88b      888      d88P       Y88b  d88P   888   888"       Y88b  d88P       888  Y88b  d88P Y88b  d88P d88P      Y88b  d88P Y88b  d88P d8b  "               d8b       Y88b. .d88P  888         888  888       888    Y88b   d88P   d88P             Y88b   888                             Y88b.     .d8   888  888   Y88b 88.88P  d88P  d88b      Y88b .d8888b    d88P"Y88b      d8b d8b '
		SET @L8 = 'd88P     888 8888888P"   "Y8888P"  8888888P"  8888888888 888        "Y8888P88 888    888 8888888 d88P"  888    Y88b 88888888 888       888 888    Y888  "Y88888P"  888         "Y888888"  888   T88b  "Y8888P"     888      "Y88888P"      Y8P     888P     Y888 d88P   Y88b     888     d8888888888  "Y8888P"  8888888 888888888   "Y8888P"        888   "Y8888P"   "Y8888P" d88P        "Y8888P"   "Y8888P"  Y8P 888    888       88P        "Y88 88P"   8888888 8888888  Y88b.   .d88P     Y88b d88P   d88P               Y88b  888       88888888               "Y88888888P"   888  888    "Y88888P"  d88P   Y88P       "Y8888P" Y88b dP"     "Yb     Y8P 88P '
		----       123456789102345678920234567893023456789402345678950234567896023456789702345678980234567899023456789102345678911034567891203456789130345678914034567891503456789160345678917034567891803456789190345678920034567892103456789220345678923034567892403456789250345678926034567892703456789280345678929290345678930034567893103456789320345678933034567893403456789350345678936034567893703456789380345678939034567894003456789410345678942034567894303456789440345678945034567894603456789470345678948034567894903456789500345678951034567895203456789530345678954034567895503456789560345678957034567895803456789590345678960034567896103456789620345678963034567896403456789
	END




DECLARE @Counter int = 0
WHILE @Counter < @StringLength
	BEGIN
		SET @Counter = @Counter+1
		SET @L --Determine the numeric value of the current letter (1-26)
			= CHARINDEX(SUBSTRING(@SU,@Counter,1),@CharOrder,0)
		SET @K = -1 --Set the start position over for the next letter
		SET @J = 0 --Reset the loop you're about to enter
		WHILE @J < @L
			BEGIN
				SET @J=@J+1	--The whole point of this loop, which is to figure
							--out the starting position of the character in the
							--giant strings that make up the ASCII letters
				SET @K=@K + CAST(SUBSTRING(@AlphaStart,@J,1) as int)+1
					--Add the width of all previous characters in the list
					--to figure out the starting position of the current
					--character (and add 1 extra for the spaces between letters)
				----Some debug stuff, which will show the character's position
				----being found. Good for helping to see if you have all the
				----character widths correct before the next one
				--PRINT 'Letter''s Starting Position (running): '+CAST(@K as nvarchar(10))+'.'
				--+' Current (Sub)Loop Count: '+CAST(@J as nvarchar(10))+'.'
			END
		SET @M = SUBSTRING(@AlphaLen,@L,1)+1 --Character's Length(including space)
		----More debug, to show the current status of things as it runs through the loop(s)
		--PRINT ' Letter = '+SUBSTRING(@SU,@Counter,1)+'/(#'+CAST(@L as nvarchar(10))+').'
		--	+' Character''s Length (@M): '+CAST(@M-1 as nvarchar(10))+'.'
		--	+' Starting Position (@K): '+CAST(@K as nvarchar(10))+'.'
		--	+' Counter: '+CAST(@Counter as nvarchar(10))+'.'
		--	+' Position of character:'+CAST(SUBSTRING(@SU,@Counter,1) as nvarchar(10))+'.'

		--Build
		SET @P1 = @P1 + SUBSTRING(@L1,@K,@M) --+ '||' --Helpful debug delimiter to show what
		SET @P2 = @P2 + SUBSTRING(@L2,@K,@M) --+ '||' --each cycle is pulling for each letter
		SET @P3 = @P3 + SUBSTRING(@L3,@K,@M) --+ '||' --or cycle through.
		SET @P4 = @P4 + SUBSTRING(@L4,@K,@M) --+ '||'
		SET @P5 = @P5 + SUBSTRING(@L5,@K,@M) --+ '||'
		SET @P6 = @P6 + SUBSTRING(@L6,@K,@M) --+ '||'
		SET @P7 = @P7 + SUBSTRING(@L7,@K,@M) --+ '||'
		SET @P8 = @P8 + SUBSTRING(@L8,@K,@M) --+ '||'
	END
----More debugging
--PRINT 'String Length: '+CAST(@StringLength as nvarchar(10))
SET @Final = (
	  ISNULL(@P1,'') + CHAR(10)
	+ ISNULL(@P2,'') + CHAR(10)
	+ ISNULL(@P3,'') + CHAR(10)
	+ ISNULL(@P4,'') + CHAR(10)
	+ ISNULL(@P5,'') + CHAR(10)
	+ ISNULL(@P6,'') + CHAR(10)
	+ ISNULL(@P7,'') + CHAR(10)
	+ ISNULL(@P8,'')
	)
PRINT @Final