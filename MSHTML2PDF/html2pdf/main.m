//
//  main.m
//  html2pdf
//
//  Created by Simon on 02/04/2015.
//  Copyright (c) 2015 Make and Ship Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSHTML2PDF.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        MSHTML2PDF *html2pdf = [MSHTML2PDF new];
        html2pdf.standardOutput = [NSFileHandle fileHandleWithStandardOutput];
        html2pdf.standardError = [NSFileHandle fileHandleWithStandardError];
    
        [html2pdf runWithArgc:argc argv:argv];
        
        return html2pdf.exitStatus;
    }
    return 0;
}
