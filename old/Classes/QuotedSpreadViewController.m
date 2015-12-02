//
//  QuotedSpreadViewController.m
//  iCDS
//
//  Created by James Zucker on 1/24/10.
//  Copyright 2010 James A Zucker. All rights reserved.
//

#import "QuotedSpreadViewController.h"

@implementation QuotedSpreadViewController


@synthesize priceBasisPickerView, priceFeePickerView, FeeBasisCtrl, pricePickerArray, currentValue, parentViewController;

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{	
	[self setCurrentValue: [self getCurrentQuote]];
	NSLog(@"currentValue=%@",[self currentValue]);
	[[self parentViewController] setPriceTextButton: [self currentValue]];
}

- (NSString *) getCurrentQuote
{
	int isSpreadQuote = [FeeBasisCtrl selectedSegmentIndex] == 0;
	NSString *theString = nil;
	
	if ( isSpreadQuote ) {
		int theAmount = [priceBasisPickerView selectedRowInComponent:0] * 1e3
			+ [priceBasisPickerView selectedRowInComponent:1] * 1e2
			+ [priceBasisPickerView selectedRowInComponent:2] * 1e1
		+ [priceBasisPickerView selectedRowInComponent:3];
		
		theString = [NSString stringWithFormat:@"%d%@",theAmount,@" bps"];

	} else {
			//fee with decimal
		double decimal = [priceFeePickerView selectedRowInComponent:3] / 10.0
							+ [priceFeePickerView selectedRowInComponent:4] / 100.0
							+ [priceFeePickerView selectedRowInComponent:5] / 1000.0;
		
		double theAmount = [priceFeePickerView selectedRowInComponent:0] * 1e2
			+ [priceFeePickerView selectedRowInComponent:1] * 1e1
			+ [priceFeePickerView selectedRowInComponent:2] 
			+ decimal;
		
		theString = [NSString stringWithFormat:@"%3.3f%@",theAmount,@" %"];
	}

	return theString;
}

- (void) setValue:(BOOL)isSpread spread:(NSString *)currentSpread fee:(NSString *)currentFee
{
		//set the segement controller, 0==Spread, 1==Fee
	int theSegment = isSpread ? 0 : 1;
	[FeeBasisCtrl setSelectedSegmentIndex:theSegment];

	priceBasisPickerView.hidden = theSegment == 1;
	priceFeePickerView.hidden	= theSegment == 0;

		//set the spread picker, since we display decimals, round it.
	NSString *theSpread = [NSString stringWithFormat:@"%.0f", [currentSpread doubleValue]];
	int offset	= 0;
	int i		= 0;
	NSRange theNumberRange;
	int thelength = [theSpread length];
	for (i=0; i<4; i++) 
	{
		int theRow;
		if (thelength >= (4-i)) 
		{
			theNumberRange.location = i-offset;
			theNumberRange.length	= 1;
			theRow = [[theSpread substringWithRange:theNumberRange] intValue];
		}
		else 
		{
			offset++;
			theRow = 0;
		}
		[priceBasisPickerView selectRow:theRow inComponent:i animated:NO];		
	} //for i
	
	
	//set the fee picker, its precision matches what is stored
	offset = 0;
	NSString *theString = [currentFee stringByReplacingOccurrencesOfString:@"." withString:@""];
	thelength = [theString length];
//	for (i=0; i<5; i++) 
	for (i=0; i<6; i++) 
	{
		int theRow;
		//if (thelength >= (5-i)) 
		if (thelength >= (6-i)) 
		{
			theNumberRange.location = i-offset;
			theNumberRange.length	= 1;
			theRow = [[theString substringWithRange:theNumberRange] intValue];
		}
		else 
		{
			offset++;
			theRow = 0;
		}
		[priceFeePickerView selectRow:theRow inComponent:i animated:NO];		
	} //for i
	
}
 
- (void) showActionSheet:(UIView *)theView isSpread:(BOOL)isSpread spread:(NSString *)currentSpread fee:(NSString *)currentFee 
			parentViewController:(UIViewController *)theParentController
{
	[self setParentViewController: theParentController];
	
		//create the alert
	UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:@"Select Quoted Spread\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
													   delegate:self
											  cancelButtonTitle:@"Done"
										 destructiveButtonTitle:nil
											  otherButtonTitles:nil];
	
   	[alert setBounds:CGRectMake(0,0,320,700)];
	[alert addSubview:self.view];

		//set the current values
	[self setValue:isSpread spread:currentSpread fee:currentFee];

	[alert showInView:theView];	
    [alert release];
	
}


 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization

		pricePickerArray = [[NSArray arrayWithObjects:
							 @"0", @"1", @"2", @"3", @"4"
							 , @"5", @"6", @"7", @"8", @"9"
							 , nil] retain];	
		
		
		
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
	if (pricePickerArray == nil) {
		pricePickerArray = [[NSArray arrayWithObjects:
						 @"0", @"1", @"2", @"3", @"4"
						 , @"5", @"6", @"7", @"8", @"9"
						 , nil] retain];	
	}
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
	priceFeePickerView		= nil;
	priceBasisPickerView	= nil;
	FeeBasisCtrl			= nil;
	pricePickerArray		= nil;
}

- (void)dealloc {
	[priceFeePickerView release];
	[priceBasisPickerView release];
	[FeeBasisCtrl release];
	[pricePickerArray release];
    [super dealloc];
}

#pragma mark -
#pragma mark UISegmentedControl

- (IBAction)ChangeFeeBasis:(id)sender
{
	//
	//0 is basis, 1 is Fee
	//
	int currentSelection= [FeeBasisCtrl selectedSegmentIndex];

	if ( currentSelection == 0 && priceBasisPickerView.hidden == YES )
	{
		//changed to basis
		priceBasisPickerView.hidden = NO;
		priceFeePickerView.hidden	= YES;
		
	} else if (currentSelection == 1 && priceFeePickerView.hidden == YES )
	{
		//chnaged to Fee
		priceBasisPickerView.hidden = YES;
		priceFeePickerView.hidden	= NO;
	}
}


#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	NSString *returnStr = @"";
	
	// note: custom picker doesn't care about titles, it uses custom views
	if (pickerView == priceFeePickerView)
	{
		if (component == 3) 
		{
			returnStr = [NSString stringWithFormat:@".%@", [pricePickerArray objectAtIndex:row]];			
		} 
		else 
		{
			returnStr = [pricePickerArray objectAtIndex:row];			
		}
	} else {
		returnStr = [pricePickerArray objectAtIndex:row];				
	}
	
	return returnStr;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	CGFloat componentWidth = 0.0;
	
	if (pickerView == priceBasisPickerView)
	{
		componentWidth = 280.0/4;
	}
	else if (pickerView == priceFeePickerView)
	{			
		componentWidth = 280.0/6;
	} 
	return componentWidth;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 40.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	NSInteger result = 0;
	if ( pickerView == priceFeePickerView && component == 0 ) 
	{
		result = 2;
	} else {
		result = [pricePickerArray count];
	}
	return result;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	NSInteger result = 1;
	
	//if (currentPicker == currencyPickerView) 
	//	return 1;
	
	if (pickerView == priceBasisPickerView)
	{
		result = 4;
	} else if (pickerView == priceFeePickerView)
	{
		result = 6;
	} 
	return result;
}
@end
