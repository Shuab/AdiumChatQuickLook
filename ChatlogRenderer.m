//
//  ChatlogRenderer.m
//  AdiumChatQuickLook
//
//  Created by Moritz Ulrich on 11.08.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ChatlogRenderer.h"

@implementation ChatlogRenderer

#define PROJECT_ID @"im.adium.quicklookImporter"

+ (NSString*)generateHTMLForURL:(NSURL*)url {
    NSDictionary* userDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:PROJECT_ID];
    BOOL debugLog = [[userDefaults valueForKey:@"debugLog"] boolValue];
    BOOL stripFontStyles = [[userDefaults valueForKey:@"stripStyles"] boolValue];
    NSUInteger messageLimit = [[userDefaults valueForKey:@"messageLimit"] unsignedIntegerValue];
    
    NSError* error = nil;
    NSXMLDocument *document = [[[NSXMLDocument alloc] initWithContentsOfURL:url
                                                                    options:NULL
                                                                      error:&error] autorelease];
    
    if (!document || error) {
        return [NSString stringWithFormat:@"Error reading the XML, %@", error];
    }
    
    if(debugLog)
        NSLog(@"wholeTree: %@", document);
    
    NSXMLElement* chatNode = [[document nodesForXPath:@"/chat" error:&error] objectAtIndex:0];
    NSString* account = [[chatNode attributeForName:@"account"] stringValue];
    NSString* service = [[chatNode attributeForName:@"service"] stringValue];

    NSXMLElement* bodyElement = [NSXMLElement
                                 elementWithName:@"body" 
                                 children:[NSArray arrayWithObject:[ChatlogRenderer generateTableFromChatElement:chatNode]]
                                 attributes:nil];
    NSXMLDocument* htmlElement = [NSXMLElement elementWithName:@"html"
                                                     children:[NSArray arrayWithObjects:
                                                               [ChatlogRenderer generateHead],
                                                               bodyElement, nil]
                                                   attributes:nil];
    
    return [NSString stringWithFormat:@"%@", htmlElement];
}
                                 
#pragma mark - Methods to generate HTML
                                 
+ (NSXMLElement*)generateHead {
    NSString* cssStyle = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"chatlog" withExtension:@"css"]
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    return [NSXMLElement elementWithName:@"head"
                                children:[NSArray arrayWithObject:[NSXMLElement elementWithName:@"style" stringValue:cssStyle]]
                              attributes:nil];
}

+ (NSXMLElement*)generateTableFromChatElement:(NSXMLElement*)chatElement {
    return [NSXMLElement elementWithName:@"span" stringValue:@"You lost The Game."];
}

#pragma mark - Utility Methods

+ (NSString*)formatDate:(NSString*)s {
	// Remove : of time zone
	NSMutableString *dateString = [[s mutableCopy] autorelease];
	if ([dateString characterAtIndex: [dateString length] - 3] == ':')
		[dateString deleteCharactersInRange: NSMakeRange([dateString length] - 3, 1)];
	
	// Create NSDate
	NSDateFormatter *ISO8601Formatter = [[[NSDateFormatter alloc] init] autorelease];
	[ISO8601Formatter setTimeStyle:NSDateFormatterFullStyle];
	[ISO8601Formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];
	NSDate *date = [ISO8601Formatter dateFromString:dateString];
	
	// Extract the hours
	NSDateFormatter *hoursFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[hoursFormatter setTimeStyle:NSDateFormatterShortStyle];
	[hoursFormatter	setDateFormat:@"HH:mm:ss"];
	
	return [hoursFormatter stringFromDate:date];
}

+ (void)removeStyleRecursive:(NSXMLElement*)el {
    if(el.kind == NSXMLElementKind) {
        [el removeAttributeForName:@"class"];
        [el removeAttributeForName:@"style"];
    }
    
    for(NSXMLElement* child in [el children]) {
        [self removeStyleRecursive:child];
    }
}

@end