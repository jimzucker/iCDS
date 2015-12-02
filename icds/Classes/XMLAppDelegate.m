//
//  XMLAppDelegate.m
//  XML
//
//  Created by James Zucker on 11/14/09.
//  Copyright James A. Zucker 2009, 2010. All rights reserved.
//

#import "XMLAppDelegate.h"
#import "LiborViewController.h"
#import "XMLParser.h"
#import "MarkItCalcController.h"
#import "CreditDateRoutines.h"

//include the goolge ZipArchive
#import "ZipArchive.h"

@implementation XMLAppDelegate

@synthesize liborCurve_;

- (BOOL)loadXML:(NSString *) theCurrency tradeDate:(NSDate *)tradeDate
{
	
	BOOL resultSucess = YES;
//	[activityIndicator startAnimating];
	
	CreditDateRoutines *dateRoutines = [[CreditDateRoutines alloc] autorelease];
	NSDate *TMinus1 = [dateRoutines moveToValidBusinessDate:[dateRoutines bumpDate:tradeDate days:-1 months:0 years:0] rollForward:FALSE];

	NSString *fileName = [[[[NSString stringWithString:@"InterestRates_"] stringByAppendingString:theCurrency]  
				stringByAppendingString:@"_"] stringByAppendingString:[dateRoutines yyyymmdd:TMinus1]
				];
		  
		//get the Data from the URL
	NSURL *url = [[NSURL alloc] initWithString:[[@"https://www.markit.com/news/" stringByAppendingString:fileName] stringByAppendingString: @".zip"]];
	NSError *theErr;
	NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&theErr];
	if (data) 
	{
		
		NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];		
		[data writeToFile:path atomically:YES];
		
		NSString *destPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@""];
		ZipArchive* za = [[ZipArchive alloc] init];
		if( [za UnzipOpenFile:path] )
		{
			resultSucess = [za UnzipFileTo:destPath overWrite:YES];
			[za UnzipCloseFile];
		}
		else 
		{
			resultSucess = NO;
		}
		[za release];
		
		if (resultSucess == YES)
		{
			NSData *xmlData = [NSData dataWithContentsOfFile: 
							   [[destPath stringByAppendingPathComponent: fileName] stringByAppendingString:@".xml"]];
			
			NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
			
			//Initialize the delegate.
			XMLParser *parser = [[XMLParser alloc] initXMLParser:self];
			
			//Set delegate
			[xmlParser setDelegate:parser];
			
			//Start parsing the XML file.
			resultSucess = [xmlParser parse];
			if(resultSucess == NO)
			{
				UIAlertView *errorAlert = [[UIAlertView alloc]
										   initWithTitle:@"Could not retrieve Libor Curve from markit.com"
										   message: fileName
										   delegate:self
										   cancelButtonTitle:@"OK"
										   otherButtonTitles:nil];
				
				
				[errorAlert show];
				[errorAlert release];
			}
			[parser release];
			
				//cleanup the files
			NSFileManager *theFileManager = [[NSFileManager alloc] autorelease];
			[theFileManager removeItemAtPath:[[destPath stringByAppendingPathComponent: fileName] stringByAppendingString:@".xml"] error:nil];
			[theFileManager removeItemAtPath:[destPath stringByAppendingPathComponent: @"Disclaimer.txt"] error:nil];
		}//resultSucess
	}
	else 
	{
		resultSucess = NO;		
		/*
		UIAlertView *errorAlert = [[UIAlertView alloc]
								   initWithTitle:@"Could not retrieve Libor Curve from markit.com"
								   message: [theErr localizedDescription]
								   delegate:self
								   cancelButtonTitle:@"OK"
								   otherButtonTitles:nil];
		[errorAlert show];
		[errorAlert release];
		 */
	}//if data
	
	//clean-up
	[url release];
	
		//return the sucess status
	return resultSucess;
}

- (void)dealloc 
{
	[liborCurve_ release];
	[super dealloc];
}

@end
