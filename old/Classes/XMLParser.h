//
//  XMLParser.h
//  XML
//
//  Created by James Zucker on 11/30/09.
//  Copyright 2009, 2010 James A Zucker. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XMLAppDelegate, LiborCurve, CurveInstrument;

@interface XMLParser : NSObject 
{

	NSMutableString *currentElementValue;

	//fields used for an instrument
	NSString	*instrument;
/*
 NSString	*daycountconvention;
	NSString	*snaptime;
	NSString	*spotdate;
	NSString	*fixeddaycountconvention;
	NSString	*floatingdaycountconvention;
	NSString	*fixedpaymentfrequency;
	NSString	*floatingpaymentfrequency;
	NSString	*types;
	NSMutableArray	*theTenors_;
 */
	
//	LiborViewController	*appDelegate_;
	XMLAppDelegate	*appDelegate_;
	LiborCurve		*theLiborCurve_;
	CurveInstrument *theCurveInstrument_;
	NSObject		*theCurrentObject_;
}

- (XMLParser *) initXMLParser:(XMLAppDelegate *)theDelegate;

@property (nonatomic, retain) NSString	*instrument;
/*
@property (nonatomic, retain) NSString	*daycountconvention;
@property (nonatomic, retain) NSString	*snaptime;
@property (nonatomic, retain) NSString	*spotdate;
@property (nonatomic, retain) NSString	*fixeddaycountconvention;
@property (nonatomic, retain) NSString	*floatingdaycountconvention;
@property (nonatomic, retain) NSString	*fixedpaymentfrequency;
@property (nonatomic, retain) NSString	*floatingpaymentfrequency;
@property (nonatomic, retain) NSString	*types;
*/

@end
