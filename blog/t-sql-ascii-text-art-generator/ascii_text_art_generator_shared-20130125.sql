--****************T-SQL ASCII Text-Art Creator****************
--************************************************************
--********************Only edit this stuff********************
--************************************************************
DECLARE @Face nvarchar(10) = '4max' --Name of the font (options are 4max and Banner3)
DECLARE @S nvarchar(200) = '\o/ Steve Holt!' --What you want it to say
--************************************************************
--**********************Revision History**********************
--************************************************************
--20110511 - Added ()[]{}<>/\|-_=+@#$%^&*":;
--20101116 - Narrowed the code to prep for sharing
--20101115 - Added 0-9.!?',(space) and another font
--20101112 - Created original with Banner3 font
--	     Fonts from http://patorjk.com/software/taag/
--	     (admittedly, used without permission)
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
			= 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?'', ()[]{}<>/\|-_=+@#$%^&*":;' --Every font below needs to be in the same order
			

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
		SET @AlphaLen   = '8677667626668676766678866574657677663364443355666655288688977897734' --How wide is each character (excluding the 1 space between characters)
		SET @AlphaStart = '1867766762666867676667886657465767766336444335566665528868897789773' --Where does the character start in the string(s)? Add together all prior values to get the starting position.
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
		SET @P1 = @P1 + SUBSTRING(@L1,@K,@M) --+ '||' --Helpful debug delimeter to show what
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