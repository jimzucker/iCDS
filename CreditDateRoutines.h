//
//  CreditDateRoutines.h
//  iCDS
//
//  Created by James Zucker on 12/10/09.
//  Copyright 2009,2010 James A Zucker. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CreditDateRoutines : NSObject {

}
- (NSString *) convertDateToString:(NSDate *) theDate;
- (NSDate *) bumpDate:(NSDate *)theDate days:(int) nDays months:(int) nMonths years:(int) nYears;

	//for sat/sunday move to Friday
- (NSDate *) moveToValidBusinessDate:(NSDate *) theDate rollForward:(BOOL)following;

	//bump a date by specefied # of businesdays
//- (NSDate *) bumpBusinesssDays:(NSDate *)theDate businessDays:(int) nDays;

- (NSDate *) getPeriodStartDate:(NSDate *) theTradeDate;
- (NSDate *) getTradeDate;

- (NSDate *) getCurrentCouponEnd: (BOOL) rollToAccrualEnd;
- (NSString *) yyyymmdd: (NSDate *) theDate;

- (NSDate *) getDateFromComponents:(int)theYear month:(int) theMonth day:(int) theDay;
- (NSDate *) convertStringToDate:(NSString *) theDate;
- (NSString *) convertDateToString:(NSDate *) theDate;


@end
