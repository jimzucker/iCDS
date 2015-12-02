//
//  LiborViewController.m
//  Created by James Zucker on 11/14/09.
//  Copyright James A. Zucker 2009, 2010. All rights reserved.
//

#import "LiborViewController.h"
#import "CurveInstrumentDetailViewController.h"
#import "CurveInstrument.h"
#import "LiborCurve.h"
#import "iCDSAppDelegate.h"

@implementation LiborViewController

@synthesize headerView, currencyLabel, spotDateLabel, effectiveDateLabel, calendarLabel, fixedDayCountLabel, fixedFreqencyLabel
	, floatDayCountLabel, floatFreqencyLabel;


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    int result = 0;
	
	if (appDelegate && appDelegate.liborCurve_)
		result = [appDelegate.liborCurve_.theTenors_ count];
	
	return result;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		[cell textLabel].font = [UIFont fontWithName:@"Helvetica" size:14.0];
    }
	
	if (appDelegate && appDelegate.liborCurve_)
	{
		CurveInstrument *tmpInstrument = [appDelegate.liborCurve_.theTenors_ objectAtIndex:indexPath.row];
		if (tmpInstrument) 
		{
			[cell textLabel].text = [NSString stringWithFormat:@"%@ : %@ : %.6f", tmpInstrument.instrument, tmpInstrument.tenor, [tmpInstrument.parrate doubleValue]];
			/*
			cell.text = [[[[tmpInstrument.instrument stringByAppendingString:@" : "] 
				 stringByAppendingString:tmpInstrument.tenor]
				 stringByAppendingString:@" : "]
				 stringByAppendingString:tmpInstrument.parrate]
				;
			 */
		}
		
	//	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
		// Set up the cell
    return cell;
}

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // Navigation logic -- create and push a new view controller
	
	//NSLog(@"tableView");

	if(idvController_ == nil)
		idvController_ = [[CurveInstrumentDetailViewController alloc] initWithNibName:@"CurveInstrumentDetailView" bundle:[NSBundle mainBundle]];
	
	CurveInstrument *aInstrument = [appDelegate.liborCurve_.theTenors_ objectAtIndex:indexPath.row];

	idvController_.theInstrument = aInstrument;	
	[self.navigationController pushViewController:idvController_ animated:YES];
}
*/

- (void)viewDidUnload
{
	self.headerView = nil;
}


- (void)viewDidLoad 
{
	//NSLog(@"viewDidLoad");

    [super viewDidLoad];
	
    // Uncomment the following line to add the Edit button to the navigation bar.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

	// set up the table's header view based on our UIView 'headerView' outlet
	CGRect newFrame = CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, self.headerView.frame.size.height);
	self.headerView.backgroundColor = [UIColor clearColor];
	self.headerView.frame = newFrame;
	self.tableView.tableHeaderView = self.headerView;	// note this will override UITableView's 'sectionFooterHeight' property
}


/*
// Override to support editing the list
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support conditional editing of the list
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support rearranging the list
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the list
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	//NSLog(@"viewWillAppear");
	
	appDelegate = (XMLAppDelegate *)[ (iCDSAppDelegate *)[[UIApplication sharedApplication] delegate] liborXML];
	LiborCurve *theCurve = appDelegate.liborCurve_;
	if (theCurve) 
	{
		//populate the info on the curve
		currencyLabel.text		= theCurve.currency;
		spotDateLabel.text		= theCurve.spotdate;
		effectiveDateLabel.text = theCurve.effectiveasof;
		calendarLabel.text		= theCurve.holidays;
		fixedDayCountLabel.text = theCurve.fixeddaycountconvention;
		fixedFreqencyLabel.text = theCurve.fixedpaymentfrequency;
		floatDayCountLabel.text = theCurve.floatingdaycountconvention;
		floatFreqencyLabel.text = theCurve.floatingpaymentfrequency;
		//self.title = [@"SNAC Libor Curve : " stringByAppendingString:theCurve.effectiveasof];
	}
	
}


- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	//NSLog(@"viewWillDisappear");
}


- (void)viewWillDisappear:(BOOL)animated 
{
	//NSLog(@"viewWillDisappear");
}


- (void)viewDidDisappear:(BOOL)animated 
{
	//NSLog(@"viewDidDisappear");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	//NSLog(@"shouldAutorotateToInterfaceOrientation");

    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning 
{
	//NSLog(@"didReceiveMemoryWarning");

    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc 
{
	//NSLog(@"dealloc");

	[headerView release];
//	[idvController_ release];
	[appDelegate release];
    [super dealloc];
}

@end
