//
//  CreditDateRoutines.m
//  iCDS
//
//  Created by James Zucker on 12/10/09.
//  Copyright 2009,2010 James A Zucker. All rights reserved.
//

#import "CreditDateRoutines.h"


@implementation CreditDateRoutines

- (NSDate *) convertStringToDate:(NSString *) theDate
{
	// assume default behavior set for class using
	// [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	return [dateFormatter dateFromString:theDate];
	
}

- (NSString *) convertDateToString:(NSDate *) theDate
{
	// assume default behavior set for class using
	// [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	return [dateFormatter stringFromDate:theDate];
}

- (NSString *) yyyymmdd: (NSDate *) theDate
{
	NSCalendar			*gregorian			= [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents	*weekdayComponents	= [gregorian 
											   components:(NSDayCalendarUnit | NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit) 
											   fromDate:theDate];
	
	NSString *year	= [NSString	stringWithFormat:@"%.3d", [weekdayComponents year]];
	NSString *day	= [NSString	stringWithFormat:@"%.2d", [weekdayComponents day]];
	NSString *month	= [NSString	stringWithFormat:@"%.2d", [weekdayComponents month]];
	
	return [[year stringByAppendingString: month] stringByAppendingString:day];
}


- (NSDate *) getDateFromComponents:(int)theYear month:(int) theMonth day:(int) theDay
{
	//Get the currnet QuarterEnd Date, pStartDate + 3 Months	
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
	components.month	= theMonth;
	components.day		= theDay;
	components.year		= theYear;
		
	return [gregorian dateFromComponents:components];	
}

- (NSDate *) bumpDate:(NSDate *)theDate days:(int) nDays months:(int) nMonths years:(int) nYears
{
	
	//Bump the date as request	
	
	//Create a calendar object
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	
	//setup the 'bump'
	NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
	components.month	= nMonths;
	components.day		= nDays;
	components.year		= nYears;
	
	//bump the date
	NSDate *bumpDate = [gregorian dateByAddingComponents:components toDate:theDate options:0];
	
	return bumpDate;
	
}

- (NSDate *) moveToValidBusinessDate:(NSDate *) theDate rollForward:(BOOL) following
{
	NSCalendar *gregorian				= [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *weekdayComponents = [gregorian components:(NSDayCalendarUnit | NSWeekdayCalendarUnit) fromDate:theDate];
	NSInteger weekday					= [weekdayComponents weekday];
	
	//if we are on Sat/Sun move to a Monday
	int nBumpDays = 0 ;
	if (weekday == 1 )  //sunday
	{	
		if (following)
		{
			nBumpDays = 1;
		} else {
			nBumpDays = -2;
		}
	} else 	{
		if ( weekday == 7 ) //saturday
		{
			if (following)
			{
				nBumpDays = 2;
			} else {
				nBumpDays = -1;
			}
		}
	}
	
	return [self bumpDate:theDate days:nBumpDays months:0 years:0];	
}

- (NSDate *) getPeriodStartDate:(NSDate *) theTradeDate
{
	NSCalendar			*gregorian			= [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents	*weekdayComponents	= [gregorian 
											   components:(NSDayCalendarUnit | NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit) 
											   fromDate:theTradeDate];
	
	NSInteger nDay	= [weekdayComponents day];
	NSInteger nMonth= [weekdayComponents month];
	NSInteger nYear	= [weekdayComponents year];
	
	//if we are on the quarter
	if (nMonth == 3 || nMonth == 6 || nMonth == 9 || nMonth == 12) 
	{
		if (nDay <= 20 )
		{
			nMonth -= 3;
			if (nMonth == 0 ) 
			{
				nMonth = 12;
				nYear-- ;
			}
		}
		//else do nothing we started accruing in the current month ;)
	} else {
		if (nMonth <3 ) 
		{
			nMonth = 12;
			nYear -- ;
		} else 
		{
			if ( nMonth <6 )
			{
				nMonth = 3;
			} else {
				if ( nMonth <9 )
				{
					nMonth = 6;
				} else {
					nMonth = 9;
				}
			}
		}
	} //if we are on a quarter month
	
	
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setDay:20];
	[comps setMonth:nMonth];
	[comps setYear:nYear];
	NSDate *theDate = [gregorian dateFromComponents:comps];
	[comps release];
	
	return [self moveToValidBusinessDate:theDate rollForward:TRUE];
}

- (NSDate *) getTradeDate
{
	//get the current date	
	NSDate *today = [NSDate date];
	
	return [self moveToValidBusinessDate: today rollForward:TRUE];
	//return today;
}

- (NSDate *) getCurrentCouponEnd: (BOOL) rollToAccrualEnd
{
	//does not roll to the cpn payment date
	//get theStartDate
	NSDate * tradeDate		= [self getTradeDate];
	NSDate * startDate		= [self getPeriodStartDate:tradeDate];
	
	//Get the currnet QuarterEnd Date, pStartDate + 3 Months	
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
	components.month = 3;
	NSDate *cpnEndDate = [gregorian dateByAddingComponents:components toDate:startDate options:0];
	NSDateComponents *cpnEndComponents = [gregorian components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:cpnEndDate];	
	
	//we always roll on the 20th of the months
	cpnEndComponents.day = 20;
	
	return rollToAccrualEnd ? [self moveToValidBusinessDate:[gregorian dateFromComponents:cpnEndComponents] rollForward:TRUE] : [gregorian dateFromComponents:cpnEndComponents];	
}

@end
