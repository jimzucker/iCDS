//
//  SNACViewController.h
//  iCDS
//
//  Created by James Zucker on 11/14/09.
//  Copyright 2009, 2010 James A Zucker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MarkitCalcController.h"

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@class QuotedSpreadViewController;

@interface SNACViewController : MarkItCalcController <MFMailComposeViewControllerDelegate,UIActionSheetDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>
{	
	//currency
	UIPickerView	*currencyPickerView;
	NSArray			*currencyViewArray;
	
	//maturity date
	UIPickerView	*maturityPickerView;
	NSArray			*maturityMonthViewArray;
	NSMutableArray	*maturityYearViewArray;
	
	//Notional
	UIPickerView	*notionalPickerView;
	NSArray			*notionalPickerArray;			//integers 1..9

	//recovery
	UIPickerView	*recoveryPickerView;
	NSArray			*recoveryPickerArray;			//integers 1..9

	//recovery
//	UIPickerView	*pricePickerView;
	QuotedSpreadViewController *pricePickerView;
	
	NSArray			*pricePickerArray;		//integers 1..9
	
	//TradeDate
	UIDatePicker	*tradeDatePickerView;

	//The picker we are currently using
	UIView			*currentPicker;

}
- (IBAction)dialogCurrencyPicker:(id)sender ;
- (IBAction)dialogMaturityPicker:(id)sender ;
- (IBAction)dialogNotionalPicker:(id)sender ;
- (IBAction)dialogRecoveryPicker:(id)sender ;
- (IBAction)dialogPricePicker:(id)sender	;
- (IBAction)dialogTradeDatePicker:(id)sender;
- (IBAction)debugInfoAlert:(id)sender;
- (IBAction)email:(id)sender;

- (void)setPriceTextButton:(NSString *)theTitle;

//Currency Picker
@property (nonatomic, retain) UIPickerView *currencyPickerView;
@property (nonatomic, retain) NSArray *currencyViewArray;


@property (nonatomic, retain) UIView *currentPicker;

@end
