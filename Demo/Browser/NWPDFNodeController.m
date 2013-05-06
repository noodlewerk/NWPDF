//
//  NWPDFNodeController.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFNodeController.h"
#import "NWPDFNodeDetailController.h"
#import "NWPDF.h"


@implementation NWPDFNodeController {
    NSArray *nodes;
}

- (id)initWithNodes:(NSArray *)_nodes
{
    self = [super init];
    if (self) {
        nodes = _nodes;
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return nodes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NWPDFNode *node = [nodes objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@",node.key, node.value];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NWPDFNode *node = [nodes objectAtIndex:indexPath.row];
    if(node.childrenCount){
        NWPDFNodeController *detailViewController = [[NWPDFNodeController alloc] initWithNodes:node.children];
        [self.navigationController pushViewController:detailViewController animated:YES];
    } else {
        NWPDFNodeDetailController *detailViewController = [[NWPDFNodeDetailController alloc] initWithText:node.value];
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
}

@end
