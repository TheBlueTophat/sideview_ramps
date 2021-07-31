// TheBlueTophat
// Credits to EmilyV for helping do like 3/4ths the code

#option SHORT_CIRCUIT on
#option BINARY_32BIT off

typedef const long DEFINEL;
typedef const int CONFIG;
typedef const int DEFINE;

CONFIG CT_TRI = CT_SCRIPT1;

CONFIG MISC_RAMP = 0; // Hero->Misc constant
CONFIG MISC_DEFAULT_SPEED = 1; // Hero->Misc that keeps track of the player's default speed


CONFIG BITFLAG_TRI_BL = 1b; // Attributes 2 -> Flag 1, if checked then the ramp is on the bottom-left, otherwise it is on the bottom right
CONFIG BITFLAG_TRI_FALLTHROUGH = 10b; // Attributes 2 -> Flag 2, whether or not the player can fall through the ramp. Uses same logic as platforms.

DEFINEL FLAG_ON_RAMP = 01Lb;
DEFINEL FLAG_IGNORE_RAMP = 10Lb;
DEFINEL FLAG_JUMP_ABOVE_0 = 100Lb;
DEFINEL FLAG_ON_BACK_RAMP = 1000Lb;

@Author("TheBlueTophat, EmilyV99")
global script Example_Ramps_Global
{
	void run()
	{	
		Game->Cheat = 4;
		while(true)
		{
			Waitdraw();
			
			// DEBUG
			if(Link->InputR)
			{
				Link->X = Round(Link->X);
				Link->Y = Round(Link->Y);
			}
			
			printf("on, ignore, jump>0, special case\n");
			printf("Before: %d, %d, %d, %d\n", ((Hero->Misc[MISC_RAMP] & FLAG_ON_RAMP) ? 1 : 0), ((Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP) ? 1 : 0), ((Hero->Misc[MISC_RAMP] & FLAG_JUMP_ABOVE_0) ? 1 : 0), ((Hero->Misc[MISC_RAMP] & FLAG_ON_BACK_RAMP) ? 1 : 0));
			handleRamps();
			printf("After : %d, %d, %d, %d\n\n", ((Hero->Misc[MISC_RAMP] & FLAG_ON_RAMP) ? 1 : 0), ((Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP) ? 1 : 0), ((Hero->Misc[MISC_RAMP] & FLAG_JUMP_ABOVE_0) ? 1 : 0), ((Hero->Misc[MISC_RAMP] & FLAG_ON_BACK_RAMP) ? 1 : 0));
			
			Waitframe();
		}
	}
}

bool checkRamps()
{
	if(Hero->Jump > 0) return false;

	int x1, x2, y1, y2, m, b, hx, hy, dy;

	int posbr = ComboAt(Hero->X+15, Hero->Y+15), posbl = ComboAt(Hero->X, Hero->Y+15);
	combodata br = Game->LoadComboData(Screen->ComboD[posbr]),
			  bl = Game->LoadComboData(Screen->ComboD[posbl]);

	int posbr2 = ComboAt(Hero->X+3, Hero->Y+18), posbl2 = ComboAt(Hero->X+12, Hero->Y+18);
	combodata br2 = Game->LoadComboData(Screen->ComboD[posbr2]),
			  bl2 = Game->LoadComboData(Screen->ComboD[posbl2]);
			  
	int posbr3 = ComboAt(Hero->X+17, Hero->Y+16), posbl3 = ComboAt(Hero->X -2, Hero->Y+16);
	combodata br3 = Game->LoadComboData(Screen->ComboD[posbr3]),
			  bl3 = Game->LoadComboData(Screen->ComboD[posbl3]);
	
	combodata onCombo;
	
	if(br->Type == CT_TRI && !(br->UserFlags & BITFLAG_TRI_BL))
	{
		onCombo = br;
		x1 = ComboX(posbr);
		x2 = x1+15;
		y1 = ComboY(posbr)+15;
		y2 = y1-15;
		hx = Hero->X + 15 - x1;
	}
	else if(bl->Type == CT_TRI && (bl->UserFlags & BITFLAG_TRI_BL))
	{
		onCombo = bl;
		x1 = ComboX(posbl) + 15;
		x2 = x1-15;
		y1 = ComboY(posbl) + 15;
		y2 = y1-15;
		hx = Hero->X - x1;
	}
	else if(br2->Type == CT_TRI && !(br2->UserFlags & BITFLAG_TRI_BL))
	{
		if(br3->Type == CT_TRI && !(br3->UserFlags & BITFLAG_TRI_BL))
		{
			onCombo = br3;
			x1 = ComboX(posbr3);
			x2 = x1+15;
			y1 = ComboY(posbr3)+15;
			y2 = y1-15;
			hx = Hero->X + 15 - x1;
		}
		else
		{
			if((Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP) && !(Hero->Misc[MISC_RAMP] & FLAG_ON_BACK_RAMP)) 
				return false;
			
			int diff;
			
			unless(Hero->Jump && Hero->Y <= ComboY(posbr2))
			{
				diff = GridY(Hero->Y + 8) - Hero->Y;
			}
			
			unless(checkFallthrough(br2, diff)) 
				return false;
			
			Hero->Y += diff;
			
			return true;
		}
		
	}
	else if(bl2->Type == CT_TRI && (bl2->UserFlags & BITFLAG_TRI_BL))
	{
		if(bl3->Type == CT_TRI && (bl3->UserFlags & BITFLAG_TRI_BL))
		{
			onCombo = bl3;
			x1 = ComboX(posbl3) + 15;
			x2 = x1-15;
			y1 = ComboY(posbl3) + 15;
			y2 = y1-15;
			//b = 16;
			hx = Hero->X - x1;
		}
		else
		{
			if((Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP) && !(Hero->Misc[MISC_RAMP] & FLAG_ON_BACK_RAMP)) return false;
			
			int diff;
			
			unless(Hero->Jump && Hero->Y <= ComboY(posbl2))
			{
				diff = GridY(Hero->Y + 8) - Hero->Y;
			}
			
			unless(checkFallthrough(bl2, diff)) return false;
			
			Hero->Y += diff;
		
			return true;
		}
	}
	else 
	{
		unless(br->Type == CT_TRI || bl->Type == CT_TRI)
		{
			Hero->Misc[MISC_RAMP] ~= FLAG_IGNORE_RAMP | FLAG_ON_BACK_RAMP;
		}
		
		return false;
	}
	
	hy = Floor(Hero->Y + 15 - (y1));
	
	m = (x2-x1)/(y2-y1);
	dy = m*hx + b;
	
	int diff = ((dy - hy));
	
	printf("diff: %d\n", diff);
	
	// DEBUG: Don't mess with this block
	if(Hero->Misc[MISC_RAMP] & FLAG_JUMP_ABOVE_0)
	{
		if(diff < 0) // < 0
		{
			Hero->Misc[MISC_RAMP] |= FLAG_IGNORE_RAMP;
		}
	}
	
	// DEBUG: Don't mess with this block
	if(Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP )
	{
		if(diff >= 0) // >= 0
		{
			Hero->Misc[MISC_RAMP] ~= FLAG_IGNORE_RAMP;
		}
		else return false;
	}
	
	unless(checkFallthrough(onCombo, diff)) 
		return false;
	
	unless(Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP)
	{
		unless(Hero->Jump && diff >= 0 )
		{
			Hero->Y = Floor(Hero->Y + diff);
			return true;
		}		
	}
	
	return false;
}

void checkBehindRamps()
{
	//return; // debug
	int posbr = ComboAt(Hero->X + 3, Hero->Y+15), posbl = ComboAt(Hero->X + 15 - 3, Hero->Y+15);
	combodata br = Game->LoadComboData(Screen->ComboD[posbr]),
			  bl = Game->LoadComboData(Screen->ComboD[posbl]);
			  
	int posbr2 = ComboAt(Hero->X + 3, Hero->Y+16), posbl2 = ComboAt(Hero->X + 15 - 3, Hero->Y+16); // DEBUG: all this stuff
	combodata br2 = Game->LoadComboData(Screen->ComboD[posbr2]),
			  bl2 = Game->LoadComboData(Screen->ComboD[posbl2]);
			  
	int posbr3 = ComboAt(Hero->X + 3, Hero->Y+16), posbl3 = ComboAt(Hero->X + 15 - 3, Hero->Y+16); // DEBUG: all this stuff
	combodata br3 = Game->LoadComboData(Screen->ComboD[posbr3]),
			  bl3 = Game->LoadComboData(Screen->ComboD[posbl3]);
	
	if(br->Type == CT_TRI && !(br->UserFlags & BITFLAG_TRI_BL))// && br3->Type != CT_TRI)
	{
		// If player is on a ramp "behind" another ramp, activate FLAG_ON_BACK_RAMP
		if(br2->Type == CT_TRI)
		{
			// unless(Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP)
			{
				Hero->Misc[MISC_RAMP] |= FLAG_ON_BACK_RAMP;
			}
		}
		else
		{
			// Hero->Misc[MISC_RAMP] ~= FLAG_ON_BACK_RAMP;
			Hero->Misc[MISC_RAMP] |= FLAG_IGNORE_RAMP;
		}
	
		// Hero->Misc[MISC_RAMP] ~= FLAG_ON_RAMP; // DEBUG
	}
	else if(bl->Type == CT_TRI && (bl->UserFlags & BITFLAG_TRI_BL))// && bl3->Type != CT_TRI )
	{
		if(bl2->Type == CT_TRI)
		{
			// unless(Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP)
			{
				Hero->Misc[MISC_RAMP] |= FLAG_ON_BACK_RAMP;
			}
		}
		else
		{
			// Hero->Misc[MISC_RAMP] ~= FLAG_ON_BACK_RAMP;
			Hero->Misc[MISC_RAMP] |= FLAG_IGNORE_RAMP;
		}
	
		// Hero->Misc[MISC_RAMP] ~= FLAG_ON_RAMP; // DEBUG
	}
	else
	{
		Hero->Misc[MISC_RAMP] ~= FLAG_ON_BACK_RAMP;
	}
	
	// if(br2->Type != CT_TRI || bl2->Type != CT_TRI)
	// {
		// Hero->Misc[MISC_RAMP] ~= FLAG_IGNORE_RAMP;
	// }
}

void handleRamps()
{
	if(Hero->Climbing)
	{
		// Resets all the flags keeping track of the ramps if the player is climbing (don't use ladders with ramps!)
		Hero->Misc[MISC_RAMP] = FLAG_IGNORE_RAMP;
		return;
	}
	
	if(Hero->Jump > 0)
	{
		Hero->Misc[MISC_RAMP] |= FLAG_JUMP_ABOVE_0;
	}

	checkBehindRamps();
	
	bool checkRamp = checkRamps();
	
	if(checkRamp)
	{
		Hero->Misc[MISC_RAMP] |= FLAG_ON_RAMP;
	
		Hero->Gravity = false;
	}
	else if(Hero->Misc[MISC_RAMP] & FLAG_ON_RAMP)
	{
		unless(Hero->Jump > 0 || (Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP))
		{
			Hero->Y = GridY(Hero->Y + 8);
		}
		
		Hero->Misc[MISC_RAMP] ~= FLAG_ON_RAMP;
		Hero->JumpCount = 0;
		// Hero->Misc[MISC_RAMP] ~= FLAG_ON_BACK_RAMP;
	}
	
	printf("Mid   : %d, %d, %d, %d\n\n", ((Hero->Misc[MISC_RAMP] & FLAG_ON_RAMP) ? 1 : 0), ((Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP) ? 1 : 0), ((Hero->Misc[MISC_RAMP] & FLAG_JUMP_ABOVE_0) ? 1 : 0), ((Hero->Misc[MISC_RAMP] & FLAG_ON_BACK_RAMP) ? 1 : 0));
	
	if(Hero->Jump > 0)
	{
		Hero->Misc[MISC_RAMP] ~= FLAG_ON_RAMP | FLAG_ON_BACK_RAMP;
		
		// Hero->Misc[MISC_RAMP] ~= FLAG_ON_BACK_RAMP;
	}
	
	unless(Hero->Misc[MISC_RAMP] & FLAG_ON_RAMP || (Hero->Misc[MISC_RAMP] & FLAG_ON_BACK_RAMP))
	{
		Hero->Gravity = true;
	}
	else
	{
		Hero->JumpCount = -1;
	}
	
	unless(Hero->Jump > 0)
	{
		Hero->Misc[MISC_RAMP] ~= FLAG_JUMP_ABOVE_0;
	}
}

bool pressedItemType(int ic)
{
	if(Input->Press[CB_B] && Hero->ItemB > -1 && Game->LoadItemData(Hero->ItemB)->Type == ic) 
		return true;
	if(Input->Press[CB_A] && Hero->ItemA > -1 && Game->LoadItemData(Hero->ItemA)->Type == ic) 
		return true;
	if(Input->Press[CB_EX1] && Hero->ItemX > -1 && Game->LoadItemData(Hero->ItemX)->Type == ic) 
		return true;
	if(Input->Press[CB_EX2] && Hero->ItemY > -1 && Game->LoadItemData(Hero->ItemY)->Type == ic) 
		return true;
	
	return false;
}

bool checkFallthrough(combodata onCombo, int diff)
{
	if((onCombo->UserFlags & BITFLAG_TRI_FALLTHROUGH) && !(Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP) && !(Hero->Jump && diff >= 0 ))
	{
		if(Game->FFRules[qr_DOWN_FALL_THROUGH_SIDEVIEW_PLATFORMS])
		{
			if(Input->Button[CB_DOWN])
			{
				Hero->Y = Floor(Hero->Y + diff) + 1;
				Hero->Misc[MISC_RAMP] |= FLAG_IGNORE_RAMP;
				Hero->Misc[MISC_RAMP] ~= FLAG_ON_BACK_RAMP;
				
				//Hero->Misc[MISC_RAMP] ~= FLAG_ON_RAMP;
				// Hero->Misc[MISC_RAMP] ~= FLAG_JUMP_ABOVE_0;
				return false;
			}
		}
		else if(Game->FFRules[qr_DOWNJUMP_FALL_THROUGH_SIDEVIEW_PLATFORMS])
		{
			if(Input->Button[CB_DOWN] && pressedItemType(IC_ROCS))
			{
				Hero->Y = Floor(Hero->Y + diff) + 1;
				Hero->Misc[MISC_RAMP] |= FLAG_IGNORE_RAMP;
				Hero->Misc[MISC_RAMP] ~= FLAG_ON_BACK_RAMP;
				//Hero->Misc[MISC_RAMP] ~= FLAG_ON_RAMP;
				// Hero->Misc[MISC_RAMP] ~= FLAG_JUMP_ABOVE_0;
				int arr[] = {CB_A, CB_B, CB_EX1, CB_EX2};
				for(int i = 0; i < 4; ++i)
				{
					Input->Button[arr[i]] = false;
					Input->Press[arr[i]] = false;
				}
				
				return false;
			}
		}
	}
	
	return true;
}