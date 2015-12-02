//
//  XMLAppDelegate.h
//  XML
//
//  Created by James Zucker on 11/14/09.
//  Copyright James A. Zucker 2009, 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "LiborCurve.h"

@interface XMLAppDelegate : UITableViewController
{
	LiborCurve					*liborCurve_;
}
- (BOOL)loadXML:(NSString *) theCurrency tradeDate:(NSDate *)tradeDate;

@property (nonatomic, retain)	LiborCurve		*liborCurve_;

@end

