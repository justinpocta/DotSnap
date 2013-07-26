//
//  DSPMainViewModel.m
//  DotSnap
//
//  Created by Robert Widmann on 7/25/13.
//
//

#import "DSPMainViewModel.h"

static NSUInteger const DPSUniqueFilenameDepthLimit = 500;

@interface DSPMainViewModel ()
@property (nonatomic, strong) NSMetadataQuery *screenshotQuery;
@property (nonatomic, strong) NSMutableArray *filenameHistory;
@end

@implementation DSPMainViewModel

- (id)init {
	self = [super init];
	
	_filenameHistory = [NSUserDefaults.standardUserDefaults arrayForKey:DPSFilenameHistoryKey].mutableCopy;
	
	_screenshotQuery = [[NSMetadataQuery alloc] init];
    [_screenshotQuery setPredicate:[NSPredicate predicateWithFormat:@"kMDItemIsScreenCapture = 1"]];
    [_screenshotQuery startQuery];
	
    [NSNotificationCenter.defaultCenter addObserverForName:NSMetadataQueryDidUpdateNotification object:_screenshotQuery queue:nil usingBlock:^(NSNotification *note) {
		for (NSMetadataItem *item in [note.userInfo objectForKey:(NSString *)kMDQueryUpdateAddedItems]) {
			NSString *screenShotPath = [item valueForAttribute:NSMetadataItemPathKey];
			NSURL *oldURL = [NSURL fileURLWithPath:screenShotPath];
			
			NSURL *newURL = [NSURL fileURLWithPath:DPSUniqueFilenameForDirectory(self.filepath, self.filename)];
			[[NSFileManager defaultManager] moveItemAtURL:oldURL toURL:newURL error:nil];
		}
	}];
    
	
	return self;
}

- (void)addFilenameToHistory:(NSString *)filename {
	if (self.filenameHistory.count == 5) {
		[self.filenameHistory removeObjectAtIndex:(self.filenameHistory.count - 1)];
	}
	[self.filenameHistory insertObject:filename atIndex:0];
}

- (void)dealloc {
	[NSUserDefaults.standardUserDefaults setObject:self.filenameHistory forKey:DPSFilenameHistoryKey];
	[NSUserDefaults.standardUserDefaults synchronize];
}

static NSString *DPSUniqueFilenameForDirectory(NSString *relativePath, NSString *filename) {
	NSError *error;
	NSSet *allURLs = [NSSet setWithArray:[NSFileManager.defaultManager contentsOfDirectoryAtPath:relativePath error:&error]];
	if (error) return nil;
	
	NSString *retVal = nil;
	for (NSUInteger i = 0; i < DPSUniqueFilenameDepthLimit; i++) {
		NSString *temp = [NSString stringWithFormat:@"%@-%lu.png", filename, i];
		if (![allURLs containsObject:temp]) {
			retVal = temp;
			break;
		}
	}
	return [relativePath stringByAppendingPathComponent:retVal];
}


#pragma mark - NSTableViewDatasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return self.filenameHistory.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return [self.filenameHistory objectAtIndex:row];
}

#pragma mark - NSTableViewDelegate

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
	return 90.f;
}

@end
