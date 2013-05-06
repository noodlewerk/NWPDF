//
//  NWPDFMenuTableViewController.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFMenuTableViewController.h"
#import "NWPDFPageContainerViewController.h"
#import "NWPDFNodeController.h"
#import "NWPDFCacherController.h"
#import "NWPDF.h"
#import "NWPDFScrollViewController.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NWPDFMenuTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
#ifdef DEBUG
//    [self selectController:1 animated:NO];
#endif
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"PDF PageViewController";
            break;
        case 1:
            cell.textLabel.text = @"PDF ScrollViewController";
            break;
        case 2:
            cell.textLabel.text = @"PDF NodeController";
            break;
        case 3:
            cell.textLabel.text = @"PDF CacherController";
            break;
        default:
            break;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)selectController:(NSInteger)index animated:(BOOL)animated
{
    NSURL *documentURL = [[NSBundle mainBundle] URLForResource:@"demo" withExtension:@"pdf"];
    NWPDFDocument *document = [[NWPDFDocument alloc] initWithURL:documentURL];
    
    UIViewController* vc = nil;
    
    switch (index) {
        case 0:
            vc = [[NWPDFPageContainerViewController alloc] initWithDocument:document];
            break;
        case 1:{
            vc = [[NWPDFScrollViewController alloc] initWithDocument:document cacheName:documentURL.lastPathComponent pageIndex:0];
            break;
        }
        case 2:{
            NWPDFDocumentNode *root = [[NWPDFDocumentNode alloc] initWithDocument:document];
            vc = [[NWPDFNodeController alloc] initWithNodes:root.children];   
            break;
        }
        case 3:{
            vc = [[NWPDFCacherController alloc] initWithDocument:document];   
            break;
        }
        default:
            break;
    }
    
    [self.navigationController pushViewController:vc animated:animated];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectController:indexPath.row animated:YES];
}

@end
