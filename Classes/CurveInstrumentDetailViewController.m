//
//  CurveInstrumentDetailViewController.m
//  Created by James Zucker on 11/30/09.
//  Copyright 2009, 2010 James A Zucker. All rights reserved.
//

#import "CurveInstrumentDetailViewController.h"
#import "CurveInstrument.h"

@implementation CurveInstrumentDetailViewController

@synthesize theInstrument;

/*
// Override initWithNibName:bundle: to load the view using a nib file then perform additional customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Instrument";
}

- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	
	[tableView reloadData];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
	
	switch(indexPath.section)
	{
		case 0:
			cell.text = theInstrument.instrument;
			break;
		case 1:
			cell.text = theInstrument.tenor;
			break;
		case 2:
			cell.text = theInstrument.parrate;
			break;
/*
		case 3:
			cell.text = theInstrument.daycountconvention;
			break;
		case 4:
			cell.text = theInstrument.spotdate;
			break;
		case 5:
			cell.text = theInstrument.snaptime;
			break;
*/
	}
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tblView titleForHeaderInSection:(NSInteger)section {
	
	NSString *sectionName = nil;
	
	switch(section)
	{
		case 0:
            sectionName = @"Instrument";
			break;
		case 1:
            sectionName = @"Tenor";
			break;
		case 2:
            sectionName = @"Par Rate";
			break;
			/*
		case 3:
			sectionName = [NSString stringWithString:@"Daycount"];
			break;
		case 4:
			sectionName = [NSString stringWithString:@"SpotDate"];
			break;
		case 5:
			sectionName = [NSString stringWithString:@"SnapTime"];
			break;
*/
	}
	
	return sectionName;
}

- (void)dealloc {
	
	[theInstrument release];
	[tableView release];
    [super dealloc];
}


@end
