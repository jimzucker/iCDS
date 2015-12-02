//
//  MarkItCalcController.m
//
//  Created by James Zucker on 11/15/09.
//  Copyright 2009,2010 James A Zucker. All rights reserved.
//


/*
 Specification
 •
 •
 User Inputs: 
	o Trade date T (should default to Today (current business day) ) 
	o Maturity Date	Specified by year and month (one of Mar/Jun/Sep/Dec) 20th of month is assumed 
	o Notional Amount (MM)
	o Standard Coupon as defined by the Standard CDS Contract Specifications 
	o Recovery Rate (%) 
		40% is used for senior unsecured. 
		20% is used for subordinate. 
		25% is used for emerging markets.(both senior and subordinate) 
 o Spread (bp) or Upfront (%)
 */


#import "MarkItCalcController.h"
#include "CreditDateRoutines.h"
#include "XMLAppDelegate.h"
#include "LiborCurve.h"
#include "iCDSAppDelegate.h"
#include "mdydate.h"
#include "cmemory.h"
#include "dateconv.h"

@implementation MarkItCalcController

@synthesize debugInfo;

TDate JpmcdsDate
(long year,  /* (I) Year */
 long month, /* (I) Month */
 long day    /* (I) Day */
 );


int idsa_JpmcdsCdsoneUpfrontCharge( double dCouponRate, double quotedSpread, double recovery, double dNotional
			   , TDate today
			   , TDate valueDate
			   , TDate startDate
			   , TDate endDate
			   , TDate benchmarkStart
			   , TDate stepinDate
			   , char *maturities[],double rates[]
			   , TDate spotDate
			   , const char *currency
			   , char baddayconvention			
			   , char *holidays			
			   , char *moneyMarketDCC			
			   , char *swapFixedDCC
			   , char *swapFloatDCC
			   , char *swapFloatFreq
			   , char *swapFixFreq
			   , char *types
			   , TBoolean isCleanPrice
			   , double *result
			);

int idsa_JpmcdsCdsoneSpread ( double couponRate, double upfrontCharge, double recovery, double notional
								, TDate today
								, TDate valueDate
								, TDate startDate
								, TDate endDate
								, TDate benchmarkStart
								, TDate stepinDate
								, char *maturities[],double rates[]
								, TDate spotDate
								, const char *currency
								, char baddayconvention			
								, char *holidays			
								, char *moneyMarketDCC			
								, char *swapFixedDCC
								, char *swapFloatDCC
								, char *swapFloatFreq
								, char *swapFixFreq
								, char *types
								, TBoolean isPriceClean
								, double *result
								);


void isda_calcValueAndStepinDate(TDate today
								 ,char baddayconvention
								 , char *holidays			
								 , TDate **valueDate
								 , TDate **stepinDate
								 );


//Converts an NSDate to a TDate for the Markit Library
- (TDate) convertToTDate:(NSDate *)theDate
{
	NSCalendar *gregorian				= [ [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *weekdayComponents = [
										   gregorian components:(NSDayCalendarUnit | NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:theDate];
	int nYear	= [weekdayComponents year];
	int nMonth	= [weekdayComponents month];
	int nDay	= [weekdayComponents day];
	
	//NSLog(@"%d %d %d", nYear, nMonth, nDay);
	return JpmcdsDate(nYear, nMonth, nDay);
	
}

- (NSDate *) convertTDateToNSDate:(TDate *) valueDateTDate
{
	TMonthDayYear mdy;
	
	JpmcdsDateToMDY( *valueDateTDate, &mdy );
		
	return [dateCalc getDateFromComponents:mdy.year month:mdy.month day:mdy.day];
}


- (void)setButtonText:(UIButton *)theButton title: (NSString *)theTitle recalc: (BOOL) doRecalc
{
	[theButton setTitle:theTitle forState: UIControlStateNormal];
	[theButton setTitle:theTitle forState: UIControlStateSelected];
	[theButton setTitle:theTitle forState: UIControlStateHighlighted];
	
	//re-calc the #s
	if (doRecalc) 
	{
		[self ReCalculate];
	}
	
}


/*
- (void)applicationDidFinishLaunching: (NSNotification *)aNotification		
{
	NSLog(@"\napplicationDidFinishLauching\n");
}
*/

/*
+ (void)initialize
{
	[super initialize];
	
	//I want to set the defaults here, can't figure it out
	NSLog(@"\ninitialize\n");
	
}	
*/

- (void) dealloc
{
	[dateCalc release];
	[super dealloc];
}

- (void) setMaturityDate: (NSDate *) maturityDate
{
	//get the next rolldate
	NSDate *couponEndDate	= [dateCalc getCurrentCouponEnd: FALSE];
	
	//bump it based on the requested maturity
	int nYears	=  [[ MaturityCtrl titleForSegmentAtIndex: [ MaturityCtrl selectedSegmentIndex ]] intValue ] ;
	NSDate *newMaturityDate = [dateCalc bumpDate:couponEndDate days:0 months:0 years:nYears];
	
	//update the GUI
	//MaturityText.text	= [dateCalc convertDateToString:newMaturityDate] ;	
	NSString *maturity = [dateCalc convertDateToString:newMaturityDate] ;
	[MaturityText setTitle:maturity forState: UIControlStateNormal];
	[MaturityText setTitle:maturity forState: UIControlStateSelected];
	[MaturityText setTitle:maturity forState: UIControlStateHighlighted];
	
}

- (NSString *) getCurrency
{
	return [ CurrencyCtrl titleForState: UIControlStateNormal] ;
}

- (void) calcMaturityDate
{
	//get Years from the control
	int nYears = [[ MaturityCtrl titleForSegmentAtIndex: [ MaturityCtrl selectedSegmentIndex ]] intValue] ;
	
	//calc the maturity date
	NSDate *newMaturity = [dateCalc bumpDate:[dateCalc getCurrentCouponEnd:FALSE] days:0 months:0 years:nYears];
	
	//update the textFiled
	[self setMaturityDate: newMaturity];
	
}

- (NSDate *) getMaturityDate
{
	
		//format the date based on user preferences
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	
		//if Maturity Date is not initialzed, initialize it
	if ( ![MaturityText titleForState:UIControlStateNormal] ) 
	{
		[self calcMaturityDate ];
	}
    NSDate *dateFromString = [dateFormatter dateFromString:[MaturityText titleForState:UIControlStateNormal]];	
	
	return dateFromString;
}

- (double) getStandardCoupon
{
	//get the value of the segment as a double
	double dStandardCoupon =  [[ StandardCouponCtrl titleForSegmentAtIndex: [ StandardCouponCtrl selectedSegmentIndex ]] doubleValue ] ;
	
	return dStandardCoupon ;
}

-(LiborCurve *) getLiborCurve
{
	LiborCurve *theCurve = nil;

	//Get the LIBOR curve
	XMLAppDelegate *appDelegate = (XMLAppDelegate *) [(iCDSAppDelegate *)[[UIApplication sharedApplication] delegate] liborXML];	
	if (appDelegate) 
	{
		//if we dont have the curve get it
		theCurve = appDelegate.liborCurve_;
		if (theCurve == nil) 
		{
			[self setLiborCurve:[self getCurrency] valueDate:[self getTradeDate]];
			theCurve = appDelegate.liborCurve_;
		}
	}
	return theCurve;	
}

- (BOOL) setLiborCurve: (NSString *)currency valueDate:(NSDate *)theDate
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	BOOL returnStatus = NO;
	
	//Get the LIBOR curve
	XMLAppDelegate *appDelegate = (XMLAppDelegate *)
	[(iCDSAppDelegate *)[[UIApplication sharedApplication] delegate] liborXML];
	if (appDelegate) 
	{
		[appDelegate.liborCurve_ release];
		appDelegate.liborCurve_ = nil;
			
			//get the new libor curve, looking at the markit website, it always uses the current LIBOR curve
		returnStatus = [appDelegate loadXML:currency tradeDate:theDate];
//		returnStatus = [appDelegate loadXML:currency tradeDate:[self getTradeDate]];
//		returnStatus = [appDelegate loadXML:currency tradeDate:[dateCalc getTradeDate]];
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	return returnStatus;
}

- (NSDate *) getTradeDate
{
	NSString *tradeDateString = [outTradeDate titleForState:UIControlStateNormal];
	NSDate *theDate = nil;
	
	//we need to bootstrap if it is not set here
	if (tradeDateString == nil)
	{
		theDate = [dateCalc getTradeDate];
		[self setTradeDate: theDate];
	}
	else 
	{
		theDate = [dateCalc convertStringToDate:tradeDateString];	
	}
	
	return theDate;
}

- (void) setTradeDate: (NSDate*)tradeDate
{
		//format it based on the users preferences
	NSString *theDate = [dateCalc convertDateToString:tradeDate];
	
	[outTradeDate setTitle:theDate forState: UIControlStateNormal];
	[outTradeDate setTitle:theDate forState: UIControlStateSelected];
	[outTradeDate setTitle:theDate forState: UIControlStateHighlighted];	
}


- (void) ReCalculate
{
	double notional = [[NotionalText titleForState:UIControlStateNormal] doubleValue]  * 1e6;
	
	//Recovery is shown on the GUI as a % with the "%" sign, strip it off and conver to a fraction
	double recovery	= [[RecoveryText titleForState:UIControlStateNormal] doubleValue ] / 100.0;
	
		//Calc the dates we need
	NSDate * tradeDate		= [self getTradeDate ];
	NSDate * maturityDate	= [self getMaturityDate];
	NSDate * startDate		= [dateCalc getPeriodStartDate:tradeDate];								//AccrualStart Date

	//get the currency
	const char *currency = [[self getCurrency] UTF8String];
	
	int isErr = 0;
	NSString *errMsg = @"noErr";

	//The spread is shown on the GUI with "%" if it is a fee or with "bps" if it is a spread
	double quotedSpread = [[PriceText titleForState:UIControlStateNormal] intValue ];
	double	quotedFee		= [[PriceText titleForState:UIControlStateNormal] doubleValue ];
	NSRange theRange		= [[PriceText titleForState:UIControlStateNormal] rangeOfString:@"bps"];
	BOOL	isSpreadQuoted	= (theRange.location != NSNotFound);
	
	LiborCurve *theCurve = [self getLiborCurve];
	if (theCurve) 
	{
				
			//for USD **need to set based on currency
		NSDate * spotDate		= [theCurve getSpotDate];
		
		char **maturies = [theCurve getTenors];
		double *rates = [theCurve getParRates];
		
		char baddayconvention	= *[theCurve.baddayconvention UTF8String];		
		char *holidays			= (char *)[theCurve.holidays UTF8String];
		char *moneyMarketDCC	= (char *)[theCurve.daycountconvention UTF8String];		
		char *swapFixedDCC		= (char *)[theCurve.fixeddaycountconvention UTF8String];
		char *swapFloatDCC		= (char *)[theCurve.floatingdaycountconvention UTF8String];
		char *swapFloatFreq		= (char *)[theCurve.floatingpaymentfrequency UTF8String];
		char *swapFixFreq		= (char *)[theCurve.fixedpaymentfrequency UTF8String];
		char *types				= (char *)[theCurve.types UTF8String];
		
		TDate tradeTDate = [self convertToTDate: tradeDate];
		TDate startTDate = [self convertToTDate: startDate];
		TDate maturityTDate = [self convertToTDate: maturityDate];
		TDate spotTDate = [self convertToTDate: spotDate];
		
		TDate *stepinDateTDate = nil;
		TDate *valueDateTDate = nil;
		isda_calcValueAndStepinDate( tradeTDate, baddayconvention, holidays, &valueDateTDate, &stepinDateTDate);
		NSString *stepInDate	= [dateCalc convertDateToString:[self convertTDateToNSDate:stepinDateTDate]];
		NSString *valueDate	= [dateCalc convertDateToString:[self convertTDateToNSDate:valueDateTDate]];
		
		//calc the spread if it fee quoted
		if (!isSpreadQuoted) 
		{			
			//call the calculator to the equiv spread
			double calcSpread = 0.0;
			isErr = idsa_JpmcdsCdsoneSpread ([self getStandardCoupon], quotedFee, recovery, notional
																 , tradeTDate						//trade date
																 , *valueDateTDate					//returns valueDate
																 , startTDate
																 , maturityTDate					//maturity
																 , startTDate						//benchmarkStart
																 , *stepinDateTDate					//returns stepinDate
																 
																 //params or zerocurve
																 , maturies
																 , rates
																 , spotTDate						//baseDate for the LiborCurve == T+2
																 , currency
																 , baddayconvention
																 , holidays
																 , moneyMarketDCC
																 , swapFixedDCC
																 , swapFloatDCC
																 , swapFloatFreq
																 , swapFixFreq
																 , types
																 , TRUE //isPriceClean
																, &calcSpread
																 );
			
			quotedSpread = calcSpread * 10000.0;
			
			if (isErr)
			{
					//we could not calc the equiv spread, show and error
				errMsg = @"Error: calc spread";
			}
		}
		
		double dirtyUpFront	= 0.0;
		double cleanUpFront = 0.0;
		if ( !isErr )
		{
			//call the calculator
			isErr = idsa_JpmcdsCdsoneUpfrontCharge([self getStandardCoupon], quotedSpread, recovery, notional
											, tradeTDate							//trade date
											, *valueDateTDate						//returns valueDate
											, startTDate
											, maturityTDate							//maturity
											, startTDate							//benchmarkStart
											, *stepinDateTDate						//returns stepinDate
												  
												  //params or zerocurve
											, maturies
											, rates
											, spotTDate								//baseDate for the LiborCurve == T+2
											, currency
											, baddayconvention
											, holidays
											, moneyMarketDCC
											, swapFixedDCC
											, swapFloatDCC
											, swapFloatFreq
											, swapFixFreq
											, types
											, FALSE //isPriceClean
											, &dirtyUpFront
											);
			
			if (isErr) //idsa_JpmcdsCdsoneUpfrontCharge
			{
				//show error to user
				errMsg = @"Error: calc fee";
			}
			else
			{
				//calc fee calls upFrontFlat * notional, so divide to get the original value
				isErr = idsa_JpmcdsCdsoneUpfrontCharge([self getStandardCoupon], quotedSpread, recovery, notional
								  , [self convertToTDate: tradeDate]		//today
								  , *valueDateTDate							//returns valueDate
								  , [self convertToTDate: startDate]
								  , [self convertToTDate: maturityDate]		//maturity
								  , [self convertToTDate: startDate ]		//benchmarkStart
								  , *stepinDateTDate						//returns stepinDate
										  
										  //params or zerocurve
								  , maturies
								  , rates
								  , [self convertToTDate: spotDate ]		//baseDate for the LiborCurve == T+2
								  , currency
								  , baddayconvention
								  , holidays
								  , moneyMarketDCC
								  , swapFixedDCC
								  , swapFloatDCC
								  , swapFloatFreq
								  , swapFixFreq
								  , types
								  , TRUE //isPriceClean
								, &cleanUpFront
						) ;
				
				if (isErr) //idsa_JpmcdsCdsoneUpfrontCharge
				{
					//show error to user
					errMsg = @"Error:calc clean price";
				}// isErr idsa_JpmcdsCdsoneUpfrontCharge
				
			}//!isErr idsa_JpmcdsCdsoneUpfrontCharge
			
			//Cleanup
			JpmcdsFreeSafe (stepinDateTDate);
			stepinDateTDate = nil;
			JpmcdsFreeSafe (valueDateTDate);
			valueDateTDate = nil;
			
			//set fields that do not require calcs
			[self setButtonText:outSettleDate title: valueDate recalc:NO];

			if (!isErr)
			{
				//calc the Numbers
				double cleanPrice			= 100.0 - cleanUpFront * 100.0;
				double cashSettlementAmount = dirtyUpFront * notional;
				double accruedPremium		= cleanUpFront * notional - cashSettlementAmount;
				double accruedDays			= accruedPremium * 360.0 / [self getStandardCoupon] * 10000.0 / notional;
				
				//this is just to check the price, as our clean price is off but our accrual is OK!
				double	temp = cleanUpFront * notional - accruedPremium;
				
				//default fee is calc from buy perspective
				if ([[BuySellCtrl titleForSegmentAtIndex:[BuySellCtrl selectedSegmentIndex]] compare:@"Buy"] == NSOrderedSame ) 
				{
					cashSettlementAmount *= -1;
				}
				
				NSString *theDate = [NSString stringWithFormat:@"%@ / %.0f", [dateCalc convertDateToString:startDate], accruedDays];
				[self setButtonText:outStartDate title: theDate recalc:NO];

				//format our output
				NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
				[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
				[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
				[numberFormatter setRoundingMode:NSNumberFormatterRoundHalfUp];
				[numberFormatter setMaximumFractionDigits:0];

				NSNumber *pnTempNumber = [NSNumber numberWithDouble:cashSettlementAmount];		
				NSString *theFee = [numberFormatter stringFromNumber:pnTempNumber];
				[self setButtonText:outUpFrontFee title: theFee recalc:NO];
				
				[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
				[numberFormatter setMaximumFractionDigits:2];
				pnTempNumber		= [NSNumber numberWithDouble:accruedPremium];		
				NSString *theAccrual = [numberFormatter stringFromNumber:pnTempNumber];
				[self setButtonText:outAccrued title: theAccrual recalc:NO];
				
				//if we are <100 we can show more decimal places to match the MarkIt screen	
				NSString *thePrice = [NSString stringWithFormat:@"%.3f", cleanPrice];				
				[self setButtonText:outPrice title: thePrice recalc:NO];

				NSString *theFeeQuote = nil;
				if (isSpreadQuoted) 
				{
					theFeeQuote = [NSString stringWithFormat:@"%.3f", 100.0 - cleanPrice];
				}	
				else
				{
						//if the user entered a fee, regurn what was provided
					theFeeQuote = [NSString stringWithFormat:@"%.3f", quotedFee];
				}
				[self setButtonText:outFeeQuote title: theFeeQuote recalc:NO];

				
				//dispaly the spread
				NSString *theSpread = [NSString stringWithFormat:@"%.2f", quotedSpread];	
				[self setButtonText:outSpread title: theSpread recalc:NO];

				//Capture debug information
				[self setDebugInfo:[NSString stringWithFormat:@"\n cashSettlementAmount: %f\n \
									cleanPrice          : %3.7f\n \
									accruedPremium      : %8.2f\n \
									temp                : %8.2f\n \
									AccruedDays         : %f\n \
									cleanUpFront        : %.7f\n \
									dirtyUpFront        : %.7f\n \
									============================================\n \
									notional            : %f\n \
									running Coupon      : %.0f\n \
									Quoted Spread       : %.2f\n \
									Recovery            : %.0f\n \
									Currency            : %s\n \
									============================================\n \
									tradeDate           : %@\n \
									valueDate           : %@\n \
									startDate           : %@\n \
									benchMarkDate       : %@\n \
									maturityDate        : %@\n \
									stepInDate          : %@\n \
									spotDate            : %@\n \
									============================================\n \
									baddayconvention    : %s\n \
									holidays            : %s\n \
									moneyMarketDCC      : %s\n \
									swapFixedDCC        : %s\n \
									swapFloatDCC        : %s\n \
									swapFloatFreq       : %s\n \
									swapFixFreq         : %s\n" 
									, cashSettlementAmount
									, cleanPrice	
									, accruedPremium	
									, temp
									, accruedDays
									, cleanUpFront
									, dirtyUpFront
									, notional
									, [self getStandardCoupon]
									, quotedSpread
									, recovery*100
									, currency
									, [dateCalc convertDateToString:tradeDate]
									, valueDate
									, [dateCalc convertDateToString:startDate]
									, [dateCalc convertDateToString:startDate] 
									, [dateCalc convertDateToString:maturityDate]
									, stepInDate
									, [dateCalc convertDateToString:spotDate]
									, [theCurve.baddayconvention UTF8String]
									, holidays
									, moneyMarketDCC
									, swapFixedDCC
									, swapFloatDCC
									, swapFloatFreq
									, swapFixFreq
									] ];

			}//!isErr - show output

		}//!isErr - calc the #
		
		
	}//if theCurve
	else 
	{
		isErr = 1;
		
			//do nothing loading libor failed, we already displayed an alert for that ;)
		errMsg = [NSString stringWithString:@"LIBOR not available"];
		
	}
	
	//show an error message in the fee window
	if (isErr) 
	{
		[self setButtonText:outUpFrontFee title: errMsg recalc:NO];
		[self setDebugInfo:errMsg];
		
		
		[self setButtonText:outAccrued title: @"-" recalc:NO];
		[self setButtonText:outPrice title: @"-"  recalc:NO];

		NSString *theDate = [NSString stringWithFormat:@"%@", [dateCalc convertDateToString:startDate]];
		[self setButtonText:outStartDate title: theDate recalc:NO];
				
		NSString *theFeeQuote = nil;
		NSString *theSpread = nil;
		if (isSpreadQuoted) 
		{
			theFeeQuote = @"-";
			
			//dispaly the spread the user provided
			theSpread = [NSString stringWithFormat:@"%.2f", quotedSpread];	
		}	
		else
		{
			theSpread = @"-";
			
			//if the user entered a fee, regurn what was provided
			theFeeQuote = [NSString stringWithFormat:@"%.3f", quotedFee];
		}		
		[self setButtonText:outFeeQuote title: theFeeQuote recalc:NO];
		[self setButtonText:outSpread title: theSpread recalc:NO];
		
	}	
}


- (IBAction)CalcFee:(id)sender 
{
	[ self ReCalculate ];
}

- (IBAction)CalcProtectionStart:(id)sender 
{
    
}

/*
- (IBAction)EnterRecovery:(id)sender 
{
	[ self ReCalculate ];
	[ RecoveryText resignFirstResponder ];
}

- (IBAction)EnterSpread:(id)sender 
{
	[ self ReCalculate ];    
	//[ sender resignFirstResponder ];
}
*/
/*
//Handle pressing done in the text fields 
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
		//close the keyboard
	[theTextField resignFirstResponder];

		//recalc the fee
	[self ReCalculate];

	return YES;
}
*/

- (IBAction)ValueChangeBuySell:(id)sender 
{
	[self ReCalculate];
}

- (IBAction)ValueChangeCurrency:(id)sender 
{
	[self ReCalculate];
}

/*
- (IBAction)ValueChangeMaturityYear:(id)sender 
{
	[ self ReCalculate ];
}
- (IBAction)ValueChangeMaturityMonth:(id)sender 
{
 [self ReCalculate];
}
*/

- (IBAction) ValueChangeMaturity: (id)sender
{
	[self calcMaturityDate];	
	[self ReCalculate];
}


- (IBAction)ValueChangeNotional:(id)sender 
{
	NSString *notional = [ NotionalCtrl titleForSegmentAtIndex: [ NotionalCtrl selectedSegmentIndex ]]  ;

	//update the button
	[NotionalText setTitle:notional forState: UIControlStateNormal];
	[NotionalText setTitle:notional forState: UIControlStateSelected];
	[NotionalText setTitle:notional forState: UIControlStateHighlighted];
	
	[self ReCalculate];
}

- (IBAction)ValueChangeRecovery:(id)sender 
{
	NSString *recovery = [ RecoveryCtrl titleForSegmentAtIndex: [ RecoveryCtrl selectedSegmentIndex ]]  ;

	//update the button
	[RecoveryText setTitle:recovery forState: UIControlStateNormal];
	[RecoveryText setTitle:recovery forState: UIControlStateSelected];
	[RecoveryText setTitle:recovery forState: UIControlStateHighlighted];
	
	[self ReCalculate];
}

- (IBAction)ValueChangeStandardCoupon:(id)sender 
{
	[self ReCalculate];
}

- (IBAction)ValueChangeTradeDate:(id)sender 
{
    
}

- (IBAction)ValueChangeTradeFeeSpread:(id)sender 
{
	[self ReCalculate];
}

- (void)viewDidAppear:(BOOL)animated
{		
	[super viewDidAppear:animated];
	dateCalc = [CreditDateRoutines alloc];
	[self ReCalculate];
}

@end
