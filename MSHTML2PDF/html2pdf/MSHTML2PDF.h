//
//  MSHTML2PDF.h
//  html2pdf
//
//  Created by Simon on 02/04/2015.
//  Copyright (c) 2015 Make and Ship Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSHTML2PDF : NSObject
@property (nonatomic, retain) NSFileHandle *standardOutput;
@property (nonatomic, retain) NSFileHandle *standardError;
@property (nonatomic, assign) int exitStatus;

- (void)runWithArguments:(NSArray *)arguments;
- (void)runWithArgc:(int)argc argv:(const char * [])argv;
@end
