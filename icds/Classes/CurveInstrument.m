//
//  CurveInstrument.m
//  XML
//
//  Created by James Zucker on 11/30/09.
//  Copyright 2009, 2010 James A Zucker. All rights reserved.
//

#import "CurveInstrument.h"


@implementation CurveInstrument

@synthesize	instrument, tenor, maturitydate, parrate;

- (void) dealloc {
	
	[instrument release];
	[tenor release];
	[maturitydate release];
	[parrate release];
	[super dealloc];
}

@end
