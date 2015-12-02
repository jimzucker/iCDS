//
//  LiborCurve.m
//  XML
//
//  Created by James Zucker on 11/30/09.
//  Copyright 2009, 2010 James A Zucker. All rights reserved.
//

#import "LiborCurve.h"
#import "CurveInstrument.h"
#import "CreditDateRoutines.h"

@implementation LiborCurve

@synthesize effectiveasof, currency, baddayconvention, holidays, daycountconvention, snaptime, spotdate
, fixeddaycountconvention, floatingdaycountconvention, fixedpaymentfrequency, floatingpaymentfrequency, types, theTenors_;


/*
 
TCurve *zerocurve = BuildZeroCurve(maturities,rates,spotDate, today
								   , (char *)currency
								   , baddayconvention			
								   , holidays			
								   , moneyMarketDCC			
								   , swapFixedDCC
								   , swapFloatDCC
								   , swapFloatFreq
								   , swapFixFreq
								   , types
								   , NULL
								   );

 

*/

-(CreditDateRoutines *) getDateRoutines
{
	if (!dateRoutines) 
	{
		dateRoutines = [CreditDateRoutines alloc];
	}
	return dateRoutines;
}

-(char **) getTenors
{
	if (maturityArray_ == NULL)
	{
			//allocate the array
		maturityArray_ = (char **) calloc([self numTenors], sizeof(char *));	
		//memset(maturityArray_, 0, sizeof(char *) * [self numTenors]);
		
			//populate the array
		NSEnumerator *e = [theTenors_ objectEnumerator];
		CurveInstrument *instrument;

		int i=0;
		while (instrument = (CurveInstrument *) [e nextObject]) 
		{
			// copy the pointer as the UTF8String is autoreleased
			const char *tmpMaturity = (char *)[instrument.tenor UTF8String];
			char *copyMaturity		= malloc(strlen(tmpMaturity)+1);
			strcpy(copyMaturity, tmpMaturity);
			maturityArray_[i++] = copyMaturity;
		}
	}
	
		//return the array
	return maturityArray_;
}

-(NSDate *) getSpotDate
{
	//The format of the date from MarkIt is yyyy-mm-dd
	NSArray *listItems = [spotdate componentsSeparatedByString:@"-"];
	int year = [[listItems objectAtIndex:0] intValue];
	int month = [[listItems objectAtIndex:1] intValue];
	int day = [[listItems objectAtIndex:2] intValue];

	return [[self getDateRoutines] getDateFromComponents:year month: month day: day];
}

-(double *) getParRates
{
	if (parratesArray_ == NULL)
	{
		//allocate the array
		parratesArray_ = calloc([self numTenors], sizeof(double));	
		
		//populate the array
		NSEnumerator *e = [theTenors_ objectEnumerator];
		CurveInstrument *instrument;
		
		int i=0;
		while (instrument = (CurveInstrument *) [e nextObject]) 
		{
			// do something with object
			parratesArray_[i++] = (double) [instrument.parrate floatValue];
		}
	}
	//return the array
	return parratesArray_;
}

-(int) numTenors
{
	return [types length];
}

- (void) dealloc {
	[dateRoutines release];
	[effectiveasof release];
	[currency release];
	[baddayconvention release];
	[holidays release];
	[daycountconvention release];
	[snaptime release];
	[spotdate release];
	[fixeddaycountconvention release];
	[floatingdaycountconvention release];
	[fixedpaymentfrequency release];
	[floatingpaymentfrequency release];
	[types release];
	[theTenors_ release];

	if (parratesArray_) 
	{
		free(parratesArray_);
	}
	if (maturityArray_) 
	{
		int numMaturities = sizeof(maturityArray_)/sizeof(char*);
		for (int i=0; i<numMaturities; i++) 
		{
			if (maturityArray_[i]) 
			{
				free(maturityArray_[i]);
			}
		}
		free(maturityArray_);
	}
	
	[super dealloc];
}

@end
