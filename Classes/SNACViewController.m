//
//  SNACViewController.m
//  iCDS
//
//  Created by James Zucker on 11/14/09.
//  Copyright James A. Zucker 2009, 2010. All rights reserved.
//

#import "SNACViewController.h"
#import "CreditDateRoutines.h"
#import "QuotedSpreadViewController.h"
#include "iCDSAppDelegate.h"

@implementation SNACViewController

@synthesize currencyPickerView, currencyViewArray, currentPicker;

#pragma mark -
#pragma mark Compose Mail

	// Displays an email composition interface inside the application. Populates all the Mail fields. 
- (IBAction)email:(id)sender
{
	BOOL networkWasDown =  [(iCDSAppDelegate *)[[UIApplication sharedApplication] delegate] networkWasDown];	

	if( ! networkWasDown )
	{
			//if we can send mail
		Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
		if ( mailClass != nil && ([mailClass canSendMail] == YES) )
		{
			MFMailComposeViewController *emailController = [[MFMailComposeViewController alloc] init];
			emailController.mailComposeDelegate = self;
		
			[emailController setSubject:@"CDS UpFront Fee"];
					
				// Set up recipients
			//NSArray *toRecipients = [NSArray arrayWithObject:@"first@example.com"]; 
			//	NSArray *ccRecipients = [NSArray arrayWithObjects:@"second@example.com", @"third@example.com", nil]; 
			//NSArray *bccRecipients = [NSArray arrayWithObject:@"fourth@example.com"]; 
			
			//[emailController setToRecipients:toRecipients];
			//	[emailController setCcRecipients:ccRecipients];	
			//[emailController setBccRecipients:bccRecipients];
			
				// Attach an image to the email
			NSString *path = [[NSBundle mainBundle] pathForResource:@"icds 57x57 Icon" ofType:@"jpg"];
			NSData *myData = [NSData dataWithContentsOfFile:path];
			[emailController addAttachmentData:myData mimeType:@"image/jpg" fileName:@"icds 57x57 Icon"];

			
			NSString *buySell = @"Buy Protection";
			if ( [BuySellCtrl selectedSegmentIndex] == 1 ) {
				buySell = @"Sell Protection";
			}
			
			NSArray *components = [[outStartDate titleForState:UIControlStateNormal] componentsSeparatedByString:@" / "];
			NSString *daysAcrrued = [components objectAtIndex:1];
			

				// Fill out the email body text
			NSString *emailBody = [NSString stringWithFormat: @"<BR><FONT FACE=\"Courier\" SIZE=\"-1\"> \
	<BR><B>iCDS IPhone Upfront Fee Calculator Results </B>     \
	<BR><BR><B><U>Inputs</U></B>\
	<BR>&nbsp; Trade Type:%@					\ 
	<BR>&nbsp; Trade Date:%@					\
	<BR>&nbsp; Maturity:%@						\
	<BR>&nbsp; Recovery:%@						\
	<BR>&nbsp; Standard Coupon:%@				\
	<BR>&nbsp; Notional:%@						\
	<BR>&nbsp; Currency:%@						\
	<BR><BR>&nbsp; Quoted(bps/fee):%@			\
	<BR><BR><B><U>Output</U></B>				\
	<BR>&nbsp; <B><U>UpFront Fee:%@</B></U>     \
	<BR>&nbsp; Quoted Spread:%@					\
	<BR>&nbsp; Quoted Fee:%@					\
	<BR>&nbsp; Clean Price:%@                   \
	<BR>&nbsp; Accrual Amount:%@                \
	<BR>&nbsp; Accrual Days:%@                  \
	<BR>&nbsp; Settlement Date:%@				\
	<BR>										\
	<BR><I>Note: Cash Settlement Date is not adjusted for holidays. Payment should follow on the next business day.</I> \
	<BR></FONT>"
								   , [NSString stringWithFormat:@"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;%@",buySell]				   
								   , [NSString stringWithFormat:@"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;%@", [outTradeDate titleForState:UIControlStateNormal]]				   
								   , [NSString stringWithFormat:@"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;%@", [MaturityText titleForState:UIControlStateNormal]]					   
								   , [NSString stringWithFormat:@"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;%@", [RecoveryText titleForState:UIControlStateNormal]]					   
								   , [NSString stringWithFormat:@"&nbsp;%@ bps", [StandardCouponCtrl titleForSegmentAtIndex: [StandardCouponCtrl selectedSegmentIndex]]]				   
								   , [NSString stringWithFormat:@"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;%@", [NotionalText titleForState:UIControlStateNormal]]					   
								   , [NSString stringWithFormat:@"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;%@", [CurrencyCtrl titleForState:UIControlStateNormal]]					   
								   , [NSString stringWithFormat:@"&nbsp;%@", [PriceText titleForState:UIControlStateNormal]]

								   , [NSString stringWithFormat:@"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;%@", [outUpFrontFee titleForState:UIControlStateNormal]]							   
								   , [NSString stringWithFormat:@"&nbsp;&nbsp;&nbsp;%@ bps", [outSpread titleForState:UIControlStateNormal]]
								   , [NSString stringWithFormat:@"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;%@ %", [outFeeQuote titleForState:UIControlStateNormal]]
								   , [NSString stringWithFormat:@"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;%@", [outPrice titleForState:UIControlStateNormal]]
								   , [NSString stringWithFormat:@"&nbsp;&nbsp;%@", [outAccrued titleForState:UIControlStateNormal]]
								   , [NSString stringWithFormat:@"&nbsp;&nbsp;&nbsp;&nbsp;%@", daysAcrrued]
								   , [NSString stringWithFormat:@"&nbsp;%@", [outSettleDate titleForState:UIControlStateNormal]]
	];
		
			
			
			[emailController setMessageBody:emailBody isHTML:YES];
			
			[self presentModalViewController:emailController animated:YES];
			[emailController release];

		}
		else 
		{
			//display an alert and ignore the users selection
			UIAlertView *errorAlert = [[UIAlertView alloc]
									   initWithTitle:@"Error"
									   message: [NSString stringWithFormat:@"Email not supported on this device."]
									   delegate:self
									   cancelButtonTitle:@"Continue"
									   otherButtonTitles:nil];
			[errorAlert show];
			[errorAlert release];
		}//canSendEmail
	}
	else 
	{
		//display an alert and ignore the users selection
		UIAlertView *errorAlert = [[UIAlertView alloc]
								   initWithTitle:@"Error"
								   message: [NSString stringWithFormat:@"Email cannot be sent while WIFI is not available."]
								   delegate:self
								   cancelButtonTitle:@"Continue"
								   otherButtonTitles:nil];
		[errorAlert show];
		[errorAlert release];
	}

}

	// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	
	
	/*
	message.hidden = NO;
		// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled:
			message.text = @"Result: canceled";
			break;
		case MFMailComposeResultSaved:
			message.text = @"Result: saved";
			break;
		case MFMailComposeResultSent:
			message.text = @"Result: sent";
			break;
		case MFMailComposeResultFailed:
			message.text = @"Result: failed";
			break;
		default:
			message.text = @"Result: not sent";
			break;
	}
	 */
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark UIPickerView

- (void)setPriceTextButton:(NSString *)theTitle
{
	//update the buttone
	[self setButtonText:PriceText title: theTitle recalc:YES];
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{	
		//handle the currency picker
	if (currentPicker == currencyPickerView)	
	{
			// report the selection to the UI Button
		NSString *currency = [currencyViewArray objectAtIndex:[(UIPickerView*)currentPicker selectedRowInComponent:0]];
		
			//get the current selection
		NSString *currentTitle = [CurrencyCtrl titleForState:UIControlStateNormal];
		if ( ![currency isEqualToString:currentTitle] ) 
		{
			//Get the new libor curve
			if ([self setLiborCurve:currency valueDate:[self getTradeDate]] == YES) 
			{
				[self setButtonText:CurrencyCtrl title: currency recalc:YES];

				/*
					//update the buttone
				[CurrencyCtrl setTitle:currency forState: UIControlStateNormal];
				[CurrencyCtrl setTitle:currency forState: UIControlStateSelected];
				[CurrencyCtrl setTitle:currency forState: UIControlStateHighlighted];
							
					//re-calc the #s
				[self ReCalculate];
				 */
			}
			else 
			{
				//display an alert and ignore the users selection
				UIAlertView *errorAlert = [[UIAlertView alloc]
										   initWithTitle:@"Error"
										   message: [NSString stringWithFormat:@"Could not set Currency to: %@", currency]
										   delegate:self
										   cancelButtonTitle:@"Continue"
										   otherButtonTitles:nil];
				[errorAlert show];
				[errorAlert release];
			}
		}
	}		
	else if (currentPicker == maturityPickerView)
	{
		NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
		
			//month are Quartery so calc the month by the position
		components.month = ([(UIPickerView*)currentPicker selectedRowInComponent:0] + 1) *3;
		
			//get the year from the picker
		components.year = [[maturityYearViewArray objectAtIndex:[(UIPickerView*)currentPicker selectedRowInComponent:1]] intValue];
		
			//SNAC says the date is always 20th
		components.day = 20;
		
		//calc the maturity date selected
		NSDate *maturityDate = [gregorian dateFromComponents:components];
		NSString *maturity =  [dateCalc convertDateToString:maturityDate];	
		
			//ensure the maturity date is in the future 
		NSDate *today = [NSDate date];
		if ([today compare:maturityDate] == NSOrderedAscending )
		{			
			//get the current selection
			NSString *currentTitle = [MaturityText titleForState:UIControlStateNormal];
			if ( ![maturity isEqualToString:currentTitle] ) 
			{
				
				[self setButtonText:MaturityText title: maturity recalc:YES];
/*
				//update the buttone
				[MaturityText setTitle:maturity forState: UIControlStateNormal];
				[MaturityText setTitle:maturity forState: UIControlStateSelected];
				[MaturityText setTitle:maturity forState: UIControlStateHighlighted];
				
				//re-calc the #s
				[self ReCalculate];
*/				
				//clear the quick entry
				@try 
				{
					[MaturityCtrl setSelectedSegmentIndex:UISegmentedControlNoSegment];
				}
				@catch (NSException *exception)
				{
					// deliberately ignore exception we dont want it in the log
				}
			}
		}
		else 
		{
			//maturity date is invalid, in cannot be in the past
			//display an alert and ignore the users selection
			UIAlertView *errorAlert = [[UIAlertView alloc]
									   initWithTitle:@"Error"
									   message: [NSString stringWithFormat:@"Maturity date cannot be in the past: %@", maturity]
									   delegate:self
									   cancelButtonTitle:@"Continue"
									   otherButtonTitles:nil];
			[errorAlert show];
			[errorAlert release];
		}

	}
	else if (currentPicker == notionalPickerView)
	{
		double decimal = [(UIPickerView*)currentPicker selectedRowInComponent:6] / 10.0
			+ [(UIPickerView*)currentPicker selectedRowInComponent:7] / 100.0;
		
		double notionalAmount =
			[(UIPickerView*)currentPicker selectedRowInComponent:0] * 1e5
			+ [(UIPickerView*)currentPicker selectedRowInComponent:1] * 1e4
			+ [(UIPickerView*)currentPicker selectedRowInComponent:2] * 1e3
			+ [(UIPickerView*)currentPicker selectedRowInComponent:3] * 1e2
			+ [(UIPickerView*)currentPicker selectedRowInComponent:4] * 1e1
			+ [(UIPickerView*)currentPicker selectedRowInComponent:5] 
		+ decimal;
		
		double currentNotional = [[NotionalText titleForState:UIControlStateNormal] doubleValue];
		if (notionalAmount != currentNotional) 
		{
			NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
			[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
			[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
			[numberFormatter setPositiveFormat:@"#,###,##0.##"];
			[numberFormatter setNegativeFormat:@"(#,###,##0.##)"];

			NSNumber *pnTempNumber = [NSNumber numberWithDouble:notionalAmount];
			NSString *notional;
			if ([pnTempNumber doubleValue] < 10000.0) {
				notional = [[numberFormatter stringFromNumber:pnTempNumber] stringByAppendingFormat:@"M"];
			}
			else {
				notional = [numberFormatter stringFromNumber:pnTempNumber];
			}
		
			[self setButtonText:NotionalText title: notional recalc:YES];
/*
			//update the buttone
			[NotionalText setTitle:notional forState: UIControlStateNormal];
			[NotionalText setTitle:notional forState: UIControlStateSelected];
			[NotionalText setTitle:notional forState: UIControlStateHighlighted];

			//re-calc the #s
			[self ReCalculate];
*/
			
			//clear the quick entry
			@try 
			{
				[NotionalCtrl setSelectedSegmentIndex:UISegmentedControlNoSegment];
			}
			@catch (NSException *exception)
			{
				// deliberately ignore exception we dont want it in the log
			}
			
		}
	}
	else if (currentPicker == recoveryPickerView)
	{
		
		int recoveryAmount =
			[(UIPickerView*)currentPicker selectedRowInComponent:0] * 1e2
			+ [(UIPickerView*)currentPicker selectedRowInComponent:1] * 1e1
		+ [(UIPickerView*)currentPicker selectedRowInComponent:2];
		
		double currentRecovery = [[RecoveryText titleForState:UIControlStateNormal] doubleValue];
		if (recoveryAmount != currentRecovery) 
		{
			if (recoveryAmount <= 100) 
			{
				NSString *recovery = [NSString stringWithFormat:@"%d%@",recoveryAmount,@"%"];
				
				
				[self setButtonText:RecoveryText title: recovery recalc:YES];
/*
				//update the buttone
				[RecoveryText setTitle:recovery forState: UIControlStateNormal];
				[RecoveryText setTitle:recovery forState: UIControlStateSelected];
				[RecoveryText setTitle:recovery forState: UIControlStateHighlighted];
				
				//re-calc the #s
				[self ReCalculate];
*/
				//clear the quick Entry
				@try 
				{
					[RecoveryCtrl setSelectedSegmentIndex:UISegmentedControlNoSegment];
				}
				@catch (NSException *exception)
				{
					// deliberately ignore exception we dont want it in the log
				}
				
			}
			else 
			{
				//recover is invalid, in cannot be >100%
				//display an alert and ignore the users selection
				UIAlertView *errorAlert = [[UIAlertView alloc]
										   initWithTitle:@"Error"
										   message: [NSString stringWithFormat:@"Recovery cannot be >100%: %d%@", recoveryAmount,@"%"]
										   delegate:self
										   cancelButtonTitle:@"Continue"
										   otherButtonTitles:nil];
				[errorAlert show];
				[errorAlert release];				
			}

		}
	}
/*
	else if (currentPicker == pricePickerView)
	{
		
		int  priceAmount =
		[(UIPickerView*)currentPicker selectedRowInComponent:0] * 1e3
		+ [(UIPickerView*)currentPicker selectedRowInComponent:1] * 1e2
		+ [(UIPickerView*)currentPicker selectedRowInComponent:2] * 1e1
		+ [(UIPickerView*)currentPicker selectedRowInComponent:3];
		
		double currentSpread = [[RecoveryText titleForState:UIControlStateNormal] doubleValue];
		if (priceAmount != currentSpread) 
		{
			
			NSString *spread = [NSString stringWithFormat:@"%d",priceAmount];
			
			//update the buttone
			[PriceText setTitle:spread forState: UIControlStateNormal];
			[PriceText setTitle:spread forState: UIControlStateSelected];
			[PriceText setTitle:spread forState: UIControlStateHighlighted];
			
			//re-calc the #s
			[self ReCalculate];
			
		}
	}
 */
	else if (currentPicker == tradeDatePickerView)
	{
		
		NSDate *currentDate = [self getTradeDate];
		NSDate *newDate		= [dateCalc moveToValidBusinessDate: [tradeDatePickerView date] rollForward:TRUE];

		if ( ![currentDate isEqualToDate:newDate] ) 
		{
			//Get the new libor curve
			if ([self setLiborCurve:[self getCurrency] valueDate:newDate] == YES) 
			{
				//update the button
				[self setTradeDate:newDate];
				
				//re-calc the #s
				[self ReCalculate];
			}
			else 
			{
				//display an alert and ignore the users selection
				UIAlertView *errorAlert = [[UIAlertView alloc]
										   initWithTitle:@"Error retrieving LIBOR Curve"
										   message: [NSString stringWithFormat:@"Could not set Trade Date to: %@", newDate]
										   delegate:self
										   cancelButtonTitle:@"Continue"
										   otherButtonTitles:nil];
				[errorAlert show];
				[errorAlert release];
			}
		}
	
	}
	
		//hide the picker
	currentPicker.hidden = YES;
	currentPicker = nil;	
}

// return the picker frame based on its size, positioned at the bottom of the page
- (CGRect)pickerFrameWithSize:(CGSize)size
{
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGRect pickerRect = CGRectMake(	0.0,
								   screenRect.size.height - 84.0 - size.height-120,
								   size.width,
								   size.height);
	return pickerRect;
}

- (void)showPicker:(UIView *)picker
{
	// hide the current picker and show the new one
	if (currentPicker)
	{
		currentPicker.hidden = YES;
	}
	picker.hidden = NO;
	
	currentPicker = picker;	// remember the current picker so we can remove it later when another one is chosen	
}

- (void) createMaturityPickerView
{
	maturityMonthViewArray = [[NSArray arrayWithObjects:@"March", @"June", @"September", @"December", nil] retain];
	
	//add the next 30 years to the picker
	maturityYearViewArray = [[NSMutableArray arrayWithCapacity:30] retain];
	int year = [[[[NSDate date] description] substringToIndex:5] intValue];
	for (int i=0; i<=30; i++) 
	{
		[maturityYearViewArray addObject:[NSString stringWithFormat:@"%d", year+i]];
	}
	
	// note we are using CGRectZero for the dimensions of our picker view,
	// this is because picker views have a built in optimum size,
	// you just need to set the correct origin in your view.
	//
	// position the picker at the bottom
	
	maturityPickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
	CGSize pickerSize = [maturityPickerView sizeThatFits:CGSizeZero];
	maturityPickerView.frame = [self pickerFrameWithSize:pickerSize];
	
	// currencyPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0,200,0,0)];
	
	maturityPickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	maturityPickerView.showsSelectionIndicator = YES;	// note this is default to NO
	
	// this view controller is the data source and delegate
	maturityPickerView.delegate = self;
	maturityPickerView.dataSource = self;
	
	// add this picker to our view controller, initially hidden
	maturityPickerView.hidden = YES;
	
}


- (void) createCurrencyPickerView
{
	//To Do: JPY needs calendars ;)
	currencyViewArray = [[NSArray arrayWithObjects:
						  @"USD", @"EUR", @"AUD", @"CAD", @"CHF"
						  , @"GBP" /*, @"JPY"*/, @"SGD", @"HKD", @"NZD"
						  , nil] retain];
	
	
	 // note we are using CGRectZero for the dimensions of our picker view,
	 // this is because picker views have a built in optimum size,
	 // you just need to set the correct origin in your view.
	 //
	 // position the picker at the bottom
	
	 currencyPickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
	 CGSize pickerSize = [currencyPickerView sizeThatFits:CGSizeZero];
	 currencyPickerView.frame = [self pickerFrameWithSize:pickerSize];
	
	// currencyPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0,200,0,0)];

	 currencyPickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	 currencyPickerView.showsSelectionIndicator = YES;	// note this is default to NO
	 
	 // this view controller is the data source and delegate
	 currencyPickerView.delegate = self;
	 currencyPickerView.dataSource = self;
	 
	 // add this picker to our view controller, initially hidden
	 currencyPickerView.hidden = YES;

}

- (void) createNotionalPickerView
{	
	notionalPickerArray = [[NSArray arrayWithObjects:
						  @"0", @"1", @"2", @"3", @"4"
						  , @"5", @"6", @"7", @"8", @"9"
						  , nil] retain];
		
	// note we are using CGRectZero for the dimensions of our picker view,
	// this is because picker views have a built in optimum size,
	// you just need to set the correct origin in your view.
	//
	// position the picker at the bottom
	
	notionalPickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
	CGSize pickerSize = [notionalPickerView sizeThatFits:CGSizeZero];
	notionalPickerView.frame = [self pickerFrameWithSize:pickerSize];
		
	notionalPickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	notionalPickerView.showsSelectionIndicator = YES;	// note this is default to NO
	
	// this view controller is the data source and delegate
	notionalPickerView.delegate = self;
	notionalPickerView.dataSource = self;
	
	// add this picker to our view controller, initially hidden
	notionalPickerView.hidden = YES;	
}


- (void) createRecoveryPickerView
{	
	recoveryPickerArray = [[NSArray arrayWithObjects:
							@"0", @"1", @"2", @"3", @"4"
							, @"5", @"6", @"7", @"8", @"9"
							, nil] retain];
	
	// note we are using CGRectZero for the dimensions of our picker view,
	// this is because picker views have a built in optimum size,
	// you just need to set the correct origin in your view.
	//
	// position the picker at the bottom
	
	recoveryPickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
	CGSize pickerSize = [recoveryPickerView sizeThatFits:CGSizeZero];
	recoveryPickerView.frame = [self pickerFrameWithSize:pickerSize];
	
	recoveryPickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	recoveryPickerView.showsSelectionIndicator = YES;	// note this is default to NO
	
	// this view controller is the data source and delegate
	recoveryPickerView.delegate = self;
	recoveryPickerView.dataSource = self;
	
	// add this picker to our view controller, initially hidden
	recoveryPickerView.hidden = YES;	
}

- (void) createPricePickerView
{	
	/*
	pricePickerArray = [[NSArray arrayWithObjects:
							@"0", @"1", @"2", @"3", @"4"
							, @"5", @"6", @"7", @"8", @"9"
							, nil] retain];
	*/

	pricePickerView = [[QuotedSpreadViewController alloc] 
							initWithNibName:@"QuotedSpreadViewController" 
							bundle:nil];
	
	/*
	 
	// note we are using CGRectZero for the dimensions of our picker view,
	// this is because picker views have a built in optimum size,
	// you just need to set the correct origin in your view.
	//
	// position the picker at the bottom
	
	pricePickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
	CGSize pickerSize = [pricePickerView sizeThatFits:CGSizeZero];
	pricePickerView.frame = [self pickerFrameWithSize:pickerSize];
	
	pricePickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	pricePickerView.showsSelectionIndicator = YES;	// note this is default to NO
	
	// this view controller is the data source and delegate
	pricePickerView.delegate = self;
	pricePickerView.dataSource = self;
	
	// add this picker to our view controller, initially hidden
	pricePickerView.hidden = YES;	

	 */
}

- (void) createTradeDatePickerView
{	
	// note we are using CGRectZero for the dimensions of our picker view,
	// this is because picker views have a built in optimum size,
	// you just need to set the correct origin in your view.
	//
	// position the picker at the bottom
	
	tradeDatePickerView = [[UIDatePicker alloc] initWithFrame:CGRectZero];
	CGSize pickerSize = [tradeDatePickerView sizeThatFits:CGSizeZero];
	tradeDatePickerView.frame = [self pickerFrameWithSize:pickerSize];
	
	tradeDatePickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//	tradeDatePickerView.showsSelectionIndicator = YES;	// note this is default to NO
	tradeDatePickerView.datePickerMode = UIDatePickerModeDate;

	// this view controller is the data source and delegate
//	tradeDatePickerView.delegate = self;
//	tradeDatePickerView.dataSource = self;
	
	// add this picker to our view controller, initially hidden
	tradeDatePickerView.hidden = YES;	
}

#pragma mark -
#pragma mark UIActionSheet

- (IBAction)dialogCurrencyPicker:(id)sender 
{
	UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:@"Select Currency\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
													  delegate:self
											 cancelButtonTitle:@"Done"
										destructiveButtonTitle:nil
											 otherButtonTitles:nil];
	// Add the picker
	if (!currencyPickerView)
	{
		[self createCurrencyPickerView];	
	}
	[menu setBounds:CGRectMake(0,0,320, 700)];
	[menu addSubview:currencyPickerView];
	[self showPicker:currencyPickerView];
	
	//set the picker to the current selection
	NSString *currency = [CurrencyCtrl titleForState:UIControlStateNormal];
	int count = [currencyViewArray count];
	for (int i=0; i<count; i++) 
	{
		//NSLog(@"%d - %@ - %@", i, currency, [currencyViewArray objectAtIndex: i]); 
		if ([currency isEqualToString:[currencyViewArray objectAtIndex: i]])
		{
			//we found it
			[currencyPickerView	selectRow:i inComponent:0 animated:NO];			
			break;
		}
	}
	
	//this is a modal call
	//[menu showInView:self.view];
	[menu showInView:self.parentViewController.view];
	
	//cleanup
	[menu release];
}


- (IBAction)dialogMaturityPicker:(id)sender 
{
	UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:@"Select Maturity\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
													  delegate:self
											 cancelButtonTitle:@"Done"
										destructiveButtonTitle:nil
											 otherButtonTitles:nil];
	// Add the picker
	if (!maturityPickerView)
	{
		[self createMaturityPickerView];	
	}
		
	[menu setBounds:CGRectMake(0,0,320, 700)];
	[menu addSubview:maturityPickerView];
	[self showPicker:maturityPickerView];
	
	//get the current selection
	NSString			*maturityString		= [MaturityText titleForState:UIControlStateNormal];
	NSDate				*maturity			=  [dateCalc convertStringToDate:maturityString];
	NSCalendar			*gregorian			= [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents	*weekdayComponents	= [gregorian 
											   components:(NSDayCalendarUnit | NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit) 
											   fromDate:maturity];
	
		//default the picker to the current selection
	int year	= [[NSString	stringWithFormat:@"%4d", [weekdayComponents year]] intValue];
	int month	= [[NSString	stringWithFormat:@"%2d", [weekdayComponents month]] intValue];
	[maturityPickerView selectRow:((month/3)-1) inComponent:0 animated:NO];
	[maturityPickerView	selectRow:(year-[[maturityYearViewArray objectAtIndex:0] intValue]) inComponent:1 animated:NO];
	
	//this is a modal call
	//[menu showInView:self.view];
	[menu showInView:self.parentViewController.view];

	//cleanup
	[menu release];
}

- (IBAction)dialogNotionalPicker:(id)sender 
{
	UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:@"Select Notional\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
													  delegate:self
											 cancelButtonTitle:@"Done"
										destructiveButtonTitle:nil
											 otherButtonTitles:nil];
	// Add the picker
	if (!notionalPickerView)
	{
		[self createNotionalPickerView];	
	}
	[menu setBounds:CGRectMake(0,0,320, 700)];
	[menu addSubview:notionalPickerView];
	[self showPicker:notionalPickerView];
	
		//get the current notional (get rid of any appended M(millions)
	NSString *currentNotional = [[NotionalText titleForState:UIControlStateNormal] stringByReplacingOccurrencesOfString:@"M" withString: @""];


	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[numberFormatter setPositiveFormat:@"0,000,000.00"];
	[numberFormatter setNegativeFormat:@"(0,000,000.00)"];	

	//get rid of thecommas (if there are any
	currentNotional = [currentNotional stringByReplacingOccurrencesOfString:[numberFormatter groupingSeparator] withString:@""];

	//handle the decimal
	int notionalLength = [currentNotional length];
	NSRange theNumberRange = [currentNotional rangeOfString:[numberFormatter decimalSeparator]];
	if (theNumberRange.location != NSNotFound)
	{
		//set the first decimal
		theNumberRange.location += 1;
		theNumberRange.length	= 1;
		[notionalPickerView selectRow:[[currentNotional substringWithRange:theNumberRange] intValue] inComponent:6 animated:NO];

		//set the second decimal
		theNumberRange.location += 1;
		if ((notionalLength-1) == theNumberRange.location)  //-1 discounts the decimal point
		{
			[notionalPickerView selectRow:[[currentNotional substringWithRange:theNumberRange] intValue] inComponent:7 animated:NO];
		}
		
		//strip the decimal off the notional
		theNumberRange.location -= 2;
		currentNotional = [currentNotional substringToIndex: theNumberRange.location];
		notionalLength = [currentNotional length];
	}
	else 
	{
			//no decimals
		[notionalPickerView selectRow:0 inComponent:6 animated:NO];
		[notionalPickerView selectRow:0 inComponent:7 animated:NO];
	}

	/*
		//set the picker, component 0=1e5, 1=1e4 etc
	int offset = 0;
	int theRow = 0;
	for (int i=0; i<7; i++) 
	{

		theRow = 0;
		if (notionalLength >= (7-i)) 
		{
			theNumberRange.location = i-offset;
			theNumberRange.length	= 1;
			theRow = [[currentNotional substringWithRange:theNumberRange] intValue];
		}
		offset++;

		[notionalPickerView selectRow:theRow inComponent:i animated:NO];
	}
	*/
	
	//set the picker, component 0=1e5, 1=1e4 etc
	int offset = 0;
	for (int i=0; i<6; i++) 
	{
		int theRow;
		if (notionalLength >= (6-i)) 
		{
			theNumberRange.location = i-offset;
			theNumberRange.length	= 1;
			theRow = [[currentNotional substringWithRange:theNumberRange] intValue];
		}
		else 
		{
			offset++;
			theRow = 0;
		}
		
		[notionalPickerView selectRow:theRow inComponent:i animated:NO];
	}

	
/*
	NSNumber *notional = [numberFormatter numberFromString:currentNotional];

	NSLog(@"%f",)
	NSLog(@"decimalSeparator  - %@",[numberFormatter decimalSeparator]);
	NSLog(@"groupingSeparator - %@",[numberFormatter groupingSeparator]);
	NSLog(@"%@",currentNotional);
	NSLog(@"Float - %f",[notional floatValue]);
	NSLog(@"double - %f",[notional doubleValue]);
	NSLog(@"string - %@",notional);
*/
	
	//this is a modal call
	//[menu showInView:self.view];
	[menu showInView:self.parentViewController.view];

	//cleanup
	[menu release];
}


- (IBAction)dialogRecoveryPicker:(id)sender 
{
	UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:@"Select Recovery\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
													  delegate:self
											 cancelButtonTitle:@"Done"
										destructiveButtonTitle:nil
											 otherButtonTitles:nil];
	// Add the picker
	if (!recoveryPickerView)
	{
		[self createRecoveryPickerView];	
	}	
	[menu setBounds:CGRectMake(0,0,320, 700)];
	[menu addSubview:recoveryPickerView];
	[self showPicker:recoveryPickerView];
	
	
	//get the current recovery (get rid of any appended %)
	NSString *currentRecovery = [[RecoveryText titleForState:UIControlStateNormal] stringByReplacingOccurrencesOfString:@"%" withString: @""];

	//set the picker, component 0=1e5, 1=1e4 etc
	int recoveryLength = [currentRecovery length];
	int offset = 0;
	NSRange theNumberRange;
	for (int i=0; i<3; i++) 
	{
		int theRow;
		if (recoveryLength >= (3-i)) 
		{
			theNumberRange.location = i-offset;
			theNumberRange.length	= 1;
			theRow = [[currentRecovery substringWithRange:theNumberRange] intValue];
		}
		else 
		{
			offset++;
			theRow = 0;
		}
		
		[recoveryPickerView selectRow:theRow inComponent:i animated:NO];
	}
	
	//this is a modal call
	//[menu showInView:self.view];
	[menu showInView:self.parentViewController.view];

	//cleanup
	[menu release];
}

- (IBAction)dialogPricePicker:(id)sender 
{

	//get the current price, we need to check the button to see if we quoted fee or spread
	NSString *currentQuote	= [PriceText titleForState:UIControlStateNormal];
	NSRange theRange		= [currentQuote rangeOfString:@"bps"];
	NSString *currentFee	= [NSString stringWithFormat:@"%.3f"
								, [[outFeeQuote titleForState: UIControlStateNormal] doubleValue]];
	NSString *currentSpread	= [outSpread titleForState: UIControlStateNormal];
	
	// Add the picker
	if (!pricePickerView)
	{
		[self createPricePickerView];	
	}
	
	//set the picker (both spread and fee)
	[pricePickerView showActionSheet:self.parentViewController.view 
							isSpread:(theRange.location != NSNotFound) 
							spread:currentSpread 
							fee:currentFee
							parentViewController: self
						];
	
/*
	UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:@"Select Quoted Spread\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
													  delegate:self
											 cancelButtonTitle:@"Done"
										destructiveButtonTitle:nil
											 otherButtonTitles:nil];
	// Add the picker
	if (!pricePickerView)
	{
		[self createPricePickerView];	
	}
	[menu setBounds:CGRectMake(0,0,320, 700)];
	[menu addSubview:pricePickerView.view];
	 
	//[self showPicker:pricePickerView];
	

	
	//set the picker, component 0=1e5, 1=1e4 etc
	int priceLength = [currentPrice length];
	int offset = 0;
	NSRange theNumberRange;
	for (int i=0; i<4; i++) 
	{
		int theRow;
		if (priceLength >= (4-i)) 
		{
			theNumberRange.location = i-offset;
			theNumberRange.length	= 1;
			theRow = [[currentPrice substringWithRange:theNumberRange] intValue];
		}
		else 
		{
			offset++;
			theRow = 0;
		}
		
		[pricePickerView selectRow:theRow inComponent:i animated:NO];
		
	} //for i
	
	//this is a modal call
	//[menu showInView:self.view];
	[menu showInView:self.parentViewController.view];

	//cleanup
	[menu release];
*/
}

- (IBAction)dialogTradeDatePicker:(id)sender 
{
	UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:@"Select Trade Date\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
													  delegate:self
											 cancelButtonTitle:@"Done"
										destructiveButtonTitle:nil
											 otherButtonTitles:nil];
	// Add the picker
	if (!tradeDatePickerView)
	{
		[self createTradeDatePickerView];	
	}

		//get the current value
	tradeDatePickerView.date = [self getTradeDate];
								
	[menu setBounds:CGRectMake(0,0,320, 700)];
	[menu addSubview:tradeDatePickerView];
	[self showPicker:tradeDatePickerView];
	
	//this is a modal call
	//[menu showInView:self.view];
	[menu showInView:self.parentViewController.view];

	//cleanup
	[menu release];
}

- (IBAction)debugInfoAlert:(id)sender
{
	NSString *theMessage = [self debugInfo];
	
	UIAlertView *debugAlert = [[UIAlertView alloc]
							   initWithTitle:@"Debug Info"
							   message:theMessage
							   delegate:self
							   cancelButtonTitle:@"Continue"
							   otherButtonTitles:nil];	

//	UITextView *theText = [debugAlert valueForKey:@"_bodyTextLabel"]; 
//	theText.font = [UIFont fontWithName:@"Courier" size: 8]; 
	
	[debugAlert show];
	[debugAlert release];
}

#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	NSString *returnStr = @"";
	
	// note: custom picker doesn't care about titles, it uses custom views
	if (pickerView == currencyPickerView)
	{
		if (component == 0)
		{
			returnStr = [currencyViewArray objectAtIndex:row];
		}
	}
	else if (pickerView == maturityPickerView)
	{
		if (component == 0)
		{
			returnStr = [maturityMonthViewArray objectAtIndex:row];
		}
		else
		{
			returnStr = [maturityYearViewArray objectAtIndex:row];
		}
		 
	} else if (pickerView == notionalPickerView)
	{
		if (component == 6) 
		{
			returnStr = [NSString stringWithFormat:@".%@", [notionalPickerArray objectAtIndex:row]];			
		} 
		else if (component == 2) 
		{
			returnStr = [NSString stringWithFormat:@"%@,", [notionalPickerArray objectAtIndex:row]];			
		} 
		else 
		{
			returnStr = [notionalPickerArray objectAtIndex:row];			
		}
	} else if (pickerView == recoveryPickerView)
	{
		returnStr = [recoveryPickerArray objectAtIndex:row];				
	} 
	/*
	 else if (pickerView == pricePickerView)
	{
		returnStr = [pricePickerArray objectAtIndex:row];				
	}
*/
	return returnStr;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	CGFloat componentWidth = 0.0;
	
	if (pickerView == currencyPickerView)
	{
		componentWidth = 280.0;
	}
	else if (pickerView == maturityPickerView)
	{	
		if (component == 0)
			componentWidth = 180.0;	// first column size is wider to hold months
		else
			componentWidth = 100.0;	// second column is narrower to show years
	} else if (pickerView == notionalPickerView)
	{
		//assuming 7 columns  BB, MMM . KK (Billions, millions .thousands)
		componentWidth = 35.0;
	} else if (pickerView == recoveryPickerView)
	{
		componentWidth = 280.0/3;
	} 
	
	/*
	 else if (pickerView == pricePickerView)
	{
		componentWidth = 280.0/4;
	}
	 */
	return componentWidth;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 40.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	NSInteger result = 0;

	if (currentPicker == currencyPickerView) 
	{
		result = [currencyViewArray count];
	}
	else if (pickerView == maturityPickerView)
	{
		if (component == 0) 
		{
			result = [maturityMonthViewArray count];
		}
		else
		{
			result = [maturityYearViewArray count];
		}
	} else if (pickerView == notionalPickerView)
	{
		result = [notionalPickerArray count];
	} else if (pickerView == recoveryPickerView)
	{
		if (component == 0) 
		{
				//only 0 and 1 makes sense forthe 100's place for recovery
			result = 2;
		}
		else
		{
			result = [recoveryPickerArray count];
		}
	} 
	/*
	 else if (pickerView == pricePickerView)
	{
		result = [pricePickerArray count];
	}
*/
	return result;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	NSInteger result = 1;
	
	//if (currentPicker == currencyPickerView) 
	//	return 1;

	if (pickerView == maturityPickerView)
	{
		result = 2;
	} else if (pickerView == notionalPickerView)
	{
		result = 8;
	} else if (pickerView == recoveryPickerView)
	{
		result = 3;
	} 
	/*
	 else if (pickerView == pricePickerView)
	{
		result = 4;
	}
	 */
	return result;
}

#pragma mark -
#pragma mark UIViewController

/*
 // The designated initializer. Override to perform setup that is required before the view is loaded.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
 // Custom initialization
 }
 return self;
 }
 */

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */


 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad 
{
#ifdef DEBUG
	NSLog(@"enabling debug info");
	//((UIView *)outUpFrontFee).userInteractionEnabled = YES;
	[outUpFrontFee setEnabled: YES];
#endif
	
	[super viewDidLoad];
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	
	tradeDatePickerView = nil;
	
	recoveryPickerView = nil;
	recoveryPickerArray = nil;
	
	pricePickerView = nil;
//	pricePickerArray = nil;
	
	notionalPickerView = nil;
	notionalPickerArray = nil;
	
	currencyViewArray = nil;
	currencyPickerView = nil;
	maturityPickerView = nil;
	maturityMonthViewArray = nil;
	maturityYearViewArray = nil;
}

- (void)dealloc {
	
	[recoveryPickerView release];
	[recoveryPickerArray release];
	
	[pricePickerView release];
//	[pricePickerArray release];
	
	[notionalPickerView release];
	[notionalPickerArray release];
	[currencyViewArray release];
	[currencyPickerView release];

	[maturityPickerView release];
	[maturityMonthViewArray release];
	
	//todo: do i need to release each member?
	[maturityYearViewArray release];

	[tradeDatePickerView release];
	
    [super dealloc];
}

@end
