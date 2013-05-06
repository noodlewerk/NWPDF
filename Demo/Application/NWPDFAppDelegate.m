//
//  NWPDFAppDelegate.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFAppDelegate.h"
#import "NWPDFMenuTableViewController.h"
#import <CoreData/CoreData.h>
#import <NWLogging/NWLCore.h>


@implementation NWPDFAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Logging
    NWLPrintInfo();  
    NWLBreakWarn();
//    NWLPrintDbugInFile("NWPDFCacheMonitor.m");
//    NWLPrintDbugInFile("NWPDFCache.m");
//    NWLPrintDbugInFile("NWPDFPagePrefetcher.m");
//    NWLPrintDbugInFile("NWPDFThumbPrefetcher.m");
//    NWLPrintDbugInFile("NWPDFDocumentScrollView.m");
    NWLogInfo(@"Application did finish launching");
    NWLogInfo(@"Bundle: %@", [NSBundle.mainBundle.infoDictionary valueForKey:@"CFBundleIdentifier"]);
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    NWPDFMenuTableViewController* vc = [[NWPDFMenuTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = self.navigationController;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
