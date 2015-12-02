//
//  iCDSAppDelegate.m
//  iCDS
//
//  Created by James Zucker on 11/14/09.
//  Copyright 2009,2010 James A Zucker. All rights reserved.
//

#import "iCDSAppDelegate.h"
#import "XMLAppDelegate.h"

#import "Reachability.h"

@implementation iCDSAppDelegate

@synthesize window, tabBarController, liborXML, networkWasDown;

- (void) updateInterfaceWithReachability: (Reachability*) curReach
{
    if(curReach == hostReach)
	{
		//[self configureTextField: remoteHostStatusField imageView: remoteHostIcon reachability: curReach];
		[self configureTextField: curReach message: @"Cannot access wwww.markit.com\nYou will not be able to retrieve new LIBOR curves."];
        NetworkStatus netStatus = [curReach currentReachabilityStatus];
        BOOL connectionRequired= [curReach connectionRequired];
		
//        summaryLabel.hidden = (netStatus != ReachableViaWWAN);
        NSString* baseLabel=  @"";
        if(connectionRequired)
        {
            baseLabel=  @"Cellular data network is available.\n  Internet traffic will be routed through it after a connection is established.";
        }
        else
        {
            baseLabel=  @"Cellular data network is active.\n  Internet traffic will be routed through it.";
        }
//        summaryLabel.text= baseLabel;
    }
	if(curReach == internetReach)
	{	
		//[self configureTextField: internetConnectionStatusField imageView: internetConnectionIcon reachability: curReach];
		[self configureTextField: curReach message: @"Cannot access the Internet"];
	}
	if(curReach == wifiReach)
	{	
//		[self configureTextField: localWiFiConnectionStatusField imageView: localWiFiConnectionIcon reachability: curReach];
		[self configureTextField: curReach message: @"Cannot access WiFi"];
	}
	
}

//- (void) configureTextField: (UITextField*) textField imageView: (UIImageView*) imageView reachability: (Reachability*) curReach
- (void) configureTextField: (Reachability*) curReach message:(NSString *) msg
{
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    BOOL connectionRequired= [curReach connectionRequired];
    NSString* statusString= @"";
    switch (netStatus)
    {
        case NotReachable:
        {
            statusString = @"Access Not Available";
         //   imageView.image = [UIImage imageNamed: @"stop-32.png"] ;
            //Minor interface detail- connectionRequired may return yes, even when the host is unreachable.  We cover that up here...
            connectionRequired= NO;  
			
			//remember the network was down
			networkWasDown=YES;
			
				//display an alert
			UIAlertView *errorAlert = [[UIAlertView alloc]
									   initWithTitle:@"Network Error"
									   message: msg
									   delegate:self
									   cancelButtonTitle:@"Continue"
									   otherButtonTitles:nil];
			[errorAlert show];
			[errorAlert release];
            break;
        }
            
        case ReachableViaWWAN:
        {
            statusString = @"Reachable WWAN";
       //     imageView.image = [UIImage imageNamed: @"WWAN5.png"];
			
			if (networkWasDown) {
				//display an alert
				UIAlertView *errorAlert = [[UIAlertView alloc]
										   initWithTitle:@"Network Re-connected"
										   message: @"Markit.com is now accessible for LIBOR Curves"
										   delegate:self
										   cancelButtonTitle:@"Continue"
										   otherButtonTitles:nil];
				[errorAlert show];
				[errorAlert release];
				
			}
			
			networkWasDown=NO;

            break;
        }
        case ReachableViaWiFi:
        {
			statusString= @"Reachable WiFi";
     //       imageView.image = [UIImage imageNamed: @"Airport.png"];
			
			if (networkWasDown) {
				//display an alert
				UIAlertView *errorAlert = [[UIAlertView alloc]
										   initWithTitle:@"Network Re-connected"
										   message: @"Markit.com is now accessible for LIBOR Curves"
										   delegate:self
										   cancelButtonTitle:@"Continue"
										   otherButtonTitles:nil];
				[errorAlert show];
				[errorAlert release];
				
			}
			
			networkWasDown=NO;
            break;
		}
    }
    if(connectionRequired)
    {
        statusString= [NSString stringWithFormat: @"%@, Connection Required", statusString];
    }
   // NSLog(@"Reachability Status= %@",statusString);
}


//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateInterfaceWithReachability: curReach];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application 
{
	networkWasDown=NO;
	
	// Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
    // method "reachabilityChanged" will be called. 
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
	
    //Change the host name here to change the server your monitoring
	hostReach = [[Reachability reachabilityWithHostName: @"www.markit.com"] retain];
	[hostReach startNotifer];

	/*	
    internetReach = [[Reachability reachabilityForInternetConnection] retain];
	[internetReach startNotifer];
	
    wifiReach = [[Reachability reachabilityForLocalWiFi] retain];
	[wifiReach startNotifer];
	 */
	
	liborXML = [XMLAppDelegate alloc];
	//[liborXML loadXML:@"USD"];
	
    // Add the tab bar controller's current view as a subview of the window
    [window addSubview:tabBarController.view];
    window.rootViewController = tabBarController;
    
}


/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
}
*/

/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}
*/


- (void)dealloc {
    [tabBarController release];
    [window release];
	[liborXML release];
    [super dealloc];
}

@end

