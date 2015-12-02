//
//  AppInfoViewControler.h
//  iCDS
//
//  Created by James Zucker on 1/27/10.
//  Copyright James A. Zucker 2009, 2010. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AppInfoViewControler : UIViewController {
	IBOutlet UIWebView *aboutBox;
}

@property (nonatomic,retain) 	IBOutlet UIWebView *aboutBox;
@end
