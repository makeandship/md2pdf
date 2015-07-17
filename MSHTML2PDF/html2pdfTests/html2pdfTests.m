//
//  html2pdf_Tests.m
//  html2pdf Tests
//
//  Created by Simon Heys on 08/04/2015.
//  Copyright (c) 2015 Make and Ship Limited. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MSHTML2PDF.h"
#import "Specta.h"
#define EXP_SHORTHAND
#import "Expecta.h"

SpecBegin(HTML2PDF)

describe(@"Convert", ^{
    beforeAll(^{
        [Expecta setAsynchronousTestTimeout:10];
    });

    it(@"can convert local html file to pdf", ^{
        MSHTML2PDF *html2pdf = [MSHTML2PDF new];
        html2pdf.standardOutput = [NSFileHandle fileHandleWithStandardOutput];
        html2pdf.standardError = [NSFileHandle fileHandleWithStandardError];

        NSString *localFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"index with spaces.html" ofType:nil inDirectory:@"Fixtures"];

        NSString *localTempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"html2pdfTests With Spaces.output.pdf"];

        NSArray *arguments = @[
            @"html2pdf",
            @"-i",
            localFilePath,
            @"-o",
            localTempFilePath,
            @"-d", @"210 297",
            @"-l", @"50",
            @"-t", @"50",
            @"-r", @"50",
            @"-b", @"50",
        ];

        [html2pdf runWithArguments:arguments];

        expect(EXIT_SUCCESS == html2pdf.exitStatus).to.beTruthy();
        
        expect([[NSFileManager defaultManager] fileExistsAtPath:localTempFilePath]).to.beTruthy();
        
    });
});

SpecEnd
