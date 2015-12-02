//
//  LiborViewController.h
//  Created by James Zucker on 11/14/09.
//  Copyright James A. Zucker 2009, 2010. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "XMLAppDelegate.h"
//#import "LiborCurve.h"

//@class CurveInstrumentDetailViewController;

@interface LiborViewController : UITableViewController
//@interface LiborViewController : XMLAppDelegate
{
	XMLAppDelegate						*appDelegate;
	//CurveInstrumentDetailViewController *idvController_;
	
	//Fields in the Header
	UIView *headerView;
	UILabel *currencyLabel;
	UILabel *spotDateLabel;
	UILabel *effectiveDateLabel;
	UILabel *calendarLabel;
	UILabel *fixedDayCountLabel;
	UILabel *fixedFreqencyLabel;
	UILabel *floatDayCountLabel;
	UILabel *floatFreqencyLabel;
}

//@property (nonatomic, retain) CurveInstrumentDetailViewController *idvController_;
@property (nonatomic, retain) IBOutlet UIView *headerView;
@property (nonatomic, retain) IBOutlet UILabel *currencyLabel;
@property (nonatomic, retain) IBOutlet UILabel *spotDateLabel;
@property (nonatomic, retain) IBOutlet UILabel *effectiveDateLabel;
@property (nonatomic, retain) IBOutlet UILabel *calendarLabel;
@property (nonatomic, retain) IBOutlet UILabel *fixedDayCountLabel;
@property (nonatomic, retain) IBOutlet UILabel *fixedFreqencyLabel;
@property (nonatomic, retain) IBOutlet UILabel *floatDayCountLabel;
@property (nonatomic, retain) IBOutlet UILabel *floatFreqencyLabel;
@end
