//
//  CurveInstrumentDetailViewController.h
//  XML
//
//  Created by James Zucker on 11/30/09.
//  Copyright 2009, 2010 James A Zucker. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CurveInstrument;

@interface CurveInstrumentDetailViewController : UIViewController {

	IBOutlet UITableView *tableView;
	
	CurveInstrument	*theInstrument;
}

@property (nonatomic, retain) CurveInstrument	*theInstrument;

@end
