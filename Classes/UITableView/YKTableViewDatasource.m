//
//  YKTableViewDataSource.m
//  YelpKit
//
//  Created by Gabriel Handford on 5/13/12.
//  Copyright (c) 2012 Yelp. All rights reserved.
//

#import "YKTableViewDataSource.h"

@implementation YKTableViewDataSource

- (id)init {
  if ((self = [super init])) {
    _sectionCount = 1;
  }
  return self;
}

- (id)initWithSectionCount:(NSInteger)sectionCount {
  NSParameterAssert(sectionCount > 0);
  if ((self = [self init])) {
    _sectionCount = sectionCount;
  }
  return self;
}

- (void)dealloc {
  [_cellDataSourceSections release];
  [_sectionHeaderTitles release];
  [_sectionHeaderViews release];
  [_sectionFooterViews release];
  [super dealloc];
}

+ (YKTableViewDataSource *)dataSource {
  return [[[self alloc] init] autorelease];
}

+ (YKTableViewDataSource *)dataSourceWithCellDataSources:(NSArray */*of id<YKTableViewCellDataSource>*/)cellDataSources {
  YKTableViewDataSource *dataSource = [self dataSource];
  [dataSource addCellDataSources:cellDataSources section:0 indexPaths:nil];
  return dataSource;
}

- (void)clearAll {
  [_cellDataSourceSections release];
  _cellDataSourceSections = nil;
}

- (void)clearHeaders {
  [_sectionHeaderTitles release];
  _sectionHeaderTitles = nil;
  [_sectionHeaderViews release];
  _sectionHeaderViews = nil;
}

- (NSMutableArray *)dataSourceForSection:(NSInteger)section create:(BOOL)create {
  if (!_cellDataSourceSections && create) _cellDataSourceSections = [[NSMutableDictionary alloc] init];
  
  NSMutableArray *dataSource = [_cellDataSourceSections objectForKey:[NSNumber numberWithInteger:section]];
  if (create && !dataSource) {
    dataSource = [NSMutableArray array];
    [_cellDataSourceSections setObject:dataSource forKey:[NSNumber numberWithInteger:section]];
  }
  return dataSource;
}

- (NSMutableArray *)cellDataSourcesForSection:(NSInteger)section {
  return [_cellDataSourceSections objectForKey:[NSNumber numberWithInteger:section]];
}

- (NSMutableArray *)dataSourceForSection:(NSInteger)section {
  return [self dataSourceForSection:section create:NO];
}

- (NSInteger)countForSection:(NSInteger)section {
  return [[self dataSourceForSection:section] count];
}

- (id<YKTableViewCellDataSource>)cellDataSourceAtIndexPath:(NSIndexPath *)indexPath {
  NSMutableArray *dataSource = [self dataSourceForSection:indexPath.section];
  if (dataSource && indexPath.row < [dataSource count])
    return [dataSource objectAtIndex:indexPath.row];
  return nil;
}

- (NSIndexPath *)indexPathForCellDataSource:(id<YKTableViewCellDataSource>)cellDataSource {
  for (NSInteger section = 0; section < _sectionCount; section++) {
    NSArray *cellDataSources = [self dataSourceForSection:section create:NO];
    NSInteger row = 0;
    for (id cellDataSourceCheck in cellDataSources) {
      if ([cellDataSource isEqual:cellDataSourceCheck]) return [NSIndexPath indexPathForRow:row inSection:section];
      row++;
    }
  }
  return nil;
}

- (BOOL)removeCellDataSourceAtIndexPath:(NSIndexPath *)indexPath {
  if (!indexPath) {
    return NO;
  }
  return [self removeCellDataSourceForRow:indexPath.row inSection:indexPath.section];
}

- (BOOL)removeCellDataSourceForRow:(NSInteger)row inSection:(NSInteger)section {
  NSMutableArray *dataSource = [self dataSourceForSection:section];
  if (row < [dataSource count]) {
    [dataSource removeObjectAtIndex:row];
    return YES;
  }
  return NO;
}

- (void)removeCellDataSourceAtIndexPaths:(NSArray *)indexPaths {
  for (NSIndexPath *indexPath in indexPaths) {
    [self removeCellDataSourceForRow:indexPath.row inSection:indexPath.section];
  }
}

- (UITableViewCell *)cellForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
  id<YKTableViewCellDataSource> cellDataSource = [self cellDataSourceAtIndexPath:indexPath];
  UITableViewCell *cell = [cellDataSource cellForTableView:tableView rowAtIndexPath:indexPath];
  return cell;
}

- (NSEnumerator *)enumeratorForCellDataSources {
  return [[[YKTableViewDataSourceEnumerator alloc] initWithDataSource:self] autorelease];
}

- (void)insertCellDataSources:(NSArray */*of id<YKTableViewCellDataSource>*/)array section:(NSInteger)section atIndex:(NSInteger)index indexPaths:(NSMutableArray **)indexPaths { 
  NSMutableArray *dataSource = [self dataSourceForSection:section create:YES];
  
  NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
  for(NSInteger i = 0; i < [array count]; i++) {
    [indexes addIndex:(i + index)];
    if (indexPaths) [*indexPaths addObject:[NSIndexPath indexPathForRow:(i + index) inSection:section]];
  }
  
  [dataSource insertObjects:array atIndexes:indexes];
  if (section >= _sectionCount) _sectionCount = section + 1;
}

- (void)insertCellDataSource:(id<YKTableViewCellDataSource>)cellDataSource atIndexPath:(NSIndexPath *)indexPath {
  NSMutableArray *dataSource = [self dataSourceForSection:indexPath.section create:YES];
  [dataSource insertObject:cellDataSource atIndex:indexPath.row];
}

- (NSIndexPath *)addCellDataSource:(id<YKTableViewCellDataSource>)cellDataSource section:(NSInteger)section {
  NSMutableArray *dataSource = [self dataSourceForSection:section create:YES];
  NSInteger previousCount = [dataSource count];
  [dataSource addObject:cellDataSource];
  if (section >= _sectionCount) _sectionCount = section + 1;
  return [NSIndexPath indexPathForRow:previousCount inSection:section];
}

- (void)addCellDataSources:(NSArray */*of id<YKTableViewCellDataSource>*/)array section:(NSInteger)section indexPaths:(NSMutableArray **)indexPaths {
  NSMutableArray *dataSource = [self dataSourceForSection:section create:YES];
  NSInteger previousCount = [dataSource count];
  [dataSource addObjectsFromArray:array];
  if (section >= _sectionCount) _sectionCount = section + 1;
  
  if (indexPaths) {
    for(NSInteger i = 0, count = [array count]; i < count; i++) {
      [*indexPaths addObject:[NSIndexPath indexPathForRow:(i + previousCount) inSection:section]];
    }
  }
}

- (BOOL)hasSectionBefore:(NSInteger)section {
  for (NSInteger i = 0, sectionCount = [self sectionCount]; i < section && i < sectionCount; i++) {
    if ([self countForSection:i] > 0) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)isOnlySection:(NSInteger)section {
  BOOL hasDataForOtherSections = NO;
  for (NSInteger i = 0; i < [self sectionCount]; i++) {
    if (i == section) continue;
    if ([self countForSection:i] > 0) {
      hasDataForOtherSections = YES;
      break;
    }
  }
  return !hasDataForOtherSections;
}

- (void)truncateCellDataSourcesToCount:(NSInteger)count section:(NSInteger)section indexPaths:(NSMutableArray **)indexPaths {
  NSMutableArray *dataSource = [self dataSourceForSection:section];
  NSInteger cellCount = [dataSource count];
  if (cellCount <= count) return;
  [dataSource removeObjectsInRange:NSMakeRange(count, cellCount - count)];
  
  if (indexPaths) {
    for(NSInteger i = count; i < cellCount; i++) {
      [*indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
    }
  }
}

- (void)replaceCellDataSource:(id<YKTableViewCellDataSource>)cellDataSource indexPath:(NSIndexPath *)indexPath {
  NSMutableArray *dataSource = [self dataSourceForSection:indexPath.section];
  if (indexPath.row < [dataSource count]) {
    [dataSource replaceObjectAtIndex:indexPath.row withObject:cellDataSource];
  }
}

- (void)moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
  id<YKTableViewCellDataSource> cellDataSource = [[self cellDataSourceAtIndexPath:fromIndexPath] retain];
  [self removeCellDataSourceAtIndexPath:fromIndexPath];
  [self insertCellDataSource:cellDataSource atIndexPath:toIndexPath];
  [cellDataSource release];
}

- (void)setCellDataSources:(NSArray */*of id<YKTableViewCellDataSource>*/)array section:(NSInteger)section {
  NSMutableArray *dataSource = [self dataSourceForSection:section create:YES];
  [dataSource setArray:array];
  if (section >= _sectionCount) _sectionCount = section + 1;
}

- (void)setHeaderTitle:(NSString *)title section:(NSInteger)section {
  _headersExist = YES;
  if (title) {
    if (!_sectionHeaderTitles) _sectionHeaderTitles = [[NSMutableDictionary alloc] init];
    [_sectionHeaderTitles setObject:title forKey:[NSNumber numberWithInteger:section]];
  } else {
    [_sectionHeaderTitles removeObjectForKey:[NSNumber numberWithInteger:section]];
  }
}

- (void)setHeaderView:(UIView *)view section:(NSInteger)section {
  _headersExist = YES;
  if (view) {
    if (!_sectionHeaderViews) _sectionHeaderViews = [[NSMutableDictionary alloc] init];
    [_sectionHeaderViews setObject:view forKey:[NSNumber numberWithInteger:section]];
  } else {
    [_sectionHeaderViews removeObjectForKey:[NSNumber numberWithInteger:section]];
  } 
}

- (void)setFooterView:(UIView *)view section:(NSInteger)section {
  if (view) {
    if (!_sectionFooterViews) _sectionFooterViews = [[NSMutableDictionary alloc] init];
    [_sectionFooterViews setObject:view forKey:[NSNumber numberWithInteger:section]];
  } else {
    [_sectionFooterViews removeObjectForKey:[NSNumber numberWithInteger:section]];
  } 
}

- (BOOL)hasHeaderForSection:(NSInteger)section {
  if (!_headersExist) return NO;
  if ([self countForSection:section] > 0) 
    return ([_sectionHeaderTitles objectForKey:[NSNumber numberWithInteger:section]] != nil);
  return NO;  
}

- (void)clearSection:(NSInteger)section indexPaths:(NSMutableArray **)indexPaths {
  NSMutableArray *dataSource = [self dataSourceForSection:section];
  if (indexPaths) {
    for(NSInteger i = 0; i < [dataSource count]; i++) {
      [*indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
    }
  }
  [dataSource removeAllObjects];
}

- (NSInteger)count {
  NSInteger count = 0;
  for(NSInteger i = 0; i < _sectionCount; i++) {
    count += [self countForSection:i];
  }
  return count;
}

- (NSInteger)sectionCount {
  return _sectionCount;
}

- (NSIndexPath *)lastIndexPath {
  NSInteger sectionIndex = [self sectionCount] - 1;
  while(sectionIndex >= 0) {
    NSInteger rowIndex = [self countForSection:sectionIndex] - 1;
    if (rowIndex >= 0) {
      return [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
    }
    sectionIndex--;
  }
  return nil;
}

#pragma mark -

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self cellForTableView:tableView indexPath:indexPath];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [self sectionCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [[self dataSourceForSection:section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  id<YKTableViewCellDataSource> cellDataSource = [self cellDataSourceAtIndexPath:indexPath];
  return [cellDataSource sizeThatFits:CGSizeMake(tableView.frame.size.width, tableView.frame.size.height)].height;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  return indexPath;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if (!_headersExist) return nil;
  return [_sectionHeaderTitles objectForKey:[NSNumber numberWithInteger:section]];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if (!_headersExist) return nil;
  
  NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
  if (!sectionTitle) return nil;
  
  UIView *sectionHeaderView = [_sectionHeaderViews objectForKey:[NSNumber numberWithInteger:section]];  
  // TODO(gabe): We should assert this
  // NSAssert([sectionHeaderView respondsToSelector:@selector(setText:)], @"Header views must respond to setText:");
  if ([sectionHeaderView respondsToSelector:@selector(setText:)])       
    [(id)sectionHeaderView setText:sectionTitle];
  return sectionHeaderView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  if (!_headersExist) return 0.0;
  UIView *sectionHeaderView = [self tableView:tableView viewForHeaderInSection:section];
  if (sectionHeaderView) {
    return sectionHeaderView.frame.size.height;
  } else {
    // If there's a section title, but not a header view, return some default height
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle) return 24;
  }
  return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  // Only show view if we have cells
  if ([self countForSection:section] == 0) return nil;
  
  return [_sectionFooterViews objectForKey:[NSNumber numberWithInteger:section]]; 
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return [self tableView:tableView viewForFooterInSection:section].frame.size.height;
}

@end


@implementation YKTableViewDataSourceEnumerator 

- (id)initWithDataSource:(YKTableViewDataSource *)dataSource {
  if ((self = [super init])) {
    _dataSource = [dataSource retain];
    _section = 0;
    _index = 0;
  }
  return self;
}

- (void)dealloc {
  [_dataSource release];
  [super dealloc];
}

- (id)nextObject {
  if (_section >= [_dataSource sectionCount]) return nil;
  NSArray *cellDataSources = [_dataSource cellDataSourcesForSection:_section];
  if (_index >= [cellDataSources count]) {
    _index = 0;
    _section++;
    return [self nextObject];
  }
  return [cellDataSources objectAtIndex:_index++];
}

- (NSIndexPath *)indexPath {
  return [NSIndexPath indexPathForRow:_index inSection:_section];
}

@end