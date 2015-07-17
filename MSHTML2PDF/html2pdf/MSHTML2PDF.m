//
//  MSHTML2PDF.m
//  html2pdf
//
//  Created by Simon on 02/04/2015.
//  Copyright (c) 2015 Make and Ship Limited. All rights reserved.
//

@import WebKit;

CGFloat const kMMtoPX = 595.28f / 210.0f;

#import <Foundation/Foundation.h>
#import "MSHTML2PDF.h"
#import "NSFileHandle+Print.h"
#import "BRLOptionParser.h"
#import "EXTScope.h"
#import "Version.h"

@interface MSPDFPrintInfo : NSObject
@property (nonatomic, strong) NSURL *inputURL;
@property (nonatomic, strong) NSURL *outputURL;
@property (nonatomic) CGFloat paperWidth;
@property (nonatomic) CGFloat paperHeight;
@property (nonatomic) CGFloat scalingFactor;
@property (nonatomic) CGFloat leftMargin;
@property (nonatomic) CGFloat rightMargin;
@property (nonatomic) CGFloat topMargin;
@property (nonatomic) CGFloat bottomMargin;
@end

@implementation MSPDFPrintInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.paperWidth = kMMtoPX * 210;
        self.paperHeight = kMMtoPX * 297;
        self.topMargin = kMMtoPX * 18;
        self.bottomMargin = kMMtoPX * 18;
        self.leftMargin = kMMtoPX * 18;
        self.rightMargin = kMMtoPX * 18;
    }
    return self;
}

@end

@interface MSHTML2PDF ()
@property (nonatomic, strong) BRLOptionParser *options;
@property (nonatomic, strong) NSWindow *printViewWindow;
@property (nonatomic, strong) WebView *printView;
@property (nonatomic) BOOL loadComplete;
@property (nonatomic) BOOL loadError;
@end

@implementation MSHTML2PDF

- (void)runWithArguments:(NSArray *)arguments
{
    int argc =  (int)[arguments count];
    const char **argv = (const char **)malloc(sizeof(const char*)*argc);
    for (int i = 0; i < argc; i++) {
        argv[i] = strdup([[arguments objectAtIndex:i] UTF8String]);
    }
    [self runWithArgc:argc argv:argv];
    free(argv);
}

- (void)runWithArgc:(int)argc argv:(const char * [])argv
{
    @weakify(self);
    
    self.exitStatus = EXIT_FAILURE;

    self.options = [BRLOptionParser new];
    MSPDFPrintInfo *printInfo = [MSPDFPrintInfo new];
    
    NSString *inputFile = @"";
    NSString *inputUrlString = @"";
    NSString *outputFile = @"";
    NSString *paperDimensions = @"";
    NSString *topMargin = @"";
    NSString *rightMargin = @"";
    NSString *bottomMargin = @"";
    NSString *leftMargin = @"";
    
    [self.options setBanner:@"usage: %s [-i --input-file <name>] [-u --input-url <url>] [-o --output-file <name>] [-d --paper-dimensions] [-t --top-margin] [-r --right-margin] [-b --bottom-margin] [-l --left-margin] [-v --version] [-h --help]", argv[0]];
    
    [self.options addOption:"input-file" flag:'i' description:@"Input file" argument:&inputFile];
    [self.options addOption:"input-url" flag:'u' description:@"Input url" argument:&inputUrlString];
    [self.options addOption:"output-file" flag:'o' description:@"Output file" argument:&outputFile];
    
    [self.options addOption:"paper-dimensions" flag:'d' description:@"Paper width and height in millimeters" argument:&paperDimensions];
    
    [self.options addOption:"top-margin" flag:'t' description:@"Top margin in millimeters" argument:&topMargin];
    [self.options addOption:"right-margin" flag:'r' description:@"Right margin in millimeters" argument:&rightMargin];
    [self.options addOption:"bottom-margin" flag:'b' description:@"Bottom margin in millimeters" argument:&bottomMargin];
    [self.options addOption:"left-margin" flag:'l' description:@"Left margin in millimeters" argument:&leftMargin];

    [self.options addSeparator];

    [self.options addOption:"version" flag:'v' description:@"Show version" block:^{
        @strongify(self);
        self.exitStatus = EXIT_SUCCESS;
        const char * message = [MSHTML2PDFVersionString UTF8String];
        [self.standardError printString:@"%s: %s\n", argv[0], message];
    }];
    
    [self.options addOption:"help" flag:'h' description:@"Show this message" block:^{
        @strongify(self);
        self.exitStatus = EXIT_SUCCESS;
        [self printUsage];
    }];
    
    NSError *error = nil;
    if (![self.options parseArgc:argc argv:argv error:&error]) {
        const char * message = [[error localizedDescription] UTF8String];
        [self.standardError printString:@"%s: %s\n", argv[0], message];
        return;
    }
    
    // if we intercepted version or help already
    if ( EXIT_SUCCESS == self.exitStatus ) {
        return;
    }

    if ( [inputFile length] && [inputUrlString length] ) {
        [self printUsage];
        return;
    }
    
    if ( ![inputFile length] && ![inputUrlString length] ) {
        [self printUsage];
        return;
    }
    
    if ( ![outputFile length] ) {
        [self printUsage];
        return;
    }
    
    NSNumberFormatter *floatFormatter = [NSNumberFormatter new];
    floatFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    if ( [paperDimensions length] ) {
        NSScanner *scanner = [NSScanner scannerWithString:paperDimensions];
        float paperWidth;
        float paperHeight;
        if ( [scanner scanFloat:&paperWidth] ) {
            if ( [scanner scanFloat:&paperHeight]) {
                printInfo.paperWidth = kMMtoPX * paperWidth;
                printInfo.paperHeight = kMMtoPX * paperHeight;
            }
            else {
                // not enough params
                [self printUsage];
                return;
            }
        }
    }
    if ( [topMargin length] ) {
        printInfo.topMargin = kMMtoPX * [[floatFormatter numberFromString:topMargin] floatValue];
    }
    if ( [rightMargin length] ) {
        printInfo.rightMargin = kMMtoPX * [[floatFormatter numberFromString:rightMargin] floatValue];
    }
    if ( [bottomMargin length] ) {
        printInfo.bottomMargin = kMMtoPX * [[floatFormatter numberFromString:bottomMargin] floatValue];
    }
    if ( [leftMargin length] ) {
        printInfo.leftMargin = kMMtoPX * [[floatFormatter numberFromString:leftMargin] floatValue];
    }
    

    NSURL *inputUrl = nil;
    NSURL *outputUrl = nil;

    if ( [inputUrlString length] ) {
        inputUrl = [NSURL URLWithString:inputUrlString];
    }
    else {
        inputFile = [inputFile stringByStandardizingPath];
        inputUrl = [NSURL fileURLWithPath:inputFile];
    }
    
    outputFile = [outputFile stringByStandardizingPath];
    if ( ![outputFile hasPrefix:@"/"] ) {
        // make relative to current directory
        outputFile = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:outputFile];
    }
    outputUrl = [NSURL fileURLWithPath:outputFile];
    
//    NSLog(@"inputFile:%@ ",inputFile);
//    NSLog(@"outputFile:%@ ",outputFile);
//    NSLog(@"inputUrl:%@ ",inputUrl.absoluteString);
//    NSLog(@"outputUrl:%@ ",outputUrl.absoluteString);
    
    printInfo.inputURL = inputUrl;
    printInfo.outputURL = outputUrl;
    
    @try {
        [self renderWithPrintInfo:printInfo];
    }
    @catch (NSException *exception) {
        self.exitStatus = EXIT_FAILURE;
        [self printUsage];
    }
}

- (void)printUsage
{
    NSFileHandle *output = self.standardError;
    if ( EXIT_SUCCESS == self.exitStatus ) {
        output = self.standardOutput;
    }
    [output printString:@"%s",[[self.options description] UTF8String]];
}

- (void)renderWithPrintInfo:(MSPDFPrintInfo *)printInfo
{
    NSRect printViewFrame = NSMakeRect(0,0,768,1024);
    self.printView = [[WebView alloc] initWithFrame:printViewFrame frameName:@"printFrame" groupName:@"printGroup"];
    [self.printView setMaintainsBackForwardList:NO];
    [self.printView setFrameLoadDelegate:self];
    [self.printView setResourceLoadDelegate:self];
    [self.printView setMediaStyle:@"screen"];
    [self.printView setPolicyDelegate:self];
    
    WebPreferences* printPreferences = [self.printView preferences];
	[printPreferences setShouldPrintBackgrounds:YES];
    [self.printView setPreferences:printPreferences];

    self.printViewWindow = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(0,0,1,1)
        styleMask:NSTitledWindowMask|NSResizableWindowMask|NSMiniaturizableWindowMask|NSClosableWindowMask
        backing:NSBackingStoreBuffered defer:NO
    ];
    [self.printViewWindow setContentView:self.printView];

    self.loadComplete = NO;
    self.loadError = NO;
    
    NSURLRequest *req = [NSURLRequest requestWithURL:printInfo.inputURL];
    [[self.printView mainFrame] loadRequest:req];
    
    NSDate *next = [NSDate dateWithTimeIntervalSinceNow:10.0];
    BOOL isRunning;
    do {
        isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:next];
    } while (!self.loadComplete && !self.loadError);
    
    if ( !self.loadError ) {
        [self renderToPDFWithWithPrintInfo:printInfo];
    }
}

#if false

// this is left in case we need to use this method in future

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id )listener
{
    NSString *host = [[request URL] host];
    NSString *requestString = [[request URL] absoluteString];
    NSArray *components = [requestString componentsSeparatedByString:@":"];
    if ( [components count] > 0 && [components[0] isEqualToString:@"myapp"] ) {
        NSString *command = components[1];
        if ([command isEqualToString:@"windowLoadEventFired"]) {
            self.loadComplete = YES;
            [listener ignore];
        }
    }
    else {
        [listener use];
    }
}
#endif

- (void)renderToPDFWithWithPrintInfo:(MSPDFPrintInfo *)printInfo
{
    NSMutableDictionary *printInfoDict = [[NSPrintInfo sharedPrintInfo] dictionary];
    [printInfoDict setObject:NSPrintSaveJob forKey:NSPrintJobDisposition];
    [printInfoDict setObject:printInfo.outputURL forKey:NSPrintJobSavingURL];
    [printInfoDict setObject:@YES forKey:NSPrintHeaderAndFooter];

    NSPrintInfo *rederPrintInfo = [[NSPrintInfo alloc] initWithDictionary:printInfoDict];
    [rederPrintInfo setHorizontalPagination:NSAutoPagination];
    [rederPrintInfo setVerticalPagination:NSAutoPagination];
    
    rederPrintInfo.paperSize = NSMakeSize(printInfo.paperWidth, printInfo.paperHeight);
    rederPrintInfo.orientation = NSPaperOrientationPortrait;
    rederPrintInfo.topMargin = printInfo.topMargin;
    rederPrintInfo.bottomMargin = printInfo.bottomMargin;
    rederPrintInfo.leftMargin = printInfo.leftMargin;
    rederPrintInfo.rightMargin = printInfo.rightMargin;
    rederPrintInfo.scalingFactor = 1;

    NSView *documentView = [[[self.printView mainFrame] frameView] documentView];

    NSPrintOperation *op = [NSPrintOperation printOperationWithView:documentView printInfo:rederPrintInfo];

    [op setShowsPrintPanel:NO];
    [op setShowsProgressPanel:NO];

    if ([op runOperation] ){
        // completed successfully
        self.exitStatus = EXIT_SUCCESS;
    }
    else {
        // something went wrong
    }
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    if ([frame isEqual:[self.printView mainFrame]]) {
        self.loadError = YES;
    }
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    if ([frame isEqual:[self.printView mainFrame]]) {
        self.loadError = YES;
    }
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if ([frame isEqual:[self.printView mainFrame]]) {
        self.loadComplete = YES;
    }
}

@end
