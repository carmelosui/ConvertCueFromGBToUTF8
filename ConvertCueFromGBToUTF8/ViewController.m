//
//  ViewController.m
//  ConvertCueFromGBToUTF8
//
//  Created by Carmelo Sui on 4/9/15.
//  Copyright (c) 2015 Carmelo Sui. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak) IBOutlet NSTextField *filePathTextField;
@property (weak) IBOutlet NSButton *convertRecursivelyCheckbox;
@property (weak) IBOutlet NSButton *startConvertButton;
@property (strong) IBOutlet NSTextView *outputTextField;
@property (weak) IBOutlet NSButton *chooseFileButton;

@property (nonatomic, assign, getter=isConverting) BOOL converting;

@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (IBAction)startConvertButtonPressed:(id)sender {
    if (self.isConverting) {
        [self stopConverting];
    }
    else {
        [self startConverting];
    }
}

- (IBAction)chooseFile:(id)sender {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Select"];
    
    if ([openPanel runModal] == NSModalResponseOK)
    {
        NSArray* files = [openPanel URLs];
        if (files.count == 0) {
            return;
        }
        self.filePathTextField.stringValue = [files.lastObject path];
    }
}

- (void)stopConverting
{
    
}

-(void)startConverting
{
    NSString *path = self.filePathTextField.stringValue;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL pathIsDirectory = NO;
    BOOL fileExist = [fileManager fileExistsAtPath:path isDirectory:&pathIsDirectory];
    if (!fileExist) {
        [self outputError:[NSString stringWithFormat:@"file not exist \"%@\"", path]];
        return;
    }
    
    if (pathIsDirectory) {
        [self convertDirectory:path];
        return;
    }
    
    [self convertFile:path];
}

- (void)convertDirectory:(NSString*)directory
{
    NSError *error = nil;
    NSArray *contentsOfDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:&error];
    if (error) {
        [self outputError:[NSString stringWithFormat:@"directory convert failed \"%@\"", directory]];
        return;
    }
    
    for (NSString *path in contentsOfDirectory) {
        BOOL isDirectory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
        NSMutableArray *subDirectories = [NSMutableArray array];
        if (isDirectory) {
            [subDirectories addObject:path];
        }
        else {
            [self convertFile:path];
        }
        for (NSString *directory in subDirectories) {
            [self convertDirectory:directory];
        }
    }
}

- (BOOL)fileTypeIsForConvert:(NSString*)path
{
    return [path.pathExtension isEqualTo:@"cue"];
}

- (void)convertFile:(NSString*)path
{
    if (![self fileTypeIsForConvert:path]) {
        return;
    }
    
    NSError *error = nil;
    NSString *fileContent = [NSString stringWithContentsOfFile:path encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGBK_95) error:&error];
    if (error) {
        [self outputFileConvertingFail:path];
        return;
    }
    
    BOOL succeed = [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (succeed) {
        [self outputLog:[NSString stringWithFormat:@"file converting succeeded \"%@\"", path]];
    }
    else {
        [self outputFileConvertingFail:path];
    }
}

-(void)outputFileConvertingFail:(NSString*)path
{
    [self outputError:[NSString stringWithFormat:@"file \"%@\" converting failed",path]];
}

-(void)outputLog:(NSString*)log
{
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:log attributes:@{NSForegroundColorAttributeName: [NSColor blackColor]}];
    [self appendToTextView:string];
}

-(void)outputError:(NSString*)error
{
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:error attributes:@{NSForegroundColorAttributeName: [NSColor redColor]}];
    [self appendToTextView:string];
}

- (void)appendToTextView:(NSAttributedString*)text
{
    [[self.outputTextField textStorage] appendAttributedString:text];
    [self.outputTextField scrollRangeToVisible:NSMakeRange([[self.outputTextField string] length], 0)];
}

@end
