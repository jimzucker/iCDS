//
//  LiborCurve.h
//  XML
//
//  Created by James Zucker on 11/30/09.
//  Copyright 2009, 2010 James A Zucker. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CreditDateRoutines;

@interface LiborCurve : NSObject 
{
	NSString *effectiveasof;
	NSString *currency;
	NSString *baddayconvention;
	NSString *holidays		;

	NSString *daycountconvention;
	NSString *snaptime;
	NSString *spotdate;
	NSString *fixeddaycountconvention;
	NSString *floatingdaycountconvention;
	NSString *fixedpaymentfrequency;
	NSString *floatingpaymentfrequency;
	NSString *types;
	
	NSMutableArray	*theTenors_;
	
	char **maturityArray_;
	double *parratesArray_;
	CreditDateRoutines *dateRoutines;
}

-(char **) getTenors;
-(double *) getParRates;
-(int) numTenors;
-(NSDate *) getSpotDate;
-(CreditDateRoutines *) getDateRoutines;

@property (nonatomic, retain) NSString *effectiveasof;
@property (nonatomic, retain) NSString *currency;
@property (nonatomic, retain) NSString *baddayconvention;
@property (nonatomic, retain) NSString *holidays		;
@property (nonatomic, retain) NSString *daycountconvention;
@property (nonatomic, retain) NSString *snaptime;
@property (nonatomic, retain) NSString *spotdate;
@property (nonatomic, retain) NSString *fixeddaycountconvention;
@property (nonatomic, retain) NSString *floatingdaycountconvention;
@property (nonatomic, retain) NSString *fixedpaymentfrequency;
@property (nonatomic, retain) NSString *floatingpaymentfrequency;
@property (nonatomic, retain) NSString *types;
@property (nonatomic, retain) NSMutableArray *theTenors_;


@end
