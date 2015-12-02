//
//  iCDSAppDelegate.h
//  iCDS
//
//  Created by James Zucker on 11/14/09.
//  Copyright 2009,2010 James A Zucker. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XMLAppDelegate;
@class Reachability;

@interface iCDSAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> 
{
    UIWindow			*window;
    UITabBarController	*tabBarController;
	XMLAppDelegate		*liborXML;
	
	Reachability		*hostReach;
    Reachability		*internetReach;
    Reachability		*wifiReach;
	BOOL				networkWasDown; //alert the user if the network comes back ;)
	
}
- (void) configureTextField: (Reachability*) curReach message:(NSString *) msg;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) XMLAppDelegate *liborXML;
@property (nonatomic) BOOL networkWasDown;

@end
