//
//  MarkItCalcController.h
//
//  Created by James Zucker on 11/15/09.
//  Copyright 2009,2010 James A Zucker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class CreditDateRoutines;
@class LiborCurve;

//@interface MarkItCalcController : NSObject <UIViewController>
@interface MarkItCalcController : UIViewController
{
    IBOutlet UISegmentedControl	*BuySellCtrl			;
    IBOutlet UIButton			*CurrencyCtrl			;
    IBOutlet UISegmentedControl	*PriceCtrl				;
    IBOutlet UIButton			*PriceText				;
	IBOutlet UISegmentedControl	*MaturityCtrl			;
    IBOutlet UIButton			*MaturityText			;
    IBOutlet UISegmentedControl	*NotionalCtrl			;
    IBOutlet UIButton			*NotionalText			;
    IBOutlet UISegmentedControl	*RecoveryCtrl			;
    IBOutlet UIButton			*RecoveryText			;
    IBOutlet UISegmentedControl	*StandardCouponCtrl		;
    IBOutlet UITextView			*LiborCurve				;
    IBOutlet UIButton			*outAccrued				;
    IBOutlet UIButton			*outPrice				;
    IBOutlet UIButton			*outFeeQuote			;
    IBOutlet UIButton			*outSpread				;
    IBOutlet UIButton			*outTradeDate			;
    IBOutlet UIButton			*outSettleDate			;
    IBOutlet UIButton			*outStartDate			;
    IBOutlet UIButton			*outUpFrontFee			;
	
		//date calculator
	CreditDateRoutines			*dateCalc				;
	NSString					*debugInfo				;
}

- (IBAction)ReCalculate;
- (double)getStandardCoupon ;
//- (NSDate *) bumpDate:(NSDate *)theDate days:(int)nDays months:(int)nMonths years:(int)nYears;
- (void)setButtonText:(UIButton *)theButton title: (NSString *)theTitle recalc: (BOOL) doRecalc;


- (IBAction)CalcFee:(id)sender;
- (IBAction)CalcProtectionStart:(id)sender;
//- (IBAction)EnterRecovery:(id)sender;
//- (IBAction)EnterSpread:(id)sender;
//- (IBAction)EnterNotional:(id)sender;
- (IBAction)ValueChangeBuySell:(id)sender;
- (IBAction)ValueChangeCurrency:(id)sender;
//- (IBAction)ValueChangeMaturityMonth:(id)sender;
//- (IBAction)ValueChangeMaturityYear:(id)sender;
- (IBAction)ValueChangeMaturity:(id)sender;
- (IBAction)ValueChangeNotional:(id)sender;
- (IBAction)ValueChangeRecovery:(id)sender;
- (IBAction)ValueChangeStandardCoupon:(id)sender;
- (IBAction)ValueChangeTradeFeeSpread:(id)sender;

//- (NSDate *) getTradeDate;

- (NSString *) getCurrency;
- (LiborCurve *) getLiborCurve;
- (BOOL) setLiborCurve: (NSString *)currency valueDate:(NSDate *)theDate;
- (void) setTradeDate: (NSDate*)tradeDate;
- (NSDate *) getTradeDate;

@property (retain) NSString *debugInfo;

@end
