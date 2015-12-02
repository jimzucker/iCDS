//
//  QuotedSpreadViewController.h
//  iCDS
//
//  Created by James Zucker on 1/24/10.
//  Copyright 2010 James A Zucker. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface QuotedSpreadViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate> {

	//recovery
	IBOutlet UIPickerView			*priceBasisPickerView;
	IBOutlet UIPickerView			*priceFeePickerView;
	IBOutlet UISegmentedControl		*FeeBasisCtrl;
	
	NSArray		*pricePickerArray;		//integers 1..9
	NSString	*currentValue;			//stores the current selection
	UIViewController *parentViewController;	//parent we send the price to
	
}

- (IBAction)ChangeFeeBasis:(id)sender;
- (void) showActionSheet:(UIView *)theView isSpread:(BOOL)isSpread spread:(NSString *)currentSpread fee:(NSString *)currentFee 
		parentViewController:(UIViewController *)parentViewController;
- (void) setValue:(BOOL)isSpread spread:(NSString *)currentSpread fee:(NSString *)currentFee;
- (NSString *) getCurrentQuote;


@property (nonatomic, retain) IBOutlet UIPickerView			*priceBasisPickerView;
@property (nonatomic, retain) IBOutlet UIPickerView			*priceFeePickerView;
@property (nonatomic, retain) IBOutlet UISegmentedControl	*FeeBasisCtrl;
@property (nonatomic, retain) NSArray						*pricePickerArray;
@property (nonatomic, retain) NSString						*currentValue;
@property (nonatomic, assign) UIViewController *parentViewController;

@end
