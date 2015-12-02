//
//  XMLParser.m
//  XML
//
//  Created by James Zucker on 11/30/09.
//  Copyright 2009, 2010 James A Zucker. All rights reserved.
//

#import "XMLParser.h"
#import "XMLAppDelegate.h"
#import "CurveInstrument.h"
#import "LiborCurve.h"
#import "LiborViewController.h"

@implementation XMLParser

@synthesize	instrument ;
/*, daycountconvention, snaptime, spotdate
	, fixeddaycountconvention, floatingdaycountconvention
	, fixedpaymentfrequency, floatingpaymentfrequency;

*/

- (XMLParser *) initXMLParser: (XMLAppDelegate *)theDelegate 
{
	
	[super init];
	
	//appDelegate = (XMLAppDelegate *)[[UIApplication sharedApplication] delegate];
	appDelegate_ = theDelegate;
	
	return self;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {
	
	if([elementName isEqualToString:@"interestRateCurve"]) 
	{
		//Initialize the instrument.
		theLiborCurve_	= [[LiborCurve alloc] init];

		//Initialize the array.
		theLiborCurve_.theTenors_ = [[NSMutableArray alloc] init];
				
		//SNAC always uses no holidays
		theLiborCurve_.holidays = @"none";
		theLiborCurve_.types = @"";

			//remember the current object
		theCurrentObject_ = theLiborCurve_;
	}
	else if([elementName isEqualToString:@"curvepoint"]) 
	{
		
		//Initialize the instrument.
		theCurveInstrument_= [[CurveInstrument alloc] init];
			
		theCurveInstrument_.instrument			= instrument;

		//remeber the current Object
		theCurrentObject_ = theCurveInstrument_;
		
		//the libor curve builder needs a string telling it the isrument list of M or S
		if ([instrument isEqualToString:@"deposits"]) 
		{
			theLiborCurve_.types = [theLiborCurve_.types stringByAppendingString: @"M" ];
		}
		else 
		{
			theLiborCurve_.types = [theLiborCurve_.types stringByAppendingString: @"S" ];
		}		
	}
	else if([elementName isEqualToString:@"deposits"] || [elementName isEqualToString:@"swaps"]) 
	{
			//remember the name of the instrument
		instrument = elementName;
		theCurrentObject_ = self;
	}
	//else ignore start, it is the member of an object we already created
	
//	NSLog(@"Processing Element: %@", elementName);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string { 
	
	if(!currentElementValue)
	{
		currentElementValue = [[NSMutableString alloc] initWithString:string];
		//NSLog(@"Processing Value: %@", currentElementValue);
	}
	else
	{
		[currentElementValue appendString:string];
		//NSLog(@"Processing Value2: %@", currentElementValue);
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {

		//we can ingore the calendars as they are always NONE for SNAC
	if([elementName isEqualToString:@"calendar"] 
	   || [elementName isEqualToString:@"calendars"] 
	   || [elementName isEqualToString:@"swaps"] 
	   || [elementName isEqualToString:@"deposits"]
	   ) 
	{
		//do nothing!
	}
	else if ([elementName isEqualToString:@"interestRateCurve"])
	{		
		//save the curve information
		//appDelegate_.tenors_		= theTenors_;
		appDelegate_.liborCurve_	= theLiborCurve_;
	
	}
	else if([elementName isEqualToString:@"curvepoint"]) 
	{
		//If we encounter the curvepoint element howevere, we want to add the book object to the array
		// and release the object.	
		[theLiborCurve_.theTenors_ addObject:theCurveInstrument_];
		[theCurveInstrument_ release];
		theCurveInstrument_ = nil;
	}
	else if([instrument isEqualToString:@"deposits"] || [instrument isEqualToString:@"swaps"]) 
	{
		if([elementName isEqualToString:@"snaptime"]
		   || [elementName isEqualToString:@"spotdate"]
		   || [elementName isEqualToString:@"daycountconvention"]
		   || [elementName isEqualToString:@"fixeddaycountconvention"]
		   || [elementName isEqualToString:@"floatingdaycountconvention"]
		   || [elementName isEqualToString:@"fixedpaymentfrequency"]
		   || [elementName isEqualToString:@"floatingpaymentfrequency"]
		   )
		{	
			[theLiborCurve_ setValue:currentElementValue forKey:elementName];
		}
		else 
		{
			//otherwise populate the field on the current object, we have 4 types
			//interestRateCurve, curvepoint, deposits, swaps
			[theCurrentObject_ setValue:currentElementValue forKey:elementName];
		}
	}
	else 
	{
		//otherwise populate the field on the current object, we have 4 types
		//interestRateCurve, curvepoint, deposits, swaps
		[theCurrentObject_ setValue:currentElementValue forKey:elementName];
	}
	
	[currentElementValue release];
	currentElementValue = nil;
}

- (void) dealloc 
{
	theCurrentObject_=nil;
//	[theLiborCurve_ release];
	[theCurveInstrument_ release];
	[currentElementValue release];
	[super dealloc];
}

@end
