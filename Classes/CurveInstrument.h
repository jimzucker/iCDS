//
//  CurvePoint.h
//  XML
//
//  Created by James Zucker on 11/30/09.
//  Copyright 2009, 2010 James A Zucker. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CurveInstrument : NSObject 
{
	NSString	*instrument;
	NSString	*tenor;
	NSString	*maturitydate;
	NSString	*parrate;

}


@property (nonatomic, retain) NSString	*instrument;
@property (nonatomic, retain) NSString	*tenor;
@property (nonatomic, retain) NSString	*maturitydate;
@property (nonatomic, retain) NSString	*parrate;


@end


